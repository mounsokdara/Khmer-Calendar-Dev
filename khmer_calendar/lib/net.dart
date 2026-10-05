import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetStatus {
  static final ValueNotifier<bool> online = ValueNotifier(true);
  static StreamSubscription<List<ConnectivityResult>>? _sub;

  static bool get isOffline => !online.value;

  static bool _up(List<ConnectivityResult> r) => r.any((x) => x != ConnectivityResult.none);

  static Future<void> start() async {
    final c = Connectivity();
    try {
      online.value = _up(await c.checkConnectivity());
    } catch (_) {
      online.value = true;
    }
    await _sub?.cancel();
    _sub = c.onConnectivityChanged.listen((r) => online.value = _up(r));
  }
}
