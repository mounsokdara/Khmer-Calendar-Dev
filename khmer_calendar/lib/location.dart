import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'i18n.dart';
import 'store.dart';
import 'weather.dart';
import 'custom_components/slide_snackbar.dart';

enum GpsResult { added, already, denied, disabled, failed }

String gpsMessage(Lang lang, GpsResult result) {
  switch (result) {
    case GpsResult.added:
    case GpsResult.already:
      return t(lang, 'locAdded');
    case GpsResult.denied:
      return t(lang, 'permDenied');
    case GpsResult.disabled:
    case GpsResult.failed:
      return t(lang, 'noLocation');
  }
}

LocationSettings _gpsSettings() {
  const limit = Duration(seconds: 15);
  if (kIsWeb) {
    return const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: limit);
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return AndroidSettings(
        accuracy: LocationAccuracy.medium,
        forceLocationManager: true,
        timeLimit: limit,
      );
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return AppleSettings(accuracy: LocationAccuracy.medium, timeLimit: limit);
    default:
      return const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: limit);
  }
}

bool locationPermissionGranted(LocationPermission perm) {
  return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
}


Future<GpsResult> requestNearbyCity(AppStore store) async {
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      try {
        await Geolocator.openLocationSettings();
      } catch (_) {}
      final again = await Geolocator.isLocationServiceEnabled();
      if (!again) return GpsResult.disabled;
    }
    var perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (!locationPermissionGranted(perm)) {
      return GpsResult.denied;
    }
    Position? last;
    try {
      last = await Geolocator.getLastKnownPosition();
    } catch (_) {}
    late final Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(locationSettings: _gpsSettings());
    } catch (_) {
      if (last == null) return GpsResult.failed;
      pos = last;
    }
    final city = nearestCity(pos.latitude, pos.longitude);
    final existed = store.weatherCities.contains(city.id);
    store.addWeatherCity(city.id);
    return existed ? GpsResult.already : GpsResult.added;
  } catch (_) {
    return GpsResult.failed;
  }
}

void showGpsSnack(BuildContext context, Lang lang, GpsResult result) {
  if (!context.mounted) return;
  SlideSnackBar.show(context, message: gpsMessage(lang, result), behavior: SnackBarBehavior.floating);
}
