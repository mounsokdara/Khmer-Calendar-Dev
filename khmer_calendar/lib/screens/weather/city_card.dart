import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../weather.dart';
import 'cloud_photo.dart';
import 'weather_icons.dart';

class CityCard extends StatelessWidget {
  const CityCard({
    required this.city,
    required this.snap,
    required this.error,
    required this.lang,
    required this.onOpen,
  });
  final City city;
  final WeatherSnap? snap;
  final bool error;
  final Lang lang;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final meta = snap == null ? null : wmoOf(snap!.code);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onOpen,
        child: Stack(
          children: [
            Positioned.fill(child: CloudPhoto(city: city)),
            Container(
              height: 168,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lang == Lang.en ? city.nameEn : city.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(
                          error ? t(lang, 'weatherError') : (snap == null ? t(lang, 'loading') : (lang == Lang.en ? meta!.en : meta!.km)),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Text(snap == null ? '-' : '${snap!.temp}°', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w600)),
                  if (snap != null)
                    Image.network(
                      wmoIconUrl(snap!.code),
                      width: 48,
                      height: 48,
                      errorBuilder: (_, _, _) => Icon(wxMaterialIcon(snap!.code), size: 40, color: Colors.white),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
