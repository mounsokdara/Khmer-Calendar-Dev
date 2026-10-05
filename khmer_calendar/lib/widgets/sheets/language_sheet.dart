import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../store.dart';
import '../overlay_page.dart';
import '../sheet_kit.dart';


Future<void> showLanguageSheet(BuildContext context, AppStore store) {
  return showAppSheet<void>(
    context,
    builder: (ctx) => WatchStore(
      store: store,
      builder: (c, s) => ScrollableSheet(
        header: SheetHeader(
          icon: Icons.translate,
          title: t(s.lang, 'languageTitle'),
          subtitle: t(s.lang, 'sheetLangSub'),
        ),
        children: [
          LangRadios(
            store: s,
            uiLang: s.lang,
            onPicked: () => Navigator.pop(ctx),
          ),
        ],
      ),
    ),
  );
}
