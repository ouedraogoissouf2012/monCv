import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> savePdfBytes(List<int> bytes, String filename) async {
  final blob = web.Blob(
    [Uint8List.fromList(bytes).toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
}
