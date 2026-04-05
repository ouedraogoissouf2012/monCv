import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import '../models/cv.dart';
import 'token_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final TokenStorage _storage = TokenStorage();
  String? _accessToken;

  Future<String?> get accessToken async {
    _accessToken ??= await _storage.read('access_token');
    return _accessToken;
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    await _storage.write('access_token', accessToken);
    await _storage.write('refresh_token', refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    await _storage.delete('access_token');
    await _storage.delete('refresh_token');
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

  /// Upload une photo de profil et retourne son URL relative.
  /// L'URL complète s'obtient avec [ApiConstants.baseUrl] + url.
  Future<String> uploadPhoto(XFile photo) async {
    final token = await accessToken;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/uploads/photo'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      await http.MultipartFile.fromPath('file', photo.path),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['url'] as String;
    } else {
      throw Exception('Erreur lors de l\'upload de la photo');
    }
  }

  /// Upload une photo à partir de bytes (pour le web).
  Future<String> uploadPhotoBytes(
    Uint8List bytes,
    String filename,
    String mimeType,
  ) async {
    final token = await accessToken;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/uploads/photo'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes,
          filename: filename,
          contentType: MediaType.parse(mimeType)),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['url'] as String;
    } else {
      throw Exception('Erreur lors de l\'upload de la photo');
    }
  }

  Future<Cv> duplicateCv(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/duplicate'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 201) {
      return Cv.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la duplication du CV');
    }
  }

  Future<List<String>> getAiSuggestions({
    required String poste,
    String? entreprise,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiEndpoint}/suggest'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'poste': poste,
        if (entreprise != null && entreprise.isNotEmpty) 'entreprise': entreprise,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final suggestions = data['suggestions'] as List<dynamic>;
      return suggestions.cast<String>();
    } else {
      throw Exception('Erreur lors de la génération des suggestions');
    }
  }

  Future<Cv> generateShareLink(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/share'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Cv.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Erreur lors de la génération du lien');
    }
  }

  Future<Map<String, dynamic>> enhanceCv(int cvId, String level) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiEndpoint}/enhance-cv'),
      headers: await _getHeaders(),
      body: jsonEncode({'cvId': cvId, 'level': level}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Erreur lors de l\'amélioration IA');
    }
  }

  Future<List<int>> downloadCvDocx(int id) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/docx');
    final response = await http.get(uri, headers: await _getHeaders());
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Erreur lors du telechargement DOCX');
    }
  }

  Future<String> generateResume(String? titrePoste, String? competences, String? experience) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiEndpoint}/generate-resume'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'titrePoste': titrePoste ?? '',
        'competences': competences ?? '',
        'experience': experience ?? '',
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['resume'] as String? ?? '';
    } else {
      throw Exception('Erreur lors de la generation');
    }
  }

  Future<Map<String, dynamic>> matchJob(int cvId, String jobDescription) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiEndpoint}/match-job'),
      headers: await _getHeaders(),
      body: jsonEncode({'cvId': cvId, 'jobDescription': jobDescription}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Erreur lors de l\'analyse');
    }
  }

  Future<List<int>> downloadCvPdf(int id, {String template = 'MODERNE'}) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/pdf?template=$template',
    );
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Erreur lors du téléchargement du PDF');
    }
  }
}
