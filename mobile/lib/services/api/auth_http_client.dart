import 'dart:convert';

import '../../models/user.dart';
import '../../utils/constants.dart';
import '../http_timeout.dart' as http;
import 'api_errors.dart';

/// Transport HTTP de l'authentification par mot de passe (issue #258, ex-#237).
///
/// Extrait de `ApiService`. L'authentification Google vit dans
/// `GoogleAuthHttpClient`, la deconnexion (purge locale) dans la facade.
class AuthHttpClient {
  const AuthHttpClient({required this.headers, required this.storeTokens});

  final HeaderFactory headers;
  final TokenStore storeTokens;

  Future<AuthResponse> register({
    required String email,
    required String password,
    String? nom,
    String? prenom,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authEndpoint}/register'),
      headers: await headers(withAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
        'nom': nom,
        'prenom': prenom,
      }),
    );
    if (response.statusCode == 201) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await storeTokens(authResponse.accessToken, authResponse.refreshToken);
      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de l\'inscription');
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authEndpoint}/login'),
      headers: await headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await storeTokens(authResponse.accessToken, authResponse.refreshToken);
      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Email ou mot de passe incorrect');
    }
  }
}
