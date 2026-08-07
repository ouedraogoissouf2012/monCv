import 'dart:convert';

import '../../models/user.dart';
import '../../utils/constants.dart';
import '../http_timeout.dart' as http;
import 'api_errors.dart';

/// Transport HTTP du profil utilisateur (issue #258, ex-#237). Extrait de
/// `ApiService`. La suppression de compte purge les jetons locaux via
/// [clearTokens] apres confirmation du serveur.
class UserHttpClient {
  const UserHttpClient({required this.headers, required this.clearTokens});

  final HeaderFactory headers;
  final TokenPurge clearTokens;

  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersEndpoint}/me'),
      headers: await headers(),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la recuperation du profil');
    }
  }

  Future<User> updateProfile({String? nom, String? prenom}) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersEndpoint}/me'),
      headers: await headers(),
      body: jsonEncode({
        if (nom != null) 'nom': nom,
        if (prenom != null) 'prenom': prenom,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la mise a jour du profil');
    }
  }

  Future<Map<String, dynamic>> exportUserData() async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.usersEndpoint}/me/export',
      ),
      headers: await headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Erreur lors de l\'export des donnees');
    }
  }

  Future<void> deleteAccount() async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersEndpoint}/me'),
      headers: await headers(),
    );
    if (response.statusCode == 204) {
      await clearTokens();
      return;
    }
    throw Exception('Erreur lors de la suppression du compte');
  }
}
