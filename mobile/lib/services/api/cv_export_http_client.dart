import '../../utils/constants.dart';
import '../http_timeout.dart' as http;
import 'api_errors.dart';

/// Transport HTTP du telechargement d'un CV (DOCX / PDF) (issue #258, ex-#237).
/// Extrait de `ApiService`.
class CvExportHttpClient {
  const CvExportHttpClient({required this.headers});

  final HeaderFactory headers;

  Future<List<int>> downloadCvDocx(int id) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/docx',
    );
    final response = await http.get(uri, headers: await headers());
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throwTypedError(response);
    }
  }

  Future<List<int>> downloadCvPdf(int id, {String template = 'MODERNE'}) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.cvsEndpoint}/$id/pdf?template=$template',
    );
    final response = await http.get(uri, headers: await headers());
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throwTypedError(response);
    }
  }
}
