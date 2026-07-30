import 'dart:typed_data';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv/application/upload_profile_photo_usecase.dart';
import 'package:cv_mobile/features/cv/domain/repositories/profile_photo_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ProfilePhotoRepository {}

void main() {
  setUpAll(() => registerFallbackValue(Uint8List(0)));

  late _MockRepo repo;
  late UploadProfilePhotoUseCase useCase;

  setUp(() {
    repo = _MockRepo();
    useCase = UploadProfilePhotoUseCase(repo);
  });

  test('PhotoBytesSource -> route vers uploadBytes (#242 D4)', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    when(() => repo.uploadBytes(
          bytes: any(named: 'bytes'),
          filename: any(named: 'filename'),
          mimeType: any(named: 'mimeType'),
        )).thenAnswer((_) async => const Result.success('https://x/p.png'));

    final result = await useCase(PhotoBytesSource(
      bytes: bytes,
      filename: 'p.png',
      mimeType: 'image/png',
    ));

    expect(result, isA<Success<String>>());
    expect((result as Success<String>).data, 'https://x/p.png');
    verify(() => repo.uploadBytes(
        bytes: bytes, filename: 'p.png', mimeType: 'image/png')).called(1);
    verifyNever(() => repo.uploadFile(any()));
  });

  test('PhotoFileSource -> route vers uploadFile (#242 D4)', () async {
    when(() => repo.uploadFile(any()))
        .thenAnswer((_) async => const Result.success('https://x/f.jpg'));

    final result = await useCase(const PhotoFileSource('/tmp/f.jpg'));

    expect((result as Success<String>).data, 'https://x/f.jpg');
    verify(() => repo.uploadFile('/tmp/f.jpg')).called(1);
    verifyNever(() => repo.uploadBytes(
        bytes: any(named: 'bytes'),
        filename: any(named: 'filename'),
        mimeType: any(named: 'mimeType')));
  });

  test('echec du repo -> Result.failure propage (#242 D4)', () async {
    when(() => repo.uploadFile(any()))
        .thenAnswer((_) async => const Result.failure(NetworkException()));

    final result = await useCase(const PhotoFileSource('/tmp/f.jpg'));

    expect(result, isA<Failure<String>>());
    expect((result as Failure<String>).exception, isA<NetworkException>());
  });
}
