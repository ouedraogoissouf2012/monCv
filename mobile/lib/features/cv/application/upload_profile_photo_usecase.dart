import 'dart:typed_data';

import '../../../core/error/result.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/repositories/profile_photo_repository.dart';

/// Source d'une photo de profil a uploader (issue #242).
///
/// Sealed : web fournit des octets ([PhotoBytesSource]), mobile un chemin de
/// fichier ([PhotoFileSource]). Le use case n'a pas a connaitre la plateforme.
sealed class PhotoUploadSource {
  const PhotoUploadSource();
}

/// Octets en memoire (web) + metadonnees necessaires au transport.
class PhotoBytesSource extends PhotoUploadSource {
  const PhotoBytesSource({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
}

/// Chemin d'un fichier sur disque (mobile).
class PhotoFileSource extends PhotoUploadSource {
  const PhotoFileSource(this.path);

  final String path;
}

/// Uploade la photo de profil via le port [ProfilePhotoRepository] et retourne
/// l'URL absolue. Sort l'appel transport de la presentation (critere #242).
class UploadProfilePhotoUseCase
    implements UseCase<String, PhotoUploadSource> {
  const UploadProfilePhotoUseCase(this._repository);

  final ProfilePhotoRepository _repository;

  @override
  Future<Result<String>> call(PhotoUploadSource params) => switch (params) {
        PhotoBytesSource(:final bytes, :final filename, :final mimeType) =>
          _repository.uploadBytes(
            bytes: bytes,
            filename: filename,
            mimeType: mimeType,
          ),
        PhotoFileSource(:final path) => _repository.uploadFile(path),
      };
}
