import 'dart:typed_data';

import 'package:cv_mobile/features/media/data/http_secure_photo_repository.dart';
import 'package:cv_mobile/services/i_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements IApiClient {}

void main() {
  late _MockApiClient api;
  late HttpSecurePhotoRepository repo;

  setUp(() {
    api = _MockApiClient();
    repo = HttpSecurePhotoRepository(api);
  });

  test('load délègue à IApiClient.loadPhoto et retourne les octets', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    when(() => api.loadPhoto('/photo.png')).thenAnswer((_) async => bytes);

    final result = await repo.load('/photo.png');

    expect(result, bytes);
    verify(() => api.loadPhoto('/photo.png')).called(1);
  });

  test('load retourne null quand l\'image est indisponible', () async {
    when(() => api.loadPhoto('/missing.png')).thenAnswer((_) async => null);

    final result = await repo.load('/missing.png');

    expect(result, isNull);
  });
}
