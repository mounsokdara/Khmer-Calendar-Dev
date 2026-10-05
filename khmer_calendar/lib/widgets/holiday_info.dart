import 'package:flutter/material.dart';

import '../calendar/observances.dart';
import '../dates.dart';
import '../i18n.dart';
import '../store.dart';
import 'dialog_actions.dart';

Future<void> showHolidayInfo(BuildContext context, AppStore store, Observance item) {
  final lang = store.lang;
  final kindKey = switch (item.kind) {
    Kind.holiday => 'kindHoliday',
    Kind.sil => 'kindSil',
    Kind.event => 'kindEvent',
  };
  final type = item.holidayType == null ? '' : ' · ${holidayTypeLabel(item.holidayType!, lang)}';
  final sub = obsSub(item, lang);
  final d = item.date.isEmpty ? DateTime.now() : fromIso(item.date);
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(obsTitle(item, lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t(lang, kindKey)}$type', style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            Text(gregorianLabel(d, lang)),
            const SizedBox(height: 8),
            if (item.date.isNotEmpty) Text(lunarLabel(item.date, lang)),
            if (item.kind == Kind.sil) ...[
              const SizedBox(height: 12),
              Text(t(lang, 'silBlurb'), style: TextStyle(color: cs.onSurfaceVariant)),
            ],
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(sub, style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ],
        ),
        actions: equalDialogActions([
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: dialogBtnStyle(),
            child: dlgLabel(t(lang, 'close')),
          ),
        ]),
      );
    },
  );
}
