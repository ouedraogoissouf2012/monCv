import 'package:flutter/foundation.dart';
import '../features/cv/presentation/cv_presentation_model.dart';
import '../utils/cv_pdf_generator.dart';
import '../utils/pdf_saver.dart';
import 'accent_corrector.dart';
import 'i_api_client.dart';

/// Service encapsulant la generation et le telechargement de PDF et DOCX.
/// Applique le correcteur d'accents sur tout le CV avant l'export.
class PdfService {
  PdfService(this._api);

  final IApiClient _api;
  final _corrector = AccentCorrector();

  /// Genere le PDF et le telecharge.
  /// Corrige les accents sur tout le contenu avant generation.
  Future<void> downloadPdf(Cv cv) async {
    final correctedCv = _correctAccents(cv);
    final bytes = await generate(correctedCv);
    await savePdfBytes(bytes, 'cv-${cv.id ?? 'draft'}.pdf');
  }

  /// Telecharge le DOCX depuis le backend.
  Future<void> downloadDocx(int cvId) async {
    final bytes = await _api.downloadCvDocx(cvId);
    await savePdfBytes(Uint8List.fromList(bytes), 'cv-$cvId.docx');
  }

  /// Genere le PDF en bytes.
  Future<Uint8List> generate(Cv cv) async {
    final photoBytes = await _loadPhoto(cv.personalInfo?.photoUrl);
    if (kIsWeb) {
      return generateCvPdf(cv, photoBytes: photoBytes);
    }
    return compute(_generateInIsolate, _PdfGenerationInput(cv, photoBytes));
  }

  Future<Uint8List?> _loadPhoto(String? url) async {
    try {
      return await _api.loadPhoto(url);
    } catch (_) {
      return null;
    }
  }

  /// Corrige les accents sur TOUT le CV avant export.
  Cv _correctAccents(Cv cv) {
    final info = cv.personalInfo;
    PersonalInfo? correctedInfo;
    if (info != null) {
      correctedInfo = PersonalInfo(
        nom: _corrector.correctNullable(info.nom),
        prenom: _corrector.correctNullable(info.prenom),
        email: info.email,
        telephone: info.telephone,
        adresse: _corrector.correctNullable(info.adresse),
        ville: _corrector.correctNullable(info.ville),
        codePostal: info.codePostal,
        pays: _corrector.correctNullable(info.pays),
        titrePoste: _corrector.correctNullable(info.titrePoste),
        linkedIn: info.linkedIn,
        portfolio: info.portfolio,
        photoUrl: info.photoUrl,
        resumeProfessionnel:
            _corrector.correctNullable(info.resumeProfessionnel),
      );
    }

    return cv.copyWith(
      personalInfo: correctedInfo,
      experiences: cv.experiences
          .map((e) => Experience(
                id: e.id,
                poste: _corrector.correctNullable(e.poste),
                entreprise: _corrector.correctNullable(e.entreprise),
                lieu: _corrector.correctNullable(e.lieu),
                dateDebut: e.dateDebut,
                dateFin: e.dateFin,
                actuel: e.actuel,
                description: _corrector.correctNullable(e.description),
              ))
          .toList(),
      educations: cv.educations
          .map((e) => Education(
                id: e.id,
                diplome: _corrector.correctNullable(e.diplome),
                etablissement: _corrector.correctNullable(e.etablissement),
                domaine: _corrector.correctNullable(e.domaine),
                dateDebut: e.dateDebut,
                dateFin: e.dateFin,
                description: _corrector.correctNullable(e.description),
              ))
          .toList(),
      projects: cv.projects
          .map((p) => Project(
                id: p.id,
                nom: _corrector.correctNullable(p.nom),
                description: _corrector.correctNullable(p.description),
                technologies: p.technologies,
                lien: p.lien,
                dateDebut: p.dateDebut,
                dateFin: p.dateFin,
              ))
          .toList(),
      languages: cv.languages
          .map((l) => Language(
                id: l.id,
                langue: _corrector.correctNullable(l.langue),
                niveau: l.niveau,
              ))
          .toList(),
    );
  }
}

/// Fonction top-level pour compute()
Future<Uint8List> _generateInIsolate(_PdfGenerationInput input) =>
    generateCvPdf(input.cv, photoBytes: input.photoBytes);

final class _PdfGenerationInput {
  const _PdfGenerationInput(this.cv, this.photoBytes);

  final Cv cv;
  final Uint8List? photoBytes;
}
