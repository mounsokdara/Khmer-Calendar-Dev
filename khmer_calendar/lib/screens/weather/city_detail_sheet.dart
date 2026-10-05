import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../weather.dart';
import '../../widgets/sheet_kit.dart';
import 'cloud_photo.dart';
import 'weather_icons.dart';


Future<void> showCityDetailSheet(
  BuildContext context, {
  required Lang lang,
  required City city,
  required WeatherSnap? snap,
}) async {
  await showAppSheet<void>(
    context,
    scrollControlled: true,
    builder: (ctx) {
      final meta = snap == null ? null : wmoOf(snap.code);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, sc) {
          return ListView(
            controller: sc,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(height: 140, width: double.infinity, child: CloudPhoto(city: city)),
              ),
              const SizedBox(height: 16),
              SheetHeader(
                title: lang == Lang.en ? city.nameEn : city.name,
                subtitle: t(lang, 'sheetCitySub'),
                icon: Icons.location_on_outlined,
              ),
              if (snap != null) ...[
                Text('${snap.temp}°', style: Theme.of(ctx).textTheme.displaySmall),
                Text(lang == Lang.en ? meta!.en : meta!.km),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(ctx, t(lang, 'humidity'), '${snap.humidity}%'),
                    _chip(ctx, t(lang, 'wind'), '${snap.wind.round()} ${t(lang, 'kmh')}'),
                    _chip(ctx, t(lang, 'uv'), '${snap.uv.round()}'),
                    _chip(ctx, t(lang, 'feels'), '${snap.apparent}°'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(t(lang, 'hourly'), style: Theme.of(ctx).textTheme.titleMedium),
                SizedBox(
                  height: 108,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final h in snap.hourly)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Text(h.time.substring(11, 16)),
                              Image.network(
                                wmoIconUrl(h.code),
                                width: 32,
                                height: 32,
                                errorBuilder: (_, _, _) => Icon(wxMaterialIcon(h.code), size: 28),
                              ),
                              Text('${h.temp}°', style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Text(t(lang, 'weekly'), style: Theme.of(ctx).textTheme.titleMedium),
                for (final d in snap.daily)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Image.network(
                      wmoIconUrl(d.code),
                      width: 36,
                      height: 36,
                      errorBuilder: (_, _, _) => Icon(wxMaterialIcon(d.code), size: 32),
                    ),
                    title: Text(d.date),
                    subtitle: Text(lang == Lang.en ? wmoOf(d.code).en : wmoOf(d.code).km),
                    trailing: Text('${d.high}° / ${d.low}°'),
                  ),
              ] else
                Text(t(lang, 'weatherError')),
            ],
          );
        },
      );
    },
  );
}

Widget _chip(BuildContext ctx, String k, String v) {
  return Chip(label: Text('$k  $v'));
}
