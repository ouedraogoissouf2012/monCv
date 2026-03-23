import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import '../models/cv.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _accessToken;

  Future<String?> get accessToken async {
    _accessToken ??= await _storage.read(key: 'access_token');
    return _accessToken;
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withAuth) {
      final token = await accessToken;
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Auth endpoints
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? nom,
    String? prenom,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authEndpoint}/register'),
      headers: await _getHeaders(withAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
        'nom': nom,
        'prenom': prenom,
      }),
    );

    if (response.statusCode == 201) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await setTokens(authResponse.accessToken, authResponse.refreshToken);
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
      headers: await _getHeaders(withAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await setTokens(authResponse.accessToken, authResponse.refreshToken);
      return authResponse;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Email ou mot de passe incorrect');
    }
  }

  Future<void> logout() async {
    await clearTokens();
  }

  // User endpoints
  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersEndpoint}/me'),
      headers: await _getHeaders(),
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
      headers: await _getHeaders(),
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

  // CV endpoints
  Future<List<Cv>> getAllCvs() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Cv.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors de la recuperation des CV');
    }
  }

  Future<Cv> getCvById(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Cv.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('CV non trouve');
    }
  }

  Future<Cv> createCv(Cv cv) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}'),
      headers: await _getHeaders(),
      body: jsonEncode(cv.toJson()),
    );

    if (response.statusCode == 201) {
      return Cv.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de la creation du CV');
    }
  }

  Future<Cv> updateCv(int id, Cv cv) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(cv.toJson()),
    );

    if (response.statusCode == 200) {
      return Cv.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Erreur lors de la mise a jour du CV');
    }
  }

  Future<void> deleteCv(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Erreur lors de la suppression du CV');
    }
  }
}
