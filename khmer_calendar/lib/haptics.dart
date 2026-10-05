import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import 'haptics_platform.dart';

enum HapticsMode { system, on, off }

class Haptics {
  Haptics._();
  static final Haptics instance = Haptics._();

  static const _key = 'hapticsMode';
  static const _channel = MethodChannel('khmer.permissions');
  HapticsMode _mode = HapticsMode.system;

  HapticsMode get mode => _mode;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _mode = switch (raw) {
      'on' => HapticsMode.on,
      'off' => HapticsMode.off,
      _ => kIsWeb ? HapticsMode.on : HapticsMode.system,
    };
  }

  Future<void> setMode(HapticsMode mode) async {
    if (kIsWeb && mode == HapticsMode.system) return;
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  Future<void> tick() async {
    if (_mode == HapticsMode.off) return;

    if (kIsWeb) {
      await platformHapticTick();
      return;
    }

    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    if (_mode == HapticsMode.system &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        final enabled =
            await _channel.invokeMethod<bool>('isHapticFeedbackEnabled') ?? false;
        if (!enabled) return;
      } catch (_) {
        return;
      }
    }

    try {
      if (await Vibration.hasVibrator() != true) return;
      await Vibration.vibrate(duration: 8, amplitude: 40);
    } catch (_) {

    }
  }
}
