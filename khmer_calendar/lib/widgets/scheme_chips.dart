import 'package:flutter/material.dart';

import '../i18n.dart';
import '../store.dart';
import '../theme.dart';
import 'dialog_actions.dart';
import 'segmented_list.dart';

const colorPresets = [
  '#F5C400',
  '#FF3B30',
  '#FF9500',
  '#34C759',
  '#007AFF',
  '#5856D6',
  '#AF52DE',
  '#FF2D55',
  '#5AC8FA',
  '#8E8E93',
  '#1C1C1E',
  '#9A3B38',
];

class SchemeChipScroller extends StatelessWidget {
  const SchemeChipScroller({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final enabled = store.materialYou && !store.dynamicColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(store.lang == Lang.km ? 'ពណ៌ Material You' : 'Material You Color'),
        Semantics(
          label: t(store.lang, 'schemeAria'),
          child: SizedBox(
            height: 76,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              scrollDirection: Axis.horizontal,
              itemCount: schemes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final s = schemes[i];
                final selected = store.colorScheme == s.id;
                return Opacity(
                  opacity: store.dynamicColor || enabled ? 1 : 0.38,
                  child: Tooltip(
                    message: s.label,
                    child: _SchemeChipButton(
                      chip: s,
                      selected: selected,
                      onTap: enabled ? () => store.setColorScheme(s.id) : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SchemeChipButton extends StatelessWidget {
  const _SchemeChipButton({required this.chip, required this.selected, required this.onTap});
  final SchemeChip chip;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.4)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: chip.top,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? chip.circle : Colors.transparent, width: 3),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
                  child: Container(height: 32, color: chip.bot),
                ),
              ),
              Center(
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(color: chip.circle, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ColorRow extends StatelessWidget {
  const ColorRow({
    super.key,
    required this.title,
    required this.value,
    required this.onPick,
    this.subtitle,
    this.icon,
    this.disabled = false,
    this.compact = false,
  });
  final String title;
  final String? subtitle;
  final String value;
  final VoidCallback onPick;
  final IconData? icon;
  final bool disabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.38 : 1,
      child: ListTile(
        contentPadding: compact
            ? const EdgeInsets.fromLTRB(16, 4, 12, 4)
            : const EdgeInsets.fromLTRB(20, 8, 16, 8),
        leading: icon == null ? null : Icon(icon, size: 24),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 15 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle == null ? null : Text(subtitle!, maxLines: 3, overflow: TextOverflow.ellipsis),
        trailing: Container(
          width: compact ? 24 : 28,
          height: compact ? 24 : 28,
          decoration: BoxDecoration(
            color: hexColor(value),
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        onTap: disabled ? null : onPick,
      ),
    );
  }
}

Future<void> showColorPicker(
  BuildContext context, {
  required Lang lang,
  required String title,
  required String value,
  required ValueChanged<String> onSave,
}) async {
  var v = value.toUpperCase();
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSt) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 72,
                    width: double.infinity,
                    decoration: BoxDecoration(color: hexColor(v), borderRadius: BorderRadius.circular(16)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in colorPresets)
                        GestureDetector(
                          onTap: () => setSt(() => v = p),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: hexColor(p),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: v.toUpperCase() == p ? Theme.of(ctx).colorScheme.onSurface : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Slider(
                    min: 0,
                    max: 360,
                    value: hueFromHex(v).clamp(0, 360),
                    onChanged: (n) => setSt(() => v = hueHex(n)),
                  ),
                ],
              ),
            ),
            actions: equalDialogActions([
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: dialogBtnStyle(),
                child: dlgLabel(t(lang, 'cancel')),
              ),
              FilledButton(
                onPressed: () {
                  onSave(v);
                  Navigator.pop(ctx);
                },
                style: dialogBtnStyle(),
                child: dlgLabel(t(lang, 'save')),
              ),
            ]),
          );
        },
      );
    },
  );
}
