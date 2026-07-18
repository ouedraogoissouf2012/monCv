import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../models/ai_status.dart';
import '../models/cv.dart';
import '../models/job_application.dart';
import '../models/notification_preferences.dart';
import '../models/user.dart';

abstract interface class IApiClient {
  Future<String?> get accessToken;
  Future<void> setTokens(String accessToken, String refreshToken);
  Future<void> clearTokens();
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? nom,
    String? prenom,
  });
  Future<AuthResponse> login({required String email, required String password});
  Future<AuthResponse> loginWithGoogle(String credential);
  Future<AuthResponse> linkGoogle(String credential);
  Future<void> logout();
  Future<void> registerDeviceToken(String token, String platform);
  Future<void> unregisterDeviceToken(String token);
  Future<NotificationPreferences> getNotificationPreferences();
  Future<NotificationPreferences> updateNotificationPreferences(
    NotificationPreferences value,
  );
  Future<List<JobApplication>> getJobApplications({
    JobApplicationStatus? status,
    DateTime? from,
    DateTime? to,
  });
  Future<JobApplication> createJobApplication(JobApplication value);
  Future<JobApplication> updateJobApplication(JobApplication value);
  Future<void> deleteJobApplication(int id);
  Future<User> getCurrentUser();
  Future<User> updateProfile({String? nom, String? prenom});
  Future<Map<String, dynamic>> exportUserData();
  Future<void> deleteAccount();
  Future<List<Cv>> getAllCvs();
  Future<Cv> getCvById(int id);
  Future<Cv> createCv(Cv cv);
  Future<Cv> updateCv(int id, Cv cv);
  Future<void> deleteCv(int id);
  Future<String> uploadPhoto(XFile photo);
  Future<String> uploadPhotoBytes(
    Uint8List bytes,
    String filename,
    String mimeType,
  );
  Future<Uint8List?> loadPhoto(String? url);
  Future<Cv> duplicateCv(int id);
  Future<Cv> createVariant(
    int cvId,
    String jobDescription, {
    String? label,
  });
  Future<List<String>> getAiSuggestions({
    required String poste,
    String? entreprise,
    String? description,
  });
  Future<Cv> generateShareLink(int id);
  Future<Cv> regenerateShareLink(int id);
  Future<Cv> deactivateShareLink(int id);
  Future<Cv> updateShareSettings(
    int id, {
    required bool contactEnabled,
    required bool downloadsEnabled,
  });
  Future<Cv> getPublicCv(String token);
  Future<List<int>> downloadPublicCv(String token, String format);
  Future<void> trackPublicShare(String token);
  Future<Map<String, dynamic>> enhanceCv(int cvId, String level);
  Future<List<int>> downloadCvDocx(int id);
  Future<String> generateResume(
    String? titrePoste,
    String? competences,
    String? experience,
  );
  Future<Map<String, dynamic>> matchJob(int cvId, String jobDescription);
  Future<Map<String, dynamic>> generateApplicationMessages(
    int cvId,
    String jobDescription,
    String tone,
  );
  Future<AiStatus> getAiStatus();
  Future<List<int>> downloadCvPdf(int id, {String template = 'MODERNE'});
  Future<Cv> importCv(Uint8List bytes, String filename);
}
