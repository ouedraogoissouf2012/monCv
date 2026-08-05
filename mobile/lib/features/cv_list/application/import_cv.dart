import 'dart:typed_data';

import '../../../core/error/result.dart';
import '../../../core/error/safe_call.dart';
import '../../../models/cv.dart';
import '../domain/cv_import_policy.dart';

/// Fichier a importer (octets + nom d'origine).
class CvImportFile {
  final String filename;
  final Uint8List bytes;
  const CvImportFile({required this.filename, required this.bytes});
}

/// Port d'import : envoie le fichier et retourne le CV cree.
typedef ImportCvGateway = Future<Cv> Function(Uint8List bytes, String filename);

/// Importe un CV depuis un fichier PDF/DOCX (issue #249, D1).
///
/// Valide d'abord LOCALEMENT (extension, magic bytes, taille) via
/// [CvImportPolicy] : en cas d'echec, retourne une [ValidationException] typee
/// SANS appel reseau (le monolithe importait sans controle et convertissait les
/// erreurs avec `e.toString()`). Sinon delegue au [ImportCvGateway] et enveloppe
/// dans un [Result].
class ImportCvUseCase {
  const ImportCvUseCase(this._gateway);

  final ImportCvGateway _gateway;

  Future<Result<Cv>> call(CvImportFile file) {
    final error = CvImportPolicy.validate(file.filename, file.bytes);
    if (error != null) {
      return Future.value(
          Result.failure(ValidationException(message: error.name, code: error.name)));
    }
    return safeCall(() => _gateway(file.bytes, file.filename));
  }
}
