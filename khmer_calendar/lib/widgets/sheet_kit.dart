import 'package:flutter/material.dart';


class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.subtitle, this.icon, this.trailing});
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}


class SheetOption extends StatelessWidget {
  const SheetOption({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: selected ? cs.primaryContainer.withValues(alpha: 0.55) : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: leading,
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          subtitle: subtitle == null ? null : Text(subtitle!),
          trailing: Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected ? cs.primary : cs.outline,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}




class ScrollableSheet extends StatelessWidget {
  const ScrollableSheet({super.key, required this.header, required this.children});
  final Widget header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Flexible(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: children),
            ),
          ),
        ],
      ),
    );
  }
}


Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool scrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: scrollControlled,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: builder,
  );
}


class PageIntro extends StatelessWidget {
  const PageIntro({super.key, required this.text, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}


class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, this.icon = Icons.info_outline, this.warning = false});
  final String text;
  final IconData icon;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = warning ? cs.tertiaryContainer : cs.secondaryContainer;
    final fg = warning ? cs.onTertiaryContainer : cs.onSecondaryContainer;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 12),
                Expanded(child: Text(text, style: TextStyle(color: fg))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
