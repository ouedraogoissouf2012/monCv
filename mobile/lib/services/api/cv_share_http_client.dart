import 'dart:convert';

import '../../features/cv/data/cv_network_codec.dart';
import '../../utils/constants.dart';
import '../http_timeout.dart' as http;
import 'api_errors.dart';

/// Transport HTTP du partage public d'un CV : generation, regeneration,
/// desactivation du lien et reglages (issue #258, ex-#237). Extrait de
/// `ApiService`.
class CvShareHttpClient {
  const CvShareHttpClient({required this.headers});

  final HeaderFactory headers;

  Future<Cv> generateShareLink(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/share'),
      headers: await headers(),
    );
    if (response.statusCode == 200) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Erreur lors de la génération du lien');
    }
  }

  Future<Cv> regenerateShareLink(int id) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/share/regenerate',
      ),
      headers: await headers(),
    );
    if (response.statusCode == 200) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throwTypedError(response);
  }

  Future<Cv> deactivateShareLink(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/share'),
      headers: await headers(),
    );
    if (response.statusCode == 200) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throwTypedError(response);
  }

  Future<Cv> updateShareSettings(
    int id, {
    required bool contactEnabled,
    required bool downloadsEnabled,
  }) async {
    final response = await http.put(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/share/settings',
      ),
      headers: await headers(),
      body: jsonEncode({
        'contactEnabled': contactEnabled,
        'downloadsEnabled': downloadsEnabled,
      }),
    );
    if (response.statusCode == 200) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throwTypedError(response);
  }
}
