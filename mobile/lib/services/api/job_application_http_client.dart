import 'dart:convert';

import '../../models/job_application.dart';
import '../../utils/constants.dart';
import '../http_timeout.dart' as http;
import 'api_errors.dart';

/// Transport HTTP des candidatures (issue #258, ex-#237). Extrait de `ApiService`.
class JobApplicationHttpClient {
  const JobApplicationHttpClient({required this.headers});

  final HeaderFactory headers;

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
    final response = await http.get(uri, headers: await headers());
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((item) => JobApplication.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throwTypedError(response);
  }

  Future<JobApplication> createJobApplication(JobApplication value) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/applications'),
      headers: await headers(),
      body: jsonEncode(value.toJson()),
    );
    if (response.statusCode == 201) {
      return JobApplication.fromJson(jsonDecode(response.body));
    }
    throwTypedError(response);
  }

  Future<JobApplication> updateJobApplication(JobApplication value) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/applications/${value.id}'),
      headers: await headers(),
      body: jsonEncode(value.toJson()),
    );
    if (response.statusCode == 200) {
      return JobApplication.fromJson(jsonDecode(response.body));
    }
    throwTypedError(response);
  }

  Future<void> deleteJobApplication(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/applications/$id'),
      headers: await headers(),
    );
    if (response.statusCode != 204) {
      throwTypedError(response);
    }
  }
}
