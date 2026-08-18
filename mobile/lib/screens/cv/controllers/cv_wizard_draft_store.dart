import 'dart:typed_data';

import '../../../features/cv/presentation/cv_presentation_model.dart';

/// Conserve le brouillon du wizard « Nouveau CV » si l'utilisateur quitte
/// l'ecran avant de sauvegarder (photo comprise).
class CvWizardDraftStore {
  Cv? cv;
  int step = 0;
  Uint8List? photoBytes;

  bool get hasDraft => cv != null;

  void save({required Cv cv, required int step, Uint8List? photoBytes}) {
    this.cv = cv;
    this.step = step;
    this.photoBytes = photoBytes;
  }

  void clear() {
    cv = null;
    step = 0;
    photoBytes = null;
  }
}
