# geolocator_android 5.0.3 (Khmer Calendar fork)

Copy of [geolocator_android 5.0.3](https://github.com/Baseflow/flutter-geolocator/tree/geolocator_android_v5.0.3/geolocator_android)
(MIT, see LICENSE) with the Google Play Services backend removed, so the app contains no proprietary
Google libraries (F-Droid requirement).

Changes against upstream:
- `android/build.gradle`: removed the `com.google.android.gms:play-services-location` dependency.
- `FusedLocationClient.java`: deleted.
- `GeolocationManager.createLocationClient`: always returns `LocationManagerClient`.

The app already forced `LocationManager` (`lib/location.dart`), so behaviour is unchanged.
It is used through `dependency_overrides` in `khmer_calendar/pubspec.yaml`.
