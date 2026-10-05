import 'dart:js_interop';

@JS('__khmerInstall.isStandalone')
external JSBoolean _isStandalone();

@JS('__khmerInstall.hasPrompt')
external JSBoolean _hasPrompt();

@JS('__khmerInstall.promptInstall')
external JSPromise<JSBoolean> _promptInstall();

bool browserIsStandalone() {
  try {
    return _isStandalone().toDart;
  } catch (_) {
    return false;
  }
}

Future<bool> promptBrowserInstall() async {
  try {
    if (!_hasPrompt().toDart) return false;
    return (await _promptInstall().toDart).toDart;
  } catch (_) {
    return false;
  }
}
