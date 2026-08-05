import 'dart:typed_data';

/// Erreur de validation d'un fichier d'import CV (issue #249, D1). Neutre : la
/// presentation mappe chaque cas vers un message localise.
enum CvImportError {
  /// Extension non autorisee (attendu : pdf ou docx).
  invalidExtension,

  /// Contenu incoherent avec un PDF/DOCX (magic bytes) — protege contre un
  /// fichier renomme.
  invalidContent,

  /// Fichier vide.
  empty,

  /// Fichier trop volumineux (> [CvImportPolicy.maxBytes]).
  tooLarge,
}

/// Validation PURE d'un fichier d'import CV (issue #249, D1).
///
/// Verifie extension, signature de contenu (magic bytes) et taille — le
/// monolithe importait sans aucun controle (home_screen.dart:212-230).
abstract final class CvImportPolicy {
  static const Set<String> allowedExtensions = {'pdf', 'docx'};

  /// Taille maximale acceptee (10 Mio).
  static const int maxBytes = 10 * 1024 * 1024;

  /// Valide [filename] + [bytes]. Retourne `null` si le fichier est acceptable,
  /// sinon le premier [CvImportError] rencontre.
  static CvImportError? validate(String filename, Uint8List bytes) {
    final ext = _extension(filename);
    if (!allowedExtensions.contains(ext)) return CvImportError.invalidExtension;
    if (bytes.isEmpty) return CvImportError.empty;
    if (bytes.length > maxBytes) return CvImportError.tooLarge;
    if (!_contentMatches(ext, bytes)) return CvImportError.invalidContent;
    return null;
  }

  static String _extension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot < 0 || dot == filename.length - 1) return '';
    return filename.substring(dot + 1).toLowerCase();
  }

  /// Verifie la signature binaire : PDF commence par `%PDF`, DOCX (zip) par
  /// `PK`.
  static bool _contentMatches(String ext, Uint8List b) {
    if (b.length < 4) return false;
    return switch (ext) {
      // %PDF -> 0x25 0x50 0x44 0x46
      'pdf' => b[0] == 0x25 && b[1] == 0x50 && b[2] == 0x44 && b[3] == 0x46,
      // PK\x03\x04 -> archive zip (docx)
      'docx' => b[0] == 0x50 && b[1] == 0x4B,
      _ => false,
    };
  }
}
