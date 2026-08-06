import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../features/cv/data/cv_network_codec.dart' show Cv;
import '../models/job_application.dart';
import '../models/notification_preferences.dart';
import '../models/user.dart';
import 'api/ai_http_client.dart';
import 'api/auth_http_client.dart';
import 'api/cv_export_http_client.dart';
import 'api/cv_http_client.dart';
import 'api/cv_share_http_client.dart';
import 'api/job_application_http_client.dart';
import 'api/notification_http_client.dart';
import 'api/photo_http_client.dart';
import 'api/user_http_client.dart';
import 'google_auth_http_client.dart';
import 'http_timeout.dart' as http;
import 'i_api_client.dart';
import 'public_portfolio_api_client.dart';
import 'token_storage.dart';

/// Facade du client API : gere les jetons d'authentification et delegue chaque
/// domaine metier a un client HTTP dedie sous `services/api/` (issue #258, ex-#237).
///
/// Le contrat [IApiClient] reste stable pour tous les appelants ; seul le
/// transport a ete decompose (auth -> [AuthHttpClient], CV -> [CvHttpClient],
/// partage -> [CvShareHttpClient], etc.). L'authentification Google et le
/// portfolio public conservent leurs clients historiques
/// ([GoogleAuthHttpClient], [PublicPortfolioApiClient]).
class ApiService implements IApiClient {
  ApiService({TokenStorage? storage, http.Client? client})
      : _storage = storage ?? TokenStorage(),
        _publicPortfolioApi = PublicPortfolioApiClient(client ?? http.Client());

  final TokenStorage _storage;
  final PublicPortfolioApiClient _publicPortfolioApi;
  String? _accessToken;

  // ── Clients HTTP par feature (sans etat propre : ne portent que des rappels
  //    vers la gestion de jetons de cette facade). Construits une seule fois. ──
  late final AuthHttpClient _auth =
      AuthHttpClient(headers: _getHeaders, storeTokens: setTokens);
  late final UserHttpClient _user =
      UserHttpClient(headers: _getHeaders, clearTokens: clearTokens);
  late final NotificationHttpClient _notifications =
      NotificationHttpClient(headers: _getHeaders);
  late final JobApplicationHttpClient _jobApplications =
      JobApplicationHttpClient(headers: _getHeaders);
  late final CvHttpClient _cv =
      CvHttpClient(headers: _getHeaders, accessToken: () => accessToken);
  late final CvShareHttpClient _cvShare =
      CvShareHttpClient(headers: _getHeaders);
  late final CvExportHttpClient _cvExport =
      CvExportHttpClient(headers: _getHeaders);
  late final AiHttpClient _ai = AiHttpClient(headers: _getHeaders);
  late final PhotoHttpClient _photo =
      PhotoHttpClient(accessToken: () => accessToken);

  // ── Gestion des jetons ────────────────────────────────────────
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

