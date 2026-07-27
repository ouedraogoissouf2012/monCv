import 'dart:convert';
import 'dart:typed_data';
import 'http_timeout.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../core/error/error_mapper.dart';
import '../features/cv/data/cv_network_codec.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import '../models/notification_preferences.dart';
import '../models/job_application.dart';
import 'token_storage.dart';
import 'i_api_client.dart';
import 'public_portfolio_api_client.dart';
import 'google_auth_http_client.dart';

class ApiService implements IApiClient {
  ApiService({TokenStorage? storage, http.Client? client})
      : _storage = storage ?? TokenStorage(),
        _publicPortfolioApi = PublicPortfolioApiClient(client ?? http.Client());
  final TokenStorage _storage;
  final PublicPortfolioApiClient _publicPortfolioApi;
  String? _accessToken;
  Never _throwTypedError(http.Response response, String fallbackMessage) {
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // Body non-JSON : on passe null au mapper
    }
    throw ErrorMapper.fromHttpResponse(response.statusCode, body);
  }
  @override
  Future<String?> get accessToken async {
    _accessToken ??= await _storage.read('access_token');
    return _accessToken;
  }
  @override
  Future<void> setTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    await _storage.write('access_token', accessToken);
    await _storage.write('refresh_token', refreshToken);
  }
  @override
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

  @override
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
  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.authEndpoint}/login'),
      headers: await _getHeaders(withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
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
  @override
  Future<AuthResponse> loginWithGoogle(String credential) => GoogleAuthHttpClient(
        headers: _getHeaders, storeTokens: setTokens,
      ).request('/google', credential, withAuth: false);
  @override
  Future<AuthResponse> linkGoogle(String credential) => GoogleAuthHttpClient(
        headers: _getHeaders, storeTokens: setTokens,
      ).request('/google/link', credential, withAuth: true);
  @override
  Future<void> logout() async {
    await clearTokens();
  }
  @override
  Future<void> registerDeviceToken(String token, String platform) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/notifications/devices'),
      headers: await _getHeaders(),
      body: jsonEncode({'token': token, 'platform': platform}),
    );
    if (response.statusCode != 204) {
      _throwTypedError(response, 'Impossible d\'enregistrer cet appareil');
    }
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    final request = http.Request(
      'DELETE',
      Uri.parse('${ApiConstants.baseUrl}/notifications/devices'),
    )
      ..headers.addAll(await _getHeaders())
      ..body = jsonEncode({'token': token});
    final response = await http.Response.fromStream(
        await request.send().timeout(http.requestTimeout));
    if (response.statusCode != 204) {
      _throwTypedError(response, 'Impossible de retirer cet appareil');
    }
  }

  @override
  Future<NotificationPreferences> getNotificationPreferences() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/notifications/preferences'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return NotificationPreferences.fromJson(jsonDecode(response.body));
    }
    _throwTypedError(response, 'Impossible de charger les preferences');
  }

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences value,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/notifications/preferences'),
      headers: await _getHeaders(),
      body: jsonEncode(value.toJson()),
    );
    if (response.statusCode == 200) {
      return NotificationPreferences.fromJson(jsonDecode(response.body));
    }
    _throwTypedError(response, 'Impossible d\'enregistrer les preferences');
  }

  @override
  Future<List<JobApplication>> getJobApplications({
    JobApplicationStatus? status,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, String>{
      if (status != null) 'status': status.apiValue,
      if (from != null) 'from': JobApplication.formatDate(from)!,
      if (to != null) 'to': JobApplication.formatDate(to)!,
    };
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/applications',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await http.get(uri, headers: await _getHeaders());
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((item) => JobApplication.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    _throwTypedError(response, 'Impossible de charger les candidatures');
  }

  @override
  Future<JobApplication> createJobApplication(JobApplication value) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/applications'),
      headers: await _getHeaders(),
      body: jsonEncode(value.toJson()),
    );
    if (response.statusCode == 201) {
      return JobApplication.fromJson(jsonDecode(response.body));
    }
    _throwTypedError(response, 'Impossible de creer la candidature');
  }

  @override
  Future<JobApplication> updateJobApplication(JobApplication value) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/applications/${value.id}'),
      headers: await _getHeaders(),
      body: jsonEncode(value.toJson()),
    );
    if (response.statusCode == 200) {
      return JobApplication.fromJson(jsonDecode(response.body));
    }
    _throwTypedError(response, 'Impossible de modifier la candidature');
  }

  @override
  Future<void> deleteJobApplication(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/applications/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 204) {
      _throwTypedError(response, 'Impossible de supprimer la candidature');
    }
  }

  @override
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

  @override
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

  @override
  Future<Map<String, dynamic>> exportUserData() async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.usersEndpoint}/me/export',
      ),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Erreur lors de l\'export des donnees');
    }
  }

  @override
  Future<void> deleteAccount() async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.usersEndpoint}/me'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 204) {
      await clearTokens();
      return;
    }
    throw Exception('Erreur lors de la suppression du compte');
  }

  @override
  Future<List<Cv>> getAllCvs() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return [for (final e in data) cvFromNetworkJson(e as Map<String, dynamic>)];
    } else {
      throw Exception('Erreur lors de la recuperation des CV');
    }
  }

  @override
  Future<Cv> getCvById(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('CV non trouve');
    }
  }

  @override
  Future<Cv> createCv(Cv cv) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}'),
      headers: await _getHeaders(),
      body: cvToNetworkBody(cv),
    );

    if (response.statusCode == 201) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      _throwApiError(response, 'Erreur lors de la creation du CV');
    }
  }

  @override
  Future<Cv> updateCv(int id, Cv cv) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id'),
      headers: await _getHeaders(),
      body: cvToNetworkBody(cv),
    );

    if (response.statusCode == 200) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      _throwApiError(response, 'Erreur lors de la mise a jour du CV');
    }
  }

  Never _throwApiError(http.Response response, String fallbackMessage) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = Map<String, dynamic>.from(decoded);
        body['status'] ??= response.statusCode;
        body['message'] ??= fallbackMessage;
      }
    } catch (_) {
      // Retombe sur un message simple si le corps n'est pas du JSON valide.
    }

    if (body != null) throw Exception(jsonEncode(body));
    throw Exception(fallbackMessage);
  }

  @override
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
  @override
  Future<String> uploadPhoto(XFile photo) async {
    final token = await accessToken;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/uploads/photo'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath('file', photo.path));

    final streamed = await request.send().timeout(http.requestTimeout);
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['url'] as String;
    } else {
      throw Exception('Erreur lors de l\'upload de la photo');
    }
  }

  /// Upload une photo à partir de bytes (pour le web).
  @override
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
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamed = await request.send().timeout(http.requestTimeout);
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['url'] as String;
    } else {
      throw Exception('Erreur lors de l\'upload de la photo');
    }
  }

  @override
  Future<Uint8List?> loadPhoto(String? url) async =>
      _publicPortfolioApi.loadPhoto(url, await accessToken);

  @override
  Future<Cv> duplicateCv(int id) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/duplicate',
      ),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 201) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Erreur lors de la duplication du CV');
    }
  }

  @override
  Future<Cv> createVariant(
    int cvId,
    String jobDescription, {
    String? label,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$cvId/variant',
      ),
      headers: await _getHeaders(),
      body: jsonEncode({
        'jobDescription': jobDescription,
        if (label != null && label.isNotEmpty) 'label': label,
      }),
    );

    if (response.statusCode == 201) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(
        error['message'] ?? 'Erreur lors de la creation de la variante',
      );
    }
  }

  @override
  Future<List<String>> getAiSuggestions({
    required String poste,
    String? entreprise,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiEndpoint}/suggest'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'poste': poste,
        if (entreprise != null && entreprise.isNotEmpty)
          'entreprise': entreprise,
        if (description != null && description.isNotEmpty)
          'description': description,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final suggestions = data['suggestions'] as List<dynamic>;
      return suggestions.cast<String>();
    }
    _throwTypedError(response, 'Erreur lors de la generation des suggestions');
  }

  @override
  Future<Cv> generateShareLink(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/share'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Erreur lors de la génération du lien');
    }
  }

  @override
  Future<Cv> regenerateShareLink(int id) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/share/regenerate',
      ),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    _throwTypedError(response, 'Erreur lors de la regeneration du lien');
  }

  @override
  Future<Cv> deactivateShareLink(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/share'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    _throwTypedError(response, 'Erreur lors de la desactivation du lien');
  }

  @override
  Future<Cv> updateShareSettings(
    int id, {
    required bool contactEnabled,
    required bool downloadsEnabled,
  }) async {
    final response = await http.put(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/share/settings',
      ),
      headers: await _getHeaders(),
      body: jsonEncode({
        'contactEnabled': contactEnabled,
        'downloadsEnabled': downloadsEnabled,
      }),
    );
    if (response.statusCode == 200) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    _throwTypedError(response, 'Erreur lors de la configuration du partage');
  }

  @override
  Future<Cv> getPublicCv(String token) =>
      _publicPortfolioApi.getPortfolio(token);

  @override
  Future<List<int>> downloadPublicCv(String token, String format) =>
      _publicPortfolioApi.download(token, format);

  @override
  Future<void> trackPublicShare(String token) =>
      _publicPortfolioApi.trackShare(token);

  @override
  Future<Map<String, dynamic>> enhanceCv(int cvId, String level) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiEndpoint}/enhance-cv'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'cvId': cvId,
        'level': level,
        'aiConsentAccepted': true,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    _throwTypedError(response, 'Erreur lors de l\'amelioration IA');
  }

  @override
  Future<List<int>> downloadCvDocx(int id) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/docx',
    );
    final response = await http.get(uri, headers: await _getHeaders());
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Erreur lors du telechargement DOCX');
    }
  }

  @override
  Future<String> generateResume(
    String? titrePoste,
    String? competences,
    String? experience,
  ) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.aiEndpoint}/generate-resume',
      ),
      headers: await _getHeaders(),
      body: jsonEncode({
        'titrePoste': titrePoste ?? '',
        'competences': competences ?? '',
        'experience': experience ?? '',
        'aiConsentAccepted': true,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['resume'] as String? ?? '';
    }
    _throwTypedError(response, 'Erreur lors de la generation');
  }

  @override
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

  @override
  Future<Cv> importCv(Uint8List bytes, String filename) async {
    final token = await accessToken;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/import'),
    );
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    final lower = filename.toLowerCase();
    final contentType = lower.endsWith('.pdf')
        ? MediaType('application', 'pdf')
        : MediaType(
            'application',
            'vnd.openxmlformats-officedocument.wordprocessingml.document',
          );
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: contentType,
      ),
    );

    final streamed = await request.send().timeout(http.requestTimeout);
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 201) {
      return cvFromNetworkJson(jsonDecode(body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(body);
      throw Exception(error['message'] ?? 'Erreur lors de l\'import du CV');
    }
  }
}
