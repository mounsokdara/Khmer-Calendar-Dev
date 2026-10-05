import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../i18n.dart';
import '../../store.dart';
import '../../widgets/overlay_page.dart';
import '../../widgets/segmented_list.dart';
import '../../widgets/sheets/language_sheet.dart';
import '../../widgets/sheets/week_start_sheet.dart';
import 'sounds_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return WatchStore(
      store: store,
      builder: (context, store) {
        final lang = store.lang;
        final days = weekdaysFull(lang);
        return OverlayScaffold(
          title: t(lang, 'settingsTitle'),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              SegmentedGroup(
                children: [
                  SegmentedTile(
                    leading: const Icon(Icons.palette),
                    title: t(lang, 'themePageTitle'),
                    subtitle: t(lang, 'themePageSub'),
                    onTap: () => context.push('/settings/theme'),
                  ),
                  SegmentedTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: t(lang, 'notifyPageTitle'),
                    subtitle: t(lang, 'notifyPageSub'),
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  SegmentedTile(
                    leading: const Icon(Icons.volume_up_outlined),
                    title: soundsAndVibrationTitle(lang),
                    subtitle: soundsAndVibrationSub(lang),
                    onTap: () => context.push('/settings/sounds'),
                  ),
                  SegmentedTile(
                    leading: const Icon(Icons.translate),
                    title: t(lang, 'language'),
                    subtitle: store.langPref == 'auto' ? t(lang, 'langAuto') : (store.langPref == 'km' ? 'ខ្មែរ' : 'English'),
                    onTap: () => showLanguageSheet(context, store),
                  ),
                  SegmentedTile(
                    leading: const Icon(Icons.view_week),
                    title: t(lang, 'weekStartsOn'),
                    subtitle: days[store.weekStartsOn],
                    onTap: () => showWeekStartSheet(context, store),
                  ),
                  SegmentedTile(
                    leading: const Icon(Icons.verified_user),
                    title: t(lang, 'privacyTitle'),
                    subtitle: t(lang, 'privacySub'),
                    onTap: () => context.push('/settings/privacy'),
                  ),
                  SegmentedTile(
                    leading: const Icon(Icons.delete_sweep),
                    title: t(lang, 'clearTitle'),
                    subtitle: t(lang, 'clearSub'),
                    onTap: () => context.push('/settings/clear'),
                  ),
                  if (kIsWeb)
                    SegmentedTile(
                      leading: const Icon(Icons.install_mobile),
                      title: t(lang, 'installerTitle'),
                      subtitle: t(lang, 'installerSub'),
                      onTap: () => context.push('/download'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
