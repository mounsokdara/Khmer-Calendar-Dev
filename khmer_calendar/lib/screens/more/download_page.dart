import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../net.dart';
import '../../store.dart';
import '../../web_install.dart';
import '../../widgets/os_logo.dart';
import '../../widgets/overlay_page.dart';
import '../../widgets/segmented_list.dart';
import 'install_helpers.dart';

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return WatchStore(
      store: store,
      builder: (context, store) {
        final lang = store.lang;
        final packs = [
          ('android', 'KhmerCalendar.apk', 'exportApk', 'exportApkSub'),
          ('windows', 'KhmerCalendar-windows.zip', 'exportWindows', 'exportWindowsSub'),
          ('macos', 'KhmerCalendar.dmg', 'exportMac', 'exportMacSub'),
          ('linux', 'KhmerCalendar-linux.tar.gz', 'exportLinux', 'exportLinuxSub'),
          ('project', 'KhmerCalendar-project.zip', 'downloadProject', 'downloadProjectSub'),
        ];
        return OverlayScaffold(
          title: t(lang, 'downloadTitle'),
          body: ValueListenableBuilder<bool>(
            valueListenable: NetStatus.online,
            builder: (context, online, _) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(t(lang, 'downloadSub')),
                  const SizedBox(height: 12),
                  if (kIsWeb) ...[
                    SegmentedGroup(
                      padding: EdgeInsets.zero,
                      children: [
                        SegmentedTile(
                          leading: const Icon(Icons.install_mobile),
                          title: t(lang, store.installed || browserIsStandalone() ? 'exportInstalled' : 'exportBrowser'),
                          subtitle: t(lang, 'exportBrowserSub'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => openBrowserInstall(context, store: store, lang: lang),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  SegmentedGroup(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final p in packs)
                        SegmentedTile(
                          dim: !online,
                          leading: p.$1 == 'project' ? const Icon(Icons.folder_zip) : OsLogo(p.$1),
                          title: t(lang, p.$3),
                          subtitle: t(lang, p.$4),
                          trailing: const Icon(Icons.download),
                          onTap: () => openPackDownload(context, lang: lang, file: p.$2),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
