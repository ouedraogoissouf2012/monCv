import 'dart:convert';
import 'dart:typed_data';

import 'package:http_parser/http_parser.dart';

import '../../features/cv/data/cv_network_codec.dart';
import '../../utils/constants.dart';
import '../http_timeout.dart' as http;
import 'api_errors.dart';

/// Transport HTTP du cycle de vie des CV : CRUD, duplication, variante et import
/// (issue #258, ex-#237). Extrait de `ApiService`. Le partage vit dans
/// `CvShareHttpClient`, l'export dans `CvExportHttpClient`.
class CvHttpClient {
  const CvHttpClient({required this.headers, required this.accessToken});

  final HeaderFactory headers;
  final AccessTokenProvider accessToken;

  Future<List<Cv>> getAllCvs() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}'),
      headers: await headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return [for (final e in data) cvFromNetworkJson(e as Map<String, dynamic>)];
    } else {
      throwTypedError(response);
    }
  }

  Future<Cv> getCvById(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id'),
      headers: await headers(),
    );
    if (response.statusCode == 200) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throwTypedError(response);
    }
  }

  Future<Cv> createCv(Cv cv) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}'),
      headers: await headers(),
      body: cvToNetworkBody(cv),
    );
    if (response.statusCode == 201) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throwApiError(response, 'Erreur lors de la creation du CV');
    }
  }

  Future<Cv> updateCv(int id, Cv cv) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id'),
      headers: await headers(),
      body: cvToNetworkBody(cv),
    );
    if (response.statusCode == 200) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throwApiError(response, 'Erreur lors de la mise a jour du CV');
    }
  }

  Future<void> deleteCv(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id'),
      headers: await headers(),
    );
    if (response.statusCode != 204) {
      throwTypedError(response);
    }
  }

  Future<List<Cv>> getTrashedCvs() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/trash'),
      headers: await headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return [for (final e in data) cvFromNetworkJson(e as Map<String, dynamic>)];
    }
    throwTypedError(response);
  }

  Future<Cv> restoreCv(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/trash/$id/restore'),
      headers: await headers(),
    );
    if (response.statusCode == 200) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throwTypedError(response);
  }

  Future<void> purgeCv(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/trash/$id'),
      headers: await headers(),
    );
    if (response.statusCode != 204) {
      throwTypedError(response);
    }
  }

  Future<Cv> duplicateCv(int id) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/duplicate',
      ),
      headers: await headers(),
    );
    if (response.statusCode == 201) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throwTypedError(response);
    }
  }

  Future<Cv> createVariant(
    int cvId,
    String jobDescription, {
    String? label,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$cvId/variant',
      ),
      headers: await headers(),
      body: jsonEncode({
        'jobDescription': jobDescription,
        if (label != null && label.isNotEmpty) 'label': label,
      }),
    );
    if (response.statusCode == 201) {
      return cvFromNetworkJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throwTypedError(response);
    }
  }

  Future<Cv> importCv(Uint8List bytes, String filename) async {
    final token = await accessToken();
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
      // Reponse multipart streamee : on reconstruit une Response pour la router
      // vers le mapping type commun (M-9).
      throwTypedError(http.Response(body, streamed.statusCode));
    }
  }
}
