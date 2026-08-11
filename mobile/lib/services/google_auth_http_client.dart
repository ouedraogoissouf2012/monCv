import 'dart:convert';

import '../models/user.dart';
import '../utils/constants.dart';
import 'api/api_errors.dart';
import 'http_timeout.dart' as http;

typedef HeaderFactory = Future<Map<String, String>> Function({bool withAuth});
typedef TokenStore = Future<void> Function(
    String accessToken, String refreshToken);

class GoogleAuthHttpClient {
  const GoogleAuthHttpClient(
      {required this.headers, required this.storeTokens});

  final HeaderFactory headers;
  final TokenStore storeTokens;

  Future<AuthResponse> request(
    String path,
    String credential, {
    required bool withAuth,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authEndpoint}$path'),
      headers: await headers(withAuth: withAuth),
      body: jsonEncode({'credential': credential}),
    );
    if (response.statusCode != 200) {
      throwTypedError(response);
    }
    final auth = AuthResponse.fromJson(jsonDecode(response.body));
    await storeTokens(auth.accessToken, auth.refreshToken);
    return auth;
  }
}
