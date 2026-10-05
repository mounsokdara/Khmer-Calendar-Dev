import 'package:flutter/material.dart';

class EqualDialogActions extends StatelessWidget {
  const EqualDialogActions({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth.isFinite ? box.maxWidth : 320.0;
        return SizedBox(
          width: w,
          child: Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: children[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

List<Widget> equalDialogActions(List<Widget> buttons) {
  return [EqualDialogActions(children: buttons)];
}

ButtonStyle dialogBtnStyle({Color? background, Color? foreground}) {
  return ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    backgroundColor: background == null ? null : WidgetStatePropertyAll(background),
    foregroundColor: foreground == null ? null : WidgetStatePropertyAll(foreground),
  );
}

Widget dlgLabel(String text) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, textAlign: TextAlign.center),
  );
}
