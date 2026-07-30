import 'dart:typed_data';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/data/http_profile_photo_repository.dart';
import 'package:cv_mobile/services/i_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements IApiClient {}

class _FakeXFile extends Fake implements XFile {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeXFile());
    registerFallbackValue(Uint8List(0));
  });

  late _MockApi api;
  late HttpProfilePhotoRepository repo;

  setUp(() {
    api = _MockApi();
    repo = HttpProfilePhotoRepository(api,
        mediaBaseUrl: 'https://api.moncv.com');
  });

  test('uploadBytes : URL relative -> URL absolue (#242 D4)', () async {
    when(() => api.uploadPhotoBytes(any(), any(), any()))
        .thenAnswer((_) async => '/media/photos/42.png');

    final result = await repo.uploadBytes(
      bytes: Uint8List.fromList([1]),
      filename: '42.png',
      mimeType: 'image/png',
    );

    expect((result as Success<String>).data,
        'https://api.moncv.com/media/photos/42.png');
  });

  test('uploadFile : URL relative -> URL absolue (#242 D4)', () async {
    when(() => api.uploadPhoto(any()))
        .thenAnswer((_) async => '/media/photos/7.jpg');

    final result = await repo.uploadFile('/tmp/7.jpg');

    expect((result as Success<String>).data,
        'https://api.moncv.com/media/photos/7.jpg');
  });

  test('backend renvoie deja une URL absolue -> conservee telle quelle',
      () async {
    when(() => api.uploadPhotoBytes(any(), any(), any()))
        .thenAnswer((_) async => 'https://cdn.autre.com/p.png');

    final result = await repo.uploadBytes(
      bytes: Uint8List.fromList([1]),
      filename: 'p.png',
      mimeType: 'image/png',
    );

    expect((result as Success<String>).data, 'https://cdn.autre.com/p.png');
  });

  test('exception du transport -> Result.failure typee (#242 D4)', () async {
    when(() => api.uploadPhoto(any()))
        .thenThrow(const NetworkException());

    final result = await repo.uploadFile('/tmp/x.jpg');

    expect(result, isA<Failure<String>>());
    expect((result as Failure<String>).exception, isA<NetworkException>());
  });
}
