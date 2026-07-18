import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/security/public_share_token.dart';
import '../utils/constants.dart';
import 'bounded_http_reader.dart';

final class SecurePhotoApiClient {
  SecurePhotoApiClient(http.Client client)
      : _reader = BoundedHttpReader(client);

  static const _maxPhotoBytes = 2 * 1024 * 1024;
  static const _timeout = Duration(seconds: 10);
  static final _filenamePattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\.(?:jpg|jpeg|png|webp)$',
  );

  final BoundedHttpReader _reader;

  Future<Uint8List?> load(String? rawUrl, {String? accessToken}) async {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    final target = _trustedTarget(rawUrl);
    final headers = <String, String>{};
    if (target.requiresAuthentication) {
      if (accessToken == null || accessToken.isEmpty) return null;
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await _reader.get(
      target.uri,
      maxBytes: _maxPhotoBytes,
      timeout: _timeout,
      expectedContentType: target.contentType,
      headers: headers,
    );
    if (response.statusCode != 200) return null;
    return _hasExpectedSignature(response.bodyBytes, target.contentType)
        ? response.bodyBytes
        : null;
  }

  _PhotoTarget _trustedTarget(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    final api = Uri.parse(ApiConstants.baseUrl);
    if (uri == null ||
        uri.scheme != api.scheme ||
        uri.host != api.host ||
        uri.port != api.port ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty) {
      throw const FormatException('URL de photo non autorisee');
    }

    final apiSegments = api.pathSegments.where((part) => part.isNotEmpty);
    final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    final prefix = apiSegments.toList();
    if (!_startsWith(segments, prefix)) {
      throw const FormatException('URL de photo non autorisee');
    }
    final remaining = segments.sublist(prefix.length);

    if (remaining.length == 3 &&
        remaining[0] == 'uploads' &&
        remaining[1] == 'photos' &&
        _filenamePattern.hasMatch(remaining[2])) {
      return _PhotoTarget(uri, _contentType(remaining[2]), true);
    }
    if (remaining.length == 4 &&
        remaining[0] == 'cvs' &&
        remaining[1] == 'public' &&
        PublicShareToken.isValid(remaining[2]) &&
        remaining[3] == 'photo') {
      return _PhotoTarget(uri, 'image/', false);
    }
    throw const FormatException('URL de photo non autorisee');
  }

  bool _startsWith(List<String> value, List<String> prefix) {
    if (value.length < prefix.length) return false;
    for (var index = 0; index < prefix.length; index++) {
      if (value[index] != prefix[index]) return false;
    }
    return true;
  }

  String _contentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  bool _hasExpectedSignature(Uint8List bytes, String contentType) {
    final jpeg = _startsWithBytes(bytes, const [0xFF, 0xD8, 0xFF]);
    final png = _startsWithBytes(
      bytes,
      const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    );
    final webp = _startsWithBytes(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
        bytes.length >= 12 &&
        _matchesAt(bytes, 8, const [0x57, 0x45, 0x42, 0x50]);
    return switch (contentType) {
      'image/jpeg' => jpeg,
      'image/png' => png,
      'image/webp' => webp,
      _ => jpeg || png || webp,
    };
  }

  bool _startsWithBytes(Uint8List bytes, List<int> expected) =>
      _matchesAt(bytes, 0, expected);

  bool _matchesAt(Uint8List bytes, int offset, List<int> expected) {
    if (bytes.length < offset + expected.length) return false;
    for (var index = 0; index < expected.length; index++) {
      if (bytes[offset + index] != expected[index]) return false;
    }
    return true;
  }
}

final class _PhotoTarget {
  const _PhotoTarget(this.uri, this.contentType, this.requiresAuthentication);

  final Uri uri;
  final String contentType;
  final bool requiresAuthentication;
}
