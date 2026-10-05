import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

/// The view [steps] levels away from the current one (positive = more zoomed in, negative =
/// more zoomed out): its key and its widget. Only called for steps inside
/// `-levelsOut..levelsIn`; may return null.
typedef ZoomPeek = ({String key, Widget child})? Function(int steps);

/// Lets a pinch detector drive a [ZoomSwitcher] live.
class ZoomController {
  _ZoomSwitcherState? _s;

  /// While a pinch (or its settle animation) is running: the level the view is currently
  /// nearest to, as an offset in levels from the view the pinch started on (+ in, - out).
  /// `null` when no pinch is active. Lets UI such as the view menu follow the pinch live.
  final ValueNotifier<int?> liveStep = ValueNotifier<int?>(null);

  /// A pinch began at [focal] (global position).
  void start(Offset focal) => _s?._start(focal);

  /// Cumulative pinch scale since [start]: 1 = unchanged, >1 spread, <1 pinched.
  void update(double scale) => _s?._update(scale);

  /// The fingers lifted.
  void end() => _s?._end();
}

/// Switches between calendar views with a zoom + cross-fade.
///
/// * **Live (pinch):** while [ZoomController] reports a pinch, the views around the current
///   one (from [peek]) follow the fingers in real time. The pinch is continuous: it is not
///   capped at one level, so a single pinch can travel through every level (years, month,
///   full month, week). Each pair of neighbouring levels cross-fades while scaling. Releasing
///   snaps to the nearest level ([onCommit]); releasing before 30% of a level springs back.
///   Past the last level in either direction the view stretches against heavy resistance
///   ([onLimit] fires once when the stop is reached) and eases back smoothly on release.
/// * **Timed (menu / tap):** when [viewKey] changes with no pinch, the same cross-fade plays
///   as a short fixed-length transition.
///
/// Both views sit in their own [RepaintBoundary], so a frame is only GPU layer transforms.
class ZoomSwitcher extends StatefulWidget {
  const ZoomSwitcher({
    super.key,
    required this.viewKey,
    required this.zoomIn,
    required this.focus,
    required this.child,
    this.controller,
    this.peek,
    this.levelsIn = 0,
    this.levelsOut = 0,
    this.onCommit,
    this.onLimit,
  });

  /// Identifies the current view. A change (without a live pinch) starts a timed transition.
  final String viewKey;

  /// Direction of the change that [viewKey] represents.
  final bool zoomIn;

  /// Where the scale is anchored for a timed transition starting with this build.
  final Alignment focus;

  final Widget child;
  final ZoomController? controller;
  final ZoomPeek? peek;

  /// How many levels exist beyond the current view when zooming in / out.
  final int levelsIn;
  final int levelsOut;

  /// Called with the target view's key when a pinch is released far enough to switch to it.
  final ValueChanged<String>? onCommit;

  /// Called once each time a pinch pushes past the first or last level.
  final VoidCallback? onLimit;

  @override
  State<ZoomSwitcher> createState() => _ZoomSwitcherState();
}

