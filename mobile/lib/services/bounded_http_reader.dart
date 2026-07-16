import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

final class ResponseTooLargeException implements Exception {
  const ResponseTooLargeException(this.maxBytes);

  final int maxBytes;

  @override
  String toString() => 'ResponseTooLargeException(maxBytes: $maxBytes)';
}

final class UnexpectedContentTypeException implements Exception {
  const UnexpectedContentTypeException(this.actual, this.expected);

  final String? actual;
  final String expected;
}

final class BoundedHttpResponse {
  const BoundedHttpResponse({
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
  });

  final int statusCode;
  final Map<String, String> headers;
  final Uint8List bodyBytes;

  String get body => utf8.decode(bodyBytes);

  http.Response toHttpResponse() =>
      http.Response.bytes(bodyBytes, statusCode, headers: headers);
}

final class BoundedHttpReader {
  const BoundedHttpReader(this.client);

  final http.Client client;

  Future<BoundedHttpResponse> get(
    Uri uri, {
    required int maxBytes,
    required Duration timeout,
    required String expectedContentType,
    Map<String, String> headers = const {},
  }) async {
    final request = http.Request('GET', uri)
      ..headers.addAll(headers)
      ..headers['Accept'] = expectedContentType;
    final response = await client.send(request).timeout(timeout);
    final declaredLength = response.contentLength;
    if (declaredLength != null && declaredLength > maxBytes) {
      throw ResponseTooLargeException(maxBytes);
    }

    final bytes = BytesBuilder(copy: false);
    var received = 0;
    await for (final chunk in response.stream.timeout(timeout)) {
      received += chunk.length;
      if (received > maxBytes) throw ResponseTooLargeException(maxBytes);
      bytes.add(chunk);
    }

    final body = bytes.takeBytes();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final contentType = response.headers['content-type'];
      if (contentType == null ||
          !contentType.toLowerCase().startsWith(
                expectedContentType.toLowerCase(),
              )) {
        throw UnexpectedContentTypeException(contentType, expectedContentType);
      }
    }
    return BoundedHttpResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      bodyBytes: body,
    );
  }
}
