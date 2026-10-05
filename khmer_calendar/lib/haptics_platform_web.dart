import 'dart:js_interop';

@JS('window.__khmerHapticsTick')
external JSBoolean? _webHapticTick();

Future<void> platformHapticTick() async {
  try {
    _webHapticTick();
  } catch (_) {

  }
}
