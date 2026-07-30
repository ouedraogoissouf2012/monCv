import 'dart:typed_data';

import '../../../../core/error/result.dart';

/// Port de domaine pour l'upload de la photo de profil (issue #242).
///
/// Les use cases et la presentation dependent de ce contrat, jamais du
/// transport (regle de frontiere ADR 002, coherent avec [AiRepository]). La
/// couche `data` est le seul endroit ou une exception peut etre levee : elle y
/// est convertie en [Result.failure]. L'implementation retourne une URL
/// ABSOLUE, prete a etre affichee (la concatenation base-url n'est plus la
/// responsabilite de la presentation).
abstract interface class ProfilePhotoRepository {
  /// Upload d'octets (web : pas de fichier sur disque). Retourne l'URL absolue
  /// de la photo, ou un [Result.failure] type en cas d'echec.
  Future<Result<String>> uploadBytes({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  });

  /// Upload d'un fichier depuis un chemin (mobile). Retourne l'URL absolue.
  Future<Result<String>> uploadFile(String path);
}
