import 'dart:convert';

import '../../utils/constants.dart';
import '../http_timeout.dart' as http;
import 'api_errors.dart';

/// Transport HTTP des fonctions IA : suggestions, amelioration de CV et
/// generation de resume (issue #258, ex-#237). Extrait de `ApiService`.
class AiHttpClient {
  const AiHttpClient({required this.headers});

  final HeaderFactory headers;

  Future<List<String>> getAiSuggestions({
    required String poste,
    String? entreprise,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiEndpoint}/suggest'),
      headers: await headers(),
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
    throwTypedError(response);
  }

  Future<Map<String, dynamic>> enhanceCv(int cvId, String level) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.aiEndpoint}/enhance-cv'),
      headers: await headers(),
      body: jsonEncode({
        'cvId': cvId,
        'level': level,
        'aiConsentAccepted': true,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throwTypedError(response);
  }

  Future<String> generateResume(
    String? titrePoste,
    String? competences,
    String? experience,
  ) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.aiEndpoint}/generate-resume',
      ),
      headers: await headers(),
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
    throwTypedError(response);
  }
}
