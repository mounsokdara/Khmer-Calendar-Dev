import 'package:flutter/material.dart';

class SegmentedGroup extends StatelessWidget {
  const SegmentedGroup({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.filled = true,
  });
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool filled;

  static const _gap = 7.0;
  static const _big = 26.0;
  static const _small = 6.0;
  static const _maxWidth = 560.0;

  static BorderRadius radiusFor(int index, int count) {
    if (count <= 1) return BorderRadius.circular(_big);
    if (index == 0) {
      return const BorderRadius.only(
        topLeft: Radius.circular(_big),
        topRight: Radius.circular(_big),
        bottomLeft: Radius.circular(_small),
        bottomRight: Radius.circular(_small),
      );
    }
    if (index == count - 1) {
      return const BorderRadius.only(
        topLeft: Radius.circular(_small),
        topRight: Radius.circular(_small),
        bottomLeft: Radius.circular(_big),
        bottomRight: Radius.circular(_big),
      );
    }
    return BorderRadius.circular(_small);
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxWidth),
        child: Padding(
          padding: padding,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: _gap),
                Material(
                  color: filled ? cs.surfaceContainer : Colors.transparent,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: radiusFor(i, children.length)),
                  child: children[i],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SegmentedTile extends StatelessWidget {
  const SegmentedTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.selected = false,
    this.dim = false,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool selected;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleColor = (danger ? cs.error : cs.onSurface).withValues(alpha: dim ? 0.38 : 1);
    final subColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      minVerticalPadding: 8,
      leading: leading == null ? null : (dim ? Opacity(opacity: 0.45, child: leading!) : leading),
      selected: selected,
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: subColor),
            ),
      trailing: trailing == null ? null : (dim ? Opacity(opacity: 0.45, child: trailing!) : trailing),
      onTap: onTap,
    );
  }
}

class SegmentedSwitch extends StatelessWidget {
  const SegmentedSwitch({
    super.key,
    this.icon,
    this.leading,
    this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final IconData? icon;
  final Widget? leading;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      dense: compact,
      contentPadding: compact
          ? const EdgeInsets.fromLTRB(16, 4, 12, 4)
          : const EdgeInsets.fromLTRB(20, 8, 16, 8),
      secondary: leading ?? (icon == null ? null : Icon(icon, size: 24, color: iconColor)),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: compact ? 15 : 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
            ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color ?? cs.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
