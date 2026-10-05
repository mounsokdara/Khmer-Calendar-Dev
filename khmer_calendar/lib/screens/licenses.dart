import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../i18n.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/overlay_page.dart';
import '../widgets/segmented_list.dart';

class _Credit {
  const _Credit(this.title, this.subtitle, {this.url});
  final String title;
  final String subtitle;
  final String? url;
}

const _languages = [
  _Credit('Dart', 'App screens, calendar, weather, and settings'),
  _Credit('Kotlin', 'Android permissions, boot, and notifications'),
  _Credit('Swift', 'iOS and macOS app runner'),
  _Credit('C++', 'Windows and Linux app runner'),
  _Credit('CMake', 'Windows, Linux, and macOS native build'),
  _Credit('HTML, CSS, JavaScript', 'Web build'),
];

const _apis = [
  _Credit(
    'Open-Meteo',
    'Weather forecasts. api.open-meteo.com',
    url: 'https://open-meteo.com',
  ),
  _Credit('Device geolocation', 'Finds the nearest city for weather'),
  _Credit('System notifications', 'Event, holiday, and task reminders'),
  _Credit(
    'Windows Run key',
    'Starts the desktop app at Windows sign-in. Also uses the Startup folder.',
  ),
  _Credit(
    'macOS SMAppService',
    'Registers the app as a login item on macOS 13 and later',
  ),
  _Credit(
    'XDG Autostart',
    'Writes a .desktop file so Linux desktops start the app at login',
  ),
  _Credit(
    'Android App Startup',
    'Re-arms reminders and widgets when the process starts after boot',
  ),
];

const _libraries = [
  _Credit('Flutter', 'UI toolkit and engine'),
  _Credit('go_router', 'In-app routes'),
  _Credit('shared_preferences', 'Saves settings on the device'),
  _Credit('http', 'Weather API requests'),
  _Credit('flutter_svg', 'Zodiac artwork'),
  _Credit('url_launcher', 'Opens source, downloads, and links'),
  _Credit('geolocator', 'GPS location'),
  _Credit('intl', 'Dates and numbers'),
  _Credit('path_provider', 'App files on disk'),
  _Credit('permission_handler', 'Asks the OS for permissions'),
  _Credit('flutter_local_notifications', 'Schedules reminders'),
  _Credit('flutter_timezone', 'Local time zone for alarms'),
  _Credit('timezone', 'Time zone database'),
  _Credit('dynamic_color', 'Wallpaper colors on Material You devices'),
  _Credit('cupertino_icons', 'iOS-style icons'),
];

const _other = [
  _Credit('Flutter engine', 'Skia, Impeller, Dart VM, and platform embedders'),
  _Credit('Kantumruy Pro', 'Khmer and Latin typeface'),
  _Credit('Material Icons', 'Icons in the app'),
  _Credit(
    'OpenWeather icons',
    'Weather icons from openweathermap.org',
    url: 'https://openweathermap.org/weather-conditions',
  ),
  _Credit(
    'Wikipedia',
    'City photos from Wikipedia page summaries',
    url: 'https://www.wikipedia.org',
  ),
  _Credit('Zodiac artwork', 'Khmer animal-year marks'),
  _Credit(
    'Chinese lunar year table',
    'Traditional festival dates for 1900–2100. Same packed civil-lunar encoding used by KhmerDates and other open lunar calendars.',
    url: 'https://github.com/ksx9999/KhmerDates',
  ),
];

Future<Map<String, List<LicenseEntry>>>? _licenseCache;

Future<Map<String, List<LicenseEntry>>> loadLicenseMap() {
  return _licenseCache ??= () async {
    final map = <String, List<LicenseEntry>>{};
    await for (final entry in LicenseRegistry.licenses) {
      for (final pkg in entry.packages) {
        map.putIfAbsent(pkg, () => []).add(entry);
      }
    }
    return map;
  }();
}

