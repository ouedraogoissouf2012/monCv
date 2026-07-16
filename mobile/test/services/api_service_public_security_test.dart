import 'package:cv_mobile/services/api_service.dart';
import 'package:cv_mobile/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const token = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  test('encode le chemin public et exige une reponse JSON', () async {
    late http.Request captured;
    final api = ApiService(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          '{"titre":"CV public","personalInfo":'
          '{"photoUrl":"/api/cvs/public/$token/photo"}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final cv = await api.getPublicCv(token);

    expect(cv.titre, 'CV public');
    expect(
      cv.personalInfo?.photoUrl,
      '${ApiConstants.baseUrl}/cvs/public/$token/photo',
    );
    expect(captured.url.path, '/api/cvs/public/$token');
    expect(captured.headers['Accept'], 'application/json');
  });

  test('rejette jeton et format avant tout appel reseau', () async {
    var calls = 0;
    final api = ApiService(
      client: MockClient((_) async {
        calls++;
        return http.Response('', 500);
      }),
    );

    await expectLater(api.getPublicCv('../admin'), throwsFormatException);
    await expectLater(
      api.downloadPublicCv(token, 'exe'),
      throwsFormatException,
    );
    expect(calls, 0);
  });

  test('le suivi de partage utilise un POST JSON non simple', () async {
    late http.Request captured;
    final api = ApiService(
      client: MockClient((request) async {
        captured = request;
        return http.Response('', 204);
      }),
    );

    await api.trackPublicShare(token);

    expect(captured.method, 'POST');
    expect(captured.headers['Content-Type'], 'application/json');
    expect(captured.body, '{}');
    expect(captured.url.path, '/api/cvs/public/$token/share');
  });
}
