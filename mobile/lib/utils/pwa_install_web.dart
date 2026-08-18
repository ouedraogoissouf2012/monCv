import 'package:web/web.dart' as web;

Future<bool> promptPwaInstall() async {
  final ua = web.window.navigator.userAgent.toLowerCase();
  if (ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod')) {
    return false;
  }
  web.window.location.assign('/downloads/moncv.apk');
  return true;
}
