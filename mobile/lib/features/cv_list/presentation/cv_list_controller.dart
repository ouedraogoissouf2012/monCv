import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../application/import_cv.dart';

/// Issue d'une action de la liste (import/suppression/duplication) exposee a la
/// vue (issue #249, D4).
enum CvListActionOutcome { success, invalidInput, failure }

/// Selectionne un fichier a importer (delegue au picker cote vue). `null` si
/// l'utilisateur annule.
typedef PickImportFile = Future<CvImportFile?> Function();

/// Orchestration des actions de la liste des CV (issue #249, D4).
///
/// Delegue import (via [ImportCvUseCase], D1), suppression et duplication a des
/// fonctions injectees (CvProvider). Expose un resultat TYPE distinguant
/// validation locale et echec — le monolithe faisait ces appels directement
/// dans l'ecran avec `e.toString()`.
class CvListController extends ChangeNotifier {
  CvListController({
    required ImportCvUseCase importCv,
    required PickImportFile pickFile,
    required Future<bool> Function() reload,
    required Future<bool> Function(int id) deleteCv,
    required Future<bool> Function(int id) duplicateCv,
  })  : _importCv = importCv,
        _pickFile = pickFile,
        _reload = reload,
        _delete = deleteCv,
        _duplicate = duplicateCv;

  final ImportCvUseCase _importCv;
  final PickImportFile _pickFile;
  final Future<bool> Function() _reload;
  final Future<bool> Function(int id) _delete;
  final Future<bool> Function(int id) _duplicate;

  bool _importing = false;
  bool get importing => _importing;

  /// Derniere erreur d'import (code de validation ou message backend), ou null.
  String? importError;

  /// Titre du dernier CV importe avec succes (pour le message de confirmation).
  String? importedTitle;

  /// Selectionne un fichier, le VALIDE (extension/MIME/taille) et l'importe.
  /// Retourne `invalidInput` si le fichier est refuse localement (aucun envoi),
  /// `success` si importe (la liste est rechargee), `failure` sinon. `null` si
  /// l'utilisateur annule la selection.
  Future<CvListActionOutcome?> importFromFile() async {
    if (_importing) return null;
    final file = await _pickFile();
    if (file == null) return null;

    _importing = true;
    importError = null;
    importedTitle = null;
    notifyListeners();

    final result = await _importCv.call(file);
    _importing = false;

    switch (result) {
      case Success(:final data):
        importedTitle = data.titre;
        await _reload();
        notifyListeners();
        return CvListActionOutcome.success;
      case Failure(:final exception):
        importError = exception.code ?? exception.message;
        notifyListeners();
        return exception is ValidationException
            ? CvListActionOutcome.invalidInput
            : CvListActionOutcome.failure;
    }
  }

  /// Supprime un CV. Retourne `true` si succes.
  Future<bool> deleteCv(int id) => _delete(id);

  /// Duplique un CV. Retourne `true` si succes.
  Future<bool> duplicateCv(int id) => _duplicate(id);
}
