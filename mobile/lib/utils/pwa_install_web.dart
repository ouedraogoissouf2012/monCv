import 'dart:js_interop';

@JS('promptMoncvInstall')
external JSPromise<JSString> _promptMoncvInstall();

Future<bool> promptPwaInstall() async {
  try {
    final outcome = (await _promptMoncvInstall().toDart).toDart;
    return outcome == 'accepted';
  } catch (_) {
    return false;
  }
}
