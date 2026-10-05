import 'dart:async';

import 'package:flutter/material.dart';

class SlideSnackBar {
  SlideSnackBar._();

  static OverlayEntry? _entry;

  static void hide() {
    _entry?.remove();
    _entry = null;
  }

  static void show(
    BuildContext context, {
    required String message,
    SnackBarBehavior behavior = SnackBarBehavior.fixed,
    bool showCloseIcon = false,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
    double actionOverflowThreshold = 0.25,
  }) {
    hide();

    final OverlayState overlay = Overlay.of(context, rootOverlay: true);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext context) {
        return _SlideSnackBar(
          message: message,
          behavior: behavior,
          showCloseIcon: showCloseIcon,
          actionLabel: actionLabel,
          onActionPressed: onActionPressed,
          duration: duration,
          actionOverflowThreshold: actionOverflowThreshold,
          onDismissed: () {
            if (_entry == entry) {
              _entry = null;
            }
            entry.remove();
          },
        );
      },
    );

    _entry = entry;
    overlay.insert(entry);
  }
}

class _SlideSnackBar extends StatefulWidget {
  const _SlideSnackBar({
    required this.message,
    required this.behavior,
    required this.showCloseIcon,
    required this.actionLabel,
    required this.onActionPressed,
    required this.duration,
    required this.actionOverflowThreshold,
    required this.onDismissed,
  });

  final String message;
  final SnackBarBehavior behavior;
  final bool showCloseIcon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Duration duration;
  final double actionOverflowThreshold;
  final VoidCallback onDismissed;

  @override
  State<_SlideSnackBar> createState() => _SlideSnackBarState();
}

class _SlideSnackBarState extends State<_SlideSnackBar>
    with TickerProviderStateMixin {
  static const Duration _enterDuration = Duration(milliseconds: 250);
  static const Duration _exitDuration = Duration(milliseconds: 200);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _enterDuration,
    reverseDuration: _exitDuration,
  );

  late final AnimationController _dragController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  late final Animation<Offset> _slide =
      Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  final GlobalKey _barKey = GlobalKey();

  Timer? _timer;
  bool _dismissing = false;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _restartTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _dragController.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _dragging = false;
    _timer?.cancel();
    _dragController.stop();
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  double get _barHeight {
    final RenderObject? renderObject =
        _barKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final double height = renderObject.size.height;
      if (height > 0) return height;
    }
    return 1;
  }

  void _onDragStart(DragStartDetails details) {
    if (_dismissing) return;
    _dragging = true;
    _timer?.cancel();
    _dragController.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging || _dismissing) return;
    final double delta = details.delta.dy / _barHeight;
    final double next =
        (_dragController.value + delta).clamp(0.0, 1.0).toDouble();
    _dragController.value = next;
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;

    final double velocity = details.primaryVelocity ?? 0;

    if (_dragController.value >= 0.35 || velocity > 700) {
      _dismiss();
      return;
    }

    _dragController
        .animateTo(
      0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    )
        .whenComplete(() {
      if (mounted && !_dismissing) _restartTimer();
    });
  }

  void _onDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    _dragController.animateTo(
      0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
    if (!_dismissing) _restartTimer();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool floating = widget.behavior == SnackBarBehavior.floating;

    final Color backgroundColor =
        theme.snackBarTheme.backgroundColor ?? scheme.inverseSurface;
    final Color foregroundColor =
        theme.snackBarTheme.actionTextColor ?? scheme.onInverseSurface;
    final TextStyle textStyle =
        theme.snackBarTheme.contentTextStyle ??
        theme.textTheme.bodyMedium!.copyWith(color: scheme.onInverseSurface);

    final Widget? actionButton = widget.actionLabel == null
        ? null
        : TextButton(
            onPressed: () {
              widget.onActionPressed?.call();
              _dismiss();
            },
            style: TextButton.styleFrom(foregroundColor: foregroundColor),
            child: Text(widget.actionLabel!),
          );

    final Widget bar = Material(
      color: backgroundColor,
      elevation: 6,
      borderRadius: floating ? BorderRadius.circular(8) : BorderRadius.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _buildContentArea(
                textStyle: textStyle,
                actionButton: actionButton,
              ),
            ),
            if (widget.showCloseIcon)
              IconButton(
                onPressed: _dismiss,
                color: foregroundColor,
                icon: const Icon(Icons.close),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              ),
          ],
        ),
      ),
    );

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SlideTransition(
        position: _slide,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_fade, _dragController]),
          builder: (BuildContext context, Widget? child) {
            final double dragProgress = _dragController.value;
            final double opacity =
                (_fade.value * (1.0 - dragProgress)).clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: FractionalTranslation(
                translation: Offset(0, dragProgress),
                child: child,
              ),
            );
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: _onDragStart,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            onVerticalDragCancel: _onDragCancel,
            child: Padding(
              key: _barKey,
              padding: EdgeInsets.only(
                left: floating ? 16 : 0,
                right: floating ? 16 : 0,
                bottom: (floating ? 16 : 0) +
                    MediaQuery.of(context).padding.bottom,
              ),
              child: floating
                  ? Align(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: bar,
                      ),
                    )
                  : bar,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea({
    required TextStyle textStyle,
    required Widget? actionButton,
  }) {
    final Widget textWidget = Text(widget.message, style: textStyle);

    if (actionButton == null) {
      return textWidget;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: widget.message, style: textStyle),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout();

        final double available = constraints.maxWidth;
        final bool putActionOnNewLine =
            painter.width > available * (1 - widget.actionOverflowThreshold);

        if (putActionOnNewLine) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              textWidget,
              const SizedBox(height: 4),
              Align(alignment: Alignment.centerRight, child: actionButton),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(child: textWidget),
            const SizedBox(width: 8),
            actionButton,
          ],
        );
      },
    );
  }
}
