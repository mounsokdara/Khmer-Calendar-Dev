import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

@JS('Notification')
extension type _DomNotification._(JSObject _) implements JSObject {
  external factory _DomNotification(String title, [JSObject? options]);
  external static JSPromise<JSString> requestPermission();
  external static JSString get permission;
}

Future<bool> requestBrowserNotification() async {
  try {
    final r = (await _DomNotification.requestPermission().toDart).toDart;
    return r == 'granted';
  } catch (_) {
    return false;
  }
}

bool isBrowserNotificationGranted() {
  try {
    return _DomNotification.permission.toDart == 'granted';
  } catch (_) {
    return false;
  }
}

void showBrowserNotification(String title, String body, {String? tag}) {
  final t = tag ?? title;
  try {
    final msg = JSObject()
      ..['type'] = 'khmer-notify'.toJS
      ..['title'] = title.toJS
      ..['body'] = body.toJS
      ..['tag'] = t.toJS;
    web.window.navigator.serviceWorker.controller?.postMessage(msg);
  } catch (_) {}
  try {
    if (_DomNotification.permission.toDart != 'granted') return;
    final opts = JSObject()
      ..['body'] = body.toJS
      ..['icon'] = 'icons/Icon-192.png'.toJS
      ..['tag'] = t.toJS;
    _DomNotification(title, opts);
  } catch (_) {}
}
