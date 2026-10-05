import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../custom_components/slide_snackbar.dart';
import '../../store.dart';
import '../../widgets/dialog_actions.dart';
import '../../widgets/overlay_page.dart';
import '../../widgets/segmented_list.dart';

class ClearPage extends StatelessWidget {
  const ClearPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return WatchStore(
      store: store,
      builder: (context, store) {
        final lang = store.lang;
        final cs = Theme.of(context).colorScheme;
        Future<void> confirm(String key, VoidCallback run) async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(t(lang, key)),
              actions: equalDialogActions([
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: dialogBtnStyle(),
                  child: dlgLabel(t(lang, 'cancel')),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: dialogBtnStyle(),
                  child: dlgLabel(t(lang, 'ok')),
                ),
              ]),
            ),
          );
          if (ok == true) {
            run();
            if (context.mounted) SlideSnackBar.show(context, message: t(lang, 'clearDone'), behavior: SnackBarBehavior.floating);
          }
        }

        return OverlayScaffold(
          title: t(lang, 'clearTitle'),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              SegmentedGroup(
                children: [
                  SegmentedTile(
                    leading: const Icon(Icons.cached),
                    title: t(lang, 'clearCache'),
                    subtitle: t(lang, 'clearCacheSub'),
                    onTap: () => confirm('confirmClearCache', () {}),
                  ),
                  SegmentedTile(
                    leading: const Icon(Icons.alarm_off),
                    title: t(lang, 'clearReminders'),
                    subtitle: t(lang, 'clearRemindersSub'),
                    onTap: () => confirm('confirmClearReminders', store.clearEventReminders),
                  ),
                  SegmentedTile(
                    leading: const Icon(Icons.cloud_off),
                    title: t(lang, 'clearWeather'),
                    subtitle: t(lang, 'clearWeatherSub'),
                    onTap: () => confirm('confirmClearWeather', store.resetWeatherCities),
                  ),
                  SegmentedTile(
                    leading: Icon(Icons.delete_forever, color: cs.error),
                    title: t(lang, 'clearAll'),
                    subtitle: t(lang, 'clearAllSub'),
                    danger: true,
                    onTap: () => confirm('confirmClearAll', store.resetAppData),
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