  // ── Authentification ──────────────────────────────────────────
  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? nom,
    String? prenom,
  }) =>
      _auth.register(
        email: email,
        password: password,
        nom: nom,
        prenom: prenom,
      );

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) =>
      _auth.login(email: email, password: password);

  @override
  Future<AuthResponse> loginWithGoogle(String credential) => GoogleAuthHttpClient(
        headers: _getHeaders,
        storeTokens: setTokens,
      ).request('/google', credential, withAuth: false);

  @override
  Future<AuthResponse> linkGoogle(String credential) => GoogleAuthHttpClient(
        headers: _getHeaders,
        storeTokens: setTokens,
      ).request('/google/link', credential, withAuth: true);

  @override
  Future<void> logout() async {
    await clearTokens();
  }

  // ── Notifications ─────────────────────────────────────────────
  @override
  Future<void> registerDeviceToken(String token, String platform) =>
      _notifications.registerDeviceToken(token, platform);

  @override
  Future<void> unregisterDeviceToken(String token) =>
      _notifications.unregisterDeviceToken(token);

  @override
  Future<NotificationPreferences> getNotificationPreferences() =>
      _notifications.getNotificationPreferences();

  @override
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences value,
  ) =>
      _notifications.updateNotificationPreferences(value);

  // ── Candidatures ──────────────────────────────────────────────
  @override
  Future<List<JobApplication>> getJobApplications({
    JobApplicationStatus? status,
    DateTime? from,
    DateTime? to,
  }) =>
      _jobApplications.getJobApplications(status: status, from: from, to: to);

  @override
  Future<JobApplication> createJobApplication(JobApplication value) =>
      _jobApplications.createJobApplication(value);

  @override
  Future<JobApplication> updateJobApplication(JobApplication value) =>
      _jobApplications.updateJobApplication(value);

  @override
  Future<void> deleteJobApplication(int id) =>
      _jobApplications.deleteJobApplication(id);

  // ── Profil utilisateur ────────────────────────────────────────
  @override
  Future<User> getCurrentUser() => _user.getCurrentUser();

  @override
  Future<User> updateProfile({String? nom, String? prenom}) =>
      _user.updateProfile(nom: nom, prenom: prenom);

  @override
  Future<Map<String, dynamic>> exportUserData() => _user.exportUserData();

  @override
  Future<void> deleteAccount() => _user.deleteAccount();

  // ── CV : CRUD, duplication, variante, import ──────────────────
  @override
  Future<List<Cv>> getAllCvs() => _cv.getAllCvs();

  @override
  Future<Cv> getCvById(int id) => _cv.getCvById(id);

  @override
  Future<Cv> createCv(Cv cv) => _cv.createCv(cv);

  @override
  Future<Cv> updateCv(int id, Cv cv) => _cv.updateCv(id, cv);

  @override
  Future<void> deleteCv(int id) => _cv.deleteCv(id);

  @override
  Future<Cv> duplicateCv(int id) => _cv.duplicateCv(id);

  @override
  Future<Cv> createVariant(int cvId, String jobDescription, {String? label}) =>
      _cv.createVariant(cvId, jobDescription, label: label);

  @override
  Future<Cv> importCv(Uint8List bytes, String filename) =>
      _cv.importCv(bytes, filename);

  // ── CV : partage public ───────────────────────────────────────
  @override
  Future<Cv> generateShareLink(int id) => _cvShare.generateShareLink(id);

  @override
  Future<Cv> regenerateShareLink(int id) => _cvShare.regenerateShareLink(id);

  @override
  Future<Cv> deactivateShareLink(int id) => _cvShare.deactivateShareLink(id);

  @override
  Future<Cv> updateShareSettings(
    int id, {
    required bool contactEnabled,
    required bool downloadsEnabled,
  }) =>
      _cvShare.updateShareSettings(
        id,
        contactEnabled: contactEnabled,
        downloadsEnabled: downloadsEnabled,
      );

  // ── CV : export ───────────────────────────────────────────────
  @override
  Future<List<int>> downloadCvDocx(int id) => _cvExport.downloadCvDocx(id);

  @override
  Future<List<int>> downloadCvPdf(int id, {String template = 'MODERNE'}) =>
      _cvExport.downloadCvPdf(id, template: template);

  // ── IA ────────────────────────────────────────────────────────
  @override
  Future<List<String>> getAiSuggestions({
    required String poste,
    String? entreprise,
    String? description,
  }) =>
      _ai.getAiSuggestions(
        poste: poste,
        entreprise: entreprise,
        description: description,
      );

  @override
  Future<Map<String, dynamic>> enhanceCv(int cvId, String level) =>
      _ai.enhanceCv(cvId, level);

  @override
  Future<String> generateResume(
    String? titrePoste,
    String? competences,
    String? experience,
  ) =>
      _ai.generateResume(titrePoste, competences, experience);

  // ── Photos ────────────────────────────────────────────────────
  @override
  Future<String> uploadPhoto(XFile photo) => _photo.uploadPhoto(photo);

  @override
  Future<String> uploadPhotoBytes(
    Uint8List bytes,
    String filename,
    String mimeType,
  ) =>
      _photo.uploadPhotoBytes(bytes, filename, mimeType);

  @override
  Future<Uint8List?> loadPhoto(String? url) async =>
      _publicPortfolioApi.loadPhoto(url, await accessToken);

  // ── Portfolio public ──────────────────────────────────────────
  @override
  Future<Cv> getPublicCv(String token) =>
      _publicPortfolioApi.getPortfolio(token);

  @override
  Future<List<int>> downloadPublicCv(String token, String format) =>
      _publicPortfolioApi.download(token, format);

  @override
  Future<void> trackPublicShare(String token) =>
      _publicPortfolioApi.trackShare(token);
}
