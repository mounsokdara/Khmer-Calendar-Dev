import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n.dart';
import '../../store.dart';
import '../../theme.dart';
import '../../widgets/overlay_page.dart';
import '../../widgets/segmented_list.dart';
import 'update_checker.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return WatchStore(
      store: store,
      builder: (context, store) {
        final lang = store.lang;
        return OverlayScaffold(
          title: t(lang, 'aboutTitle'),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              SegmentedGroup(
                children: [
                  SegmentedTile(
                    leading: const Icon(Icons.person_outline),
                    title: t(lang, 'createdBy'),
                    subtitle: appAuthor,
                  ),
                  SegmentedTile(
                    leading: const Icon(Icons.tag),
                    title: t(lang, 'buildVersion'),
                    subtitle: '$appVersion ($appBuildNumber)',
                  ),
                  SegmentedTile(
                    leading: const Icon(Icons.system_update_outlined),
                    title: lang == Lang.km ? 'ពិនិត្យកំណែថ្មី' : 'Check for updates',
                    subtitle: lang == Lang.km ? 'ពិនិត្យកំណែថ្មីពី GitHub' : 'Check GitHub for a newer release',
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => _checkForUpdate(context, lang),
                  ),
                  SegmentedTile(
                    leading: const Icon(Icons.gavel_outlined),
                    title: t(lang, 'openSourceLicense'),
                    subtitle: t(lang, 'mitLicense'),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => context.push('/license'),
                  ),
                  SegmentedTile(
                    leading: const Icon(Icons.code),
                    title: t(lang, 'sourceCode'),
                    subtitle: appSourceUrl,
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => launchUrl(Uri.parse(appSourceUrl), mode: LaunchMode.externalApplication),
                  ),
                  SegmentedTile(
                    leading: const Icon(Icons.language),
                    title: t(lang, 'website'),
                    subtitle: appWebsiteUrl,
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => launchUrl(Uri.parse(appWebsiteUrl), mode: LaunchMode.externalApplication),
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

Future<void> _checkForUpdate(BuildContext context, Lang lang) async {
  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2)),
          const SizedBox(width: 16),
          Text(lang == Lang.km ? 'កំពុងពិនិត្យកំណែថ្មី…' : 'Checking for updates…'),
        ],
      ),
    ),
  );

  UpdateInfo? update;
  String? error;
  try {
    update = await checkForAppUpdate();
  } on services.PlatformException {
    error = lang == Lang.km ? 'មិនអាចពិនិត្យកំណែថ្មីបានទេ។' : 'Unable to check for updates.';
  } catch (_) {
    error = lang == Lang.km ? 'មិនអាចពិនិត្យកំណែថ្មីបានទេ។' : 'Unable to check for updates.';
  }

  if (context.mounted) Navigator.of(context).pop();
  if (!context.mounted) return;

  if (error != null) {
    await showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(lang == Lang.km ? 'ពិនិត្យកំណែថ្មី' : 'Check for updates'),
        content: Text(error!),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: Text(lang == Lang.km ? 'យល់ព្រម' : 'OK'))],
      ),
    );
    return;
  }

  if (update == null) {
    await showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(lang == Lang.km ? 'កំណែថ្មី' : 'Updates'),
        content: Text(lang == Lang.km ? 'កម្មវិធីរបស់អ្នកជាកំណែថ្មីបំផុត។' : 'You are using the latest version.'),
        actions: [TextButton(onPressed: () => Navigator.pop(d), child: Text(lang == Lang.km ? 'យល់ព្រម' : 'OK'))],
      ),
    );
    return;
  }

  await showDialog<void>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(lang == Lang.km ? 'មានកំណែថ្មី' : 'Update available'),
      content: Text(
        lang == Lang.km
            ? 'មានកំណែ ${update!.version}។ កំណែបច្ចុប្បន្នគឺ $currentAppVersion។'
            : 'Version ${update!.version} is available. You are using $currentAppVersion.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: Text(lang == Lang.km ? 'បិទ' : 'Close')),
        FilledButton(
          onPressed: () async {
            await openLatestRelease(update!.url);
            if (d.mounted) Navigator.pop(d);
          },
          child: Text(lang == Lang.km ? 'មើលកំណែថ្មី' : 'View update'),
        ),
      ],
    ),
  );
}
