Future<void> savePdfBytes(List<int> bytes, String filename) async {
  throw UnsupportedError('PDF saving not supported on this platform');
}

Future<void> saveBytes(
  List<int> bytes,
  String filename,
  String mimeType,
) async {
  throw UnsupportedError('File saving not supported on this platform');
}
