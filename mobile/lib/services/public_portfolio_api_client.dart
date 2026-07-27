import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/error/error_mapper.dart';
import '../core/security/public_share_token.dart';
import '../features/cv/data/mappers/cv_mapper.dart';
import '../features/cv/presentation/cv_presentation_model.dart';
import '../utils/constants.dart';
import 'bounded_http_reader.dart';
import 'secure_photo_api_client.dart';

final class PublicPortfolioApiClient {
  PublicPortfolioApiClient(http.Client client)
      : _client = client,
        _reader = BoundedHttpReader(client),
        _securePhotoApi = SecurePhotoApiClient(client);

  static const _readTimeout = Duration(seconds: 10);
  static const _downloadTimeout = Duration(seconds: 30);
  static const _maxPortfolioBytes = 2 * 1024 * 1024;
  static const _maxDocumentBytes = 10 * 1024 * 1024;

  final http.Client _client;
  final BoundedHttpReader _reader;
  final SecurePhotoApiClient _securePhotoApi;

  Future<Uint8List?> loadPhoto(String? url, String? accessToken) =>
      _securePhotoApi.load(url, accessToken: accessToken);

  Future<Cv> getPortfolio(String token) async {
    final response = await _reader.get(
      _uri(token),
      maxBytes: _maxPortfolioBytes,
      timeout: _readTimeout,
      expectedContentType: 'application/json',
    );
    if (response.statusCode != 200) _throwError(response.toHttpResponse());
    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Reponse de portfolio invalide');
    }
    return Cv.fromEntity(
      const CvMapper().fromNetworkJson(_normalizeMediaUrls(json)),
    );
  }

  Future<List<int>> download(String token, String format) async {
    final normalizedFormat = switch (format.toLowerCase()) {
      'pdf' => 'pdf',
      'docx' => 'docx',
      _ => throw const FormatException('Format de document invalide'),
    };
    final expectedContentType = normalizedFormat == 'pdf'
        ? 'application/pdf'
        : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    final response = await _reader.get(
      _uri(token, normalizedFormat),
      maxBytes: _maxDocumentBytes,
      timeout: _downloadTimeout,
      expectedContentType: expectedContentType,
    );
    if (response.statusCode != 200) _throwError(response.toHttpResponse());
    return response.bodyBytes;
  }

  Future<void> trackShare(String token) async {
    final response = await _client
        .post(
          _uri(token, 'share'),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: '{}',
        )
        .timeout(_readTimeout);
    if (response.statusCode != 204) _throwError(response);
  }

  Uri _uri(String token, [String? action]) {
    final validToken = PublicShareToken.requireValid(token);
    final base = Uri.parse(ApiConstants.baseUrl);
    return base.replace(
      pathSegments: [
        ...base.pathSegments.where((segment) => segment.isNotEmpty),
        'cvs',
        'public',
        validToken,
        if (action != null) action,
      ],
      query: null,
      fragment: null,
    );
  }

  Map<String, dynamic> _normalizeMediaUrls(Map<String, dynamic> source) {
    final result = Map<String, dynamic>.from(source);
    final personalInfo = source['personalInfo'];
    if (personalInfo is! Map<String, dynamic>) return result;
    final normalizedInfo = Map<String, dynamic>.from(personalInfo);
    final photoUrl = normalizedInfo['photoUrl'];
    if (photoUrl is String && photoUrl.startsWith('/')) {
      normalizedInfo['photoUrl'] =
          Uri.parse(ApiConstants.baseUrl).resolve(photoUrl).toString();
    }
    result['personalInfo'] = normalizedInfo;
    return result;
  }

  Never _throwError(http.Response response) {
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // Le mapper fournit un message generique si la reponse n'est pas du JSON.
    }
    throw ErrorMapper.fromHttpResponse(response.statusCode, body);
  }
}
