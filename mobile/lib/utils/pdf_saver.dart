export 'pdf_saver_stub.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'pdf_saver_web.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) 'pdf_saver_io.dart';