class _ZoomSwitcherState extends State<ZoomSwitcher> with TickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 300);
  static const _timedSpan = 0.14;

  /// Pinch ratio that equals one level; the layers' scale follows the fingers exactly.
  static const _fullPinch = 1.6;

  /// Fraction of a level a release must be past to move on rather than spring back.
  static const _commitAt = 0.3;

  /// The most the view can stretch past the last level (in levels) and how stiff it is at the
  /// start: the lower the stiffness, the heavier the pull feels.
  static const _stretch = 0.2;
  static const _stiffness = 0.4;

  /// Below this distance (in levels) from a whole level only that level is drawn.
  static const _snapEps = 0.004;

  late final AnimationController _c = AnimationController(vsync: this, duration: _duration, value: 1)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && _outgoing != null && mounted) {
        setState(() => _outgoing = null);
      }
    });

  /// Live pinch position in levels from the view the pinch started on (+ in, - out). It already
  /// includes the rubber-band resistance, and is driven by the spring when the fingers lift.
  late final AnimationController _z = AnimationController.unbounded(vsync: this, value: 0);
  late final Listenable _both = Listenable.merge([_c, _z]);

  // Timed transition.
  Widget? _outgoing;
  String _outKey = '';
  bool _zoomIn = true;
  Alignment _focus = Alignment.center;

  // Live pinch.
  bool _live = false;
  bool _settling = false;
  bool _suppress = false;
  bool _atLimit = false;
  double _origin = 0;
  int _gen = 0;
  final _peeks = <int, ({String key, Widget child})?>{};

  double get _lo => -widget.levelsOut.toDouble();
  double get _hi => widget.levelsIn.toDouble();

  @override
  void initState() {
    super.initState();
    widget.controller?._s = this;
    _z.addListener(_publishStep);
  }

  @override
  void didUpdateWidget(covariant ZoomSwitcher old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      if (old.controller?._s == this) old.controller?._s = null;
      widget.controller?._s = this;
    }
    if (old.viewKey == widget.viewKey) return;
    if (_suppress || _live) {
      // The switch was already shown live; just drop the helper layers.
      _suppress = false;
      _resetLive();
      return;
    }
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _outgoing = null;
      _c.value = 1;
      return;
    }
    _outgoing = old.child;
    _outKey = old.viewKey;
    _zoomIn = widget.zoomIn;
    _focus = widget.focus;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _z.removeListener(_publishStep);
    if (widget.controller?._s == this) widget.controller?._s = null;
    _c.dispose();
    _z.dispose();
    super.dispose();
  }

  /// Tells the controller which level is nearest. Deferred when called while the framework is
  /// building (e.g. from [didUpdateWidget]), since listeners may call setState.
  void _publishStep() {
    final c = widget.controller;
    if (c == null) return;
    final int? step = _live ? _z.value.round().clamp(-widget.levelsOut, widget.levelsIn).toInt() : null;
    if (c.liveStep.value == step) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.controller == c) c.liveStep.value = step;
      });
    } else {
      c.liveStep.value = step;
    }
  }

  void _resetLive() {
    _gen++;
    _z.stop();
    _live = false;
    _settling = false;
    _atLimit = false;
    _origin = 0;
    _peeks.clear();
    _outgoing = null;
    _z.value = 0;
    _c.value = 1;
    _publishStep();
  }

  ({String key, Widget child})? _peekAt(int step) {
    if (!_peeks.containsKey(step)) _peeks[step] = widget.peek?.call(step);
    return _peeks[step];
  }

  /// Rubber band: past either end the view only follows the fingers a little, and ever less.
  double _elastic(double over) => _stretch * (1 - 1 / (over * _stiffness / _stretch + 1));

  double _resist(double raw) {
    if (raw > _hi) return _hi + _elastic(raw - _hi);
    if (raw < _lo) return _lo - _elastic(_lo - raw);
    return raw;
  }

  void _start(Offset focal) {
    if (_settling && _suppress) return;
    _c.stop();
    // A spring-back that is still running is picked up where it is, not restarted from zero.
    final carry = _live && _settling ? _z.value : 0.0;
    _gen++;
    _z.stop();
    var f = Alignment.center;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize && !box.size.isEmpty) {
      final p = box.globalToLocal(focal);
      f = Alignment(
        (p.dx / box.size.width * 2 - 1).clamp(-1.0, 1.0).toDouble(),
        (p.dy / box.size.height * 2 - 1).clamp(-1.0, 1.0).toDouble(),
      );
    }
    setState(() {
      _outgoing = null;
      _live = true;
      _settling = false;
      _atLimit = false;
      _peeks.clear();
      _origin = carry.clamp(_lo, _hi).toDouble();
      _focus = f;
      _z.value = _origin;
    });
    _publishStep();
  }

  void _update(double scale) {
    if (!_live || _settling || scale <= 0) return;
    final raw = _origin + math.log(scale) / math.log(_fullPinch);
    final over = raw > _hi || raw < _lo;
    if (over && !_atLimit) {
      _atLimit = true;
      widget.onLimit?.call();
    } else if (!over) {
      _atLimit = false;
    }
    _z.value = _resist(raw);
  }

  void _end() {
    if (!_live || _settling) return;
    final z = _z.value;
    final a = z.abs();
    final whole = a.floor();
    final steps = whole + (a - whole >= _commitAt ? 1 : 0);
    final target = ((z < 0 ? -steps : steps).toDouble().clamp(_lo, _hi)).round();
    if (target == 0 && a < 0.001) {
      setState(_resetLive);
      return;
    }
    _settling = true;
    final gen = ++_gen;
    final committing = target != 0;
    String? key;
    if (committing) {
      key = _peekAt(target)?.key;
      if (key == null) {
        setState(_resetLive);
        return;
      }
      _suppress = true;
    }
    // Moving on is quick; coming back from the rubber band is slower and critically damped,
    // so it eases in without bouncing.
    final stretched = z > _hi || z < _lo;
    final spring = SpringDescription.withDampingRatio(
      mass: 1,
      stiffness: stretched ? 150 : 260,
      ratio: 1,
    );
    _z.animateWith(SpringSimulation(spring, z, target.toDouble(), 0)).whenComplete(() {
      if (!mounted || gen != _gen) return;
      if (committing) {
        widget.onCommit?.call(key!);
        // If the parent did not switch views, do not stay stuck on the other view.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _live && gen == _gen) setState(_resetLive);
        });
      } else {
        setState(_resetLive);
      }
    });
  }

  ({double scale, double opacity}) _timedValues({required bool incoming, required bool zoomIn, required double v}) {
    final t = Curves.easeOutCubic.transform(v);
    if (incoming) {
      final from = zoomIn ? 1 - _timedSpan : 1 + _timedSpan;
      return (scale: from + (1 - from) * t, opacity: (v / 0.6).clamp(0.0, 1.0).toDouble());
    }
    final to = zoomIn ? 1 + _timedSpan : 1 - _timedSpan;
    return (scale: 1 + (to - 1) * t, opacity: (1 - v / 0.55).clamp(0.0, 1.0).toDouble());
  }

  Widget _layer(Key key, Widget child, double scale, double opacity, {required bool ignore}) {
    return IgnorePointer(
      key: key,
      ignoring: ignore,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(scale: scale, alignment: _focus, child: child),
      ),
    );
  }

  /// The layers for a live pinch at position [z]. Between two levels both are drawn, with the
  /// same scale factor so they stay in proportion while the fingers move. Past the first or
  /// last level only that level is drawn, stretched but fully opaque.
  List<Widget> _liveLayers(double z) {
    const k = _fullPinch;
    Widget layer(int step, double scale, double opacity) {
      final peeked = step == 0 ? null : _peekAt(step);
      final child = step == 0 ? widget.child : peeked?.child;
      if (child == null) return SizedBox.shrink(key: ValueKey('empty$step'));
      final key = step == 0 ? widget.viewKey : peeked!.key;
      final single = opacity >= 1 && scale == 1;
      return _layer(ValueKey(key), RepaintBoundary(child: child), scale, opacity, ignore: !(single && step == 0));
    }

    final lo = widget.levelsOut == 0 ? 0 : -widget.levelsOut;
    final hi = widget.levelsIn;
    if (z >= hi) return [layer(hi, math.pow(k, z - hi).toDouble(), 1)];
    if (z <= lo) return [layer(lo, math.pow(k, z - lo).toDouble(), 1)];
    final r = z.roundToDouble();
    if ((z - r).abs() < _snapEps) return [layer(r.toInt(), 1, 1)];
    final s = z.floor();
    final t = z - s;
    return [
      layer(s, math.pow(k, t).toDouble(), 1 - t),
      layer(s + 1, math.pow(k, t - 1).toDouble(), t),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final current = RepaintBoundary(child: widget.child);
    final out = _outgoing == null ? null : RepaintBoundary(child: _outgoing!);
    return ClipRect(
      child: AnimatedBuilder(
        animation: _both,
        builder: (context, _) {
          if (_live) return Stack(fit: StackFit.expand, children: _liveLayers(_z.value));
          final v = _c.value;
          final layers = <Widget>[];
          if (out != null) {
            final o = _timedValues(incoming: false, zoomIn: _zoomIn, v: v);
            layers.add(_layer(ValueKey(_outKey), out, o.scale, o.opacity, ignore: true));
          }
          final i = _timedValues(incoming: true, zoomIn: _zoomIn, v: v);
          layers.add(_layer(ValueKey(widget.viewKey), current, i.scale, i.opacity, ignore: false));
          return Stack(fit: StackFit.expand, children: layers);
        },
      ),
    );
  }
}
