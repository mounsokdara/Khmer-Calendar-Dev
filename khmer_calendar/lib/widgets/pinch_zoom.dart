import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Reports a two-finger pinch (or a trackpad pinch) as a live gesture:
/// [onStart] with the pinch centre (global), then [onUpdate] with the cumulative scale
/// (1.0 = fingers where they started, >1 spread, <1 pinched together), then [onEnd].
///
/// It only listens to raw pointer events, so it never competes with scrolling or swiping
/// children in the gesture arena.
class PinchZoom extends StatefulWidget {
  const PinchZoom({
    super.key,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.child,
  });

  final ValueChanged<Offset> onStart;
  final ValueChanged<double> onUpdate;
  final VoidCallback onEnd;
  final Widget child;

  @override
  State<PinchZoom> createState() => _PinchZoomState();
}

class _PinchZoomState extends State<PinchZoom> {
  final _points = <int, Offset>{};
  double _base = 0;
  bool _active = false;

  double get _span {
    final v = _points.values.toList();
    return (v[0] - v[1]).distance;
  }

  Offset get _center {
    final v = _points.values.toList();
    return (v[0] + v[1]) / 2;
  }

  void _down(PointerDownEvent e) {
    if (e.kind == PointerDeviceKind.mouse) return;
    _points[e.pointer] = e.position;
    if (_points.length == 2 && !_active) {
      _base = _span;
      if (_base <= 0) return;
      _active = true;
      widget.onStart(_center);
    }
  }

  void _move(PointerMoveEvent e) {
    if (!_points.containsKey(e.pointer)) return;
    _points[e.pointer] = e.position;
    if (_active && _points.length >= 2 && _base > 0) widget.onUpdate(_span / _base);
  }

  void _up(PointerEvent e) {
    _points.remove(e.pointer);
    if (_active && _points.length < 2) {
      _active = false;
      _base = 0;
      widget.onEnd();
    }
  }

  void _padStart(PointerPanZoomStartEvent e) => widget.onStart(e.position);

  void _padUpdate(PointerPanZoomUpdateEvent e) => widget.onUpdate(e.scale);

  void _padEnd(PointerPanZoomEndEvent e) => widget.onEnd();

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      onPointerPanZoomStart: _padStart,
      onPointerPanZoomUpdate: _padUpdate,
      onPointerPanZoomEnd: _padEnd,
      child: widget.child,
    );
  }
}
