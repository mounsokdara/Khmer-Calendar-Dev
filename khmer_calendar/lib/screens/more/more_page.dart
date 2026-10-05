import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../home_screen.dart';
import '../../i18n.dart';
import '../../store.dart';
import '../../custom_components/slide_snackbar.dart';
import '../../widgets/overlay_page.dart';
import '../../widgets/segmented_list.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return WatchStore(
      store: store,
      builder: (context, store) {
        final lang = store.lang;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(t(lang, 'moreTitle'), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            SegmentedGroup(
              padding: EdgeInsets.zero,
              children: [
                SegmentedTile(
                  leading: const Icon(Icons.settings),
                  title: t(lang, 'settingsTitle'),
                  subtitle: t(lang, 'settingsSub'),
                  onTap: () => context.push('/settings'),
                ),
                SegmentedTile(
                  leading: const Icon(Icons.build),
                  title: t(lang, 'toolsTitle'),
                  subtitle: t(lang, 'toolsPageSub'),
                  onTap: () => context.push('/tools'),
                ),
                SegmentedTile(
                  leading: const Icon(Icons.info_outline),
                  title: t(lang, 'aboutTitle'),
                  subtitle: t(lang, 'aboutSub'),
                  onTap: () => context.push('/about'),
                ),
              ],
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 16),
              SegmentedGroup(
                padding: EdgeInsets.zero,
                children: [
                  SegmentedTile(
                    leading: const Icon(Icons.install_mobile),
                    title: t(lang, 'installerTitle'),
                    subtitle: t(lang, 'installerSub'),
                    onTap: () => context.push('/download'),
                  ),
                ],
              ),
            ],
            if (canPinHomeWidget) ...[
              const SizedBox(height: 16),
              SegmentedGroup(
                padding: EdgeInsets.zero,
                children: [
                  SegmentedTile(
                    leading: const Icon(Icons.widgets_outlined),
                    title: t(lang, 'homeWidget'),
                    subtitle: t(lang, 'homeWidgetSub'),
                    trailing: const Icon(Icons.add),
                    onTap: () => _pickWidget(context, store),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

Future<void> _pickWidget(BuildContext context, AppStore store) async {
  final lang = store.lang;
  final kind = await showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(t(lang, 'homeWidget')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.today),
            title: Text(t(lang, 'widgetToday')),
            onTap: () => Navigator.pop(d, 'today'),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(t(lang, 'widgetMonth')),
            onTap: () => Navigator.pop(d, 'month'),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: Text(t(lang, 'widgetWeather')),
            onTap: () => Navigator.pop(d, 'weather'),
          ),
        ],
      ),
    ),
  );
  if (kind == null || !context.mounted) return;
  await syncHomeWidget(store);
  if (kind == 'weather') await syncWeatherWidget(store);
  final ok = await pinHomeWidget(kind);
  if (!context.mounted) return;
  SlideSnackBar.show(
    context,
    message: t(lang, ok ? 'homeWidgetPinned' : 'homeWidgetHow'),
    behavior: SnackBarBehavior.floating,
  );
}