String licenseCountLabel(Lang lang, int n) {
  if (lang == Lang.en) {
    return n == 1 ? '1 license.' : '$n licenses.';
  }
  return n == 1 ? '1 អាជ្ញាបណ្ណ។' : '$n អាជ្ញាបណ្ណ។';
}

class OssLicensePage extends StatefulWidget {
  const OssLicensePage({super.key, required this.store});
  final AppStore store;

  @override
  State<OssLicensePage> createState() => _OssLicensePageState();
}

class _OssLicensePageState extends State<OssLicensePage> {
  late Future<Map<String, List<LicenseEntry>>> _future;

  @override
  void initState() {
    super.initState();
    _future = loadLicenseMap();
  }

  @override
  Widget build(BuildContext context) {
    return WatchStore(
      store: widget.store,
      builder: (context, store) {
        final lang = store.lang;
        return OverlayScaffold(
          title: t(lang, 'openSourceLicense'),
          body: FutureBuilder<Map<String, List<LicenseEntry>>>(
            future: _future,
            builder: (context, snap) {
              final packages = snap.data;
              final names = packages == null ? const <String>[] : (packages.keys.toList()..sort());
              return ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  _label(context, t(lang, 'creditsApp')),
                  SegmentedGroup(
                    children: [
                      SegmentedTile(
                        leading: const Icon(Icons.gavel_outlined),
                        title: t(lang, 'mitLicense'),
                        subtitle: '$appAuthor · $appVersion',
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => context.push('/license/app'),
                      ),
                    ],
                  ),
                  _label(context, t(lang, 'creditsLanguages')),
                  _creditGroup(_languages),
                  _label(context, t(lang, 'creditsApis')),
                  _creditGroup(_apis),
                  _label(context, t(lang, 'creditsLibraries')),
                  _creditGroup(_libraries),
                  _label(context, t(lang, 'creditsOther')),
                  _creditGroup(_other),
                  _label(context, t(lang, 'creditsPackages')),
                  if (snap.connectionState != ConnectionState.done)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snap.hasError)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Text(t(lang, 'creditsLoadFail')),
                    )
                  else
                    for (final name in names)
                      ListTile(
                        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(licenseCountLabel(lang, packages![name]!.length)),
                        onTap: () => context.push('/license/pkg/${Uri.encodeComponent(name)}'),
                      ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _creditGroup(List<_Credit> items) {
    return SegmentedGroup(
      children: [
        for (final item in items)
          SegmentedTile(
            title: item.title,
            subtitle: item.subtitle,
            trailing: item.url == null ? null : const Icon(Icons.open_in_new, size: 18),
            onTap: item.url == null
                ? null
                : () => launchUrl(Uri.parse(item.url!), mode: LaunchMode.externalApplication),
          ),
      ],
    );
  }
}

class AppMitLicensePage extends StatelessWidget {
  const AppMitLicensePage({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return WatchStore(
      store: store,
      builder: (context, store) {
        final lang = store.lang;
        final cs = Theme.of(context).colorScheme;
        return OverlayScaffold(
          title: t(lang, 'mitLicense'),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(t(lang, 'creditsApp'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SelectableText(
                mitLicenseText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      color: cs.onSurface,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PackageLicensePage extends StatelessWidget {
  const PackageLicensePage({super.key, required this.store, required this.package});
  final AppStore store;
  final String package;

  @override
  Widget build(BuildContext context) {
    return WatchStore(
      store: store,
      builder: (context, store) {
        final lang = store.lang;
        return OverlayScaffold(
          title: package,
          body: FutureBuilder<Map<String, List<LicenseEntry>>>(
            future: loadLicenseMap(),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final entries = snap.data?[package] ?? const <LicenseEntry>[];
              if (entries.isEmpty) {
                return Center(child: Text(t(lang, 'creditsLoadFail')));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Text(
                    licenseCountLabel(lang, entries.length),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const Divider(height: 32),
                    for (final para in entries[i].paragraphs)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          (para.indent.clamp(0, 8)) * 12.0,
                          0,
                          0,
                          12,
                        ),
                        child: SelectableText(
                          para.text,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}
