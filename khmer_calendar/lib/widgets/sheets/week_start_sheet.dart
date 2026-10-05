import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../store.dart';
import '../sheet_kit.dart';


Future<void> showWeekStartSheet(BuildContext context, AppStore store) {
  final lang = store.lang;
  final days = weekdaysFull(lang);
  return showAppSheet<void>(
    context,
    builder: (ctx) => ScrollableSheet(
      header: SheetHeader(
        icon: Icons.view_week,
        title: t(lang, 'weekStartsOn'),
        subtitle: t(lang, 'sheetWeekSub'),
      ),
      children: [
        for (final d in [6, 0, 1])
          SheetOption(
            title: days[d],
            subtitle: t(lang, d == 6 ? 'weekSatSub' : d == 0 ? 'weekSunSub' : 'weekMonSub'),
            selected: store.weekStartsOn == d,
            onTap: () {
              store.setWeekStartsOn(d);
              Navigator.pop(ctx);
            },
          ),
      ],
    ),
  );
}
