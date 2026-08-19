import 'dart:convert';

import '../../utils/constants.dart';
import '../http_timeout.dart' as http;
import 'api_errors.dart';

/// Transport HTTP des suggestions IA (issue #258, ex-#237). Extrait de
/// `ApiService`.
///
/// L'amelioration de CV (`enhance-cv`) et la generation de resume passent
/// desormais EXCLUSIVEMENT par le pipeline typé (`AiRemoteDataSource`), qui
/// transmet le consentement REEL de l'utilisateur. Les anciennes methodes de ce
/// client codaient `aiConsentAccepted: true` en dur (chemin mort) : elles ont
/// ete supprimees (residuel M-1).
class AiHttpClient {
  const AiHttpClient({required this.headers});

  final HeaderFactory headers;

  Future<List<String>> getAiSuggestions({
    required String poste,
    String? entreprise,
    String? description,
    required bool consentAccepted,
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
        'aiConsentAccepted': consentAccepted,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final suggestions = data['suggestions'] as List<dynamic>;
      return suggestions.cast<String>();
    }
    throwTypedError(response);
  }
}
