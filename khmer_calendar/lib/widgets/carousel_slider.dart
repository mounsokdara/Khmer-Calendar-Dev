import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CarouselSlider extends StatefulWidget {
  const CarouselSlider({
    super.key,
    required this.itemCount,
    required this.index,
    required this.itemBuilder,
    this.onIndexChanged,
  });

  final int itemCount;

  final int index;

  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int>? onIndexChanged;

  @override
  State<CarouselSlider> createState() => _CarouselSliderState();
}

class _CarouselSliderState extends State<CarouselSlider> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.index.clamp(0, _lastPage));
  }

  @override
  void didUpdateWidget(covariant CarouselSlider old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _syncTo(widget.index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _lastPage => widget.itemCount > 0 ? widget.itemCount - 1 : 0;

  void _syncTo(int page) {
    final target = page.clamp(0, _lastPage);
    void jump() {
      if (!mounted || !_controller.hasClients) return;
      if (_controller.page?.round() != target) _controller.jumpToPage(target);
    }

    if (_controller.hasClients) {
      jump();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => jump());
    }
  }

  void _onPage(int i) {
    if (i == widget.index) return;
    widget.onIndexChanged?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.itemCount,
        onPageChanged: _onPage,
        itemBuilder: widget.itemBuilder,
      ),
    );
  }
}
