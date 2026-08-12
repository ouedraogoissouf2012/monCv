import '../../../features/cv/presentation/cv_presentation_model.dart';
import '../../ai/domain/entities/enhanced_cv.dart';
import '../domain/enhancement_change.dart';

/// Construit le diff avant/apres entre un CV et sa version amelioree par l'IA
/// (issue #244).
///
/// Use case PUR : Dart pur, aucune dependance Flutter/i18n/transport. Compare
/// toutes les sections champ par champ ; ne retient un [EnhancementChange] que
/// si la valeur amelioree est non vide ET differente de l'originale (un champ
/// inchange ou vide cote IA est ignore). Gere les listes de tailles
/// differentes en s'arretant au plus court (aucun acces hors bornes, aucun ID
/// perdu : l'[index] identifie l'element compare).
class BuildEnhancementDiff {
  const BuildEnhancementDiff();

  List<EnhancementChange> call(Cv original, EnhancedCv enhanced) {
    final changes = <EnhancementChange>[];

    void add(EnhancementField field, String? before, String? after,
        {int index = 0}) {
      final b = before ?? '';
      final a = after ?? '';
      if (a.isNotEmpty && a != b) {
        changes.add(EnhancementChange(
            field: field, before: b, after: a, index: index));
      }
    }

    final info = original.personalInfo;
    add(EnhancementField.jobTitle, info?.titrePoste, enhanced.titrePoste);
    add(EnhancementField.professionalSummary, info?.resumeProfessionnel,
        enhanced.resumeProfessionnel);

    _zip(original.experiences, enhanced.experiences, (i, o, e) {
      add(EnhancementField.experiencePoste, o.poste, e.poste, index: i);
      add(EnhancementField.experienceDescription, o.description, e.description,
          index: i);
    });

    _zip(original.educations, enhanced.educations, (i, o, e) {
      add(EnhancementField.educationEtablissement, o.etablissement,
          e.etablissement,
          index: i);
      add(EnhancementField.educationDiplome, o.diplome, e.diplome, index: i);
      add(EnhancementField.educationDomaine, o.domaine, e.domaine, index: i);
      add(EnhancementField.educationDescription, o.description, e.description,
          index: i);
    });

    _zip(original.skills, enhanced.skills, (i, o, e) {
      add(EnhancementField.skill, o.nom, e.nom, index: i);
    });

    _zip(original.languages, enhanced.languages, (i, o, e) {
      add(EnhancementField.language, o.langue, e.langue, index: i);
    });

    _zip(original.certifications, enhanced.certifications, (i, o, e) {
      add(EnhancementField.certificationNom, o.nom, e.nom, index: i);
      add(EnhancementField.certificationOrganisme, o.organisme, e.organisme,
          index: i);
    });

    _zip(original.projects, enhanced.projects, (i, o, e) {
      add(EnhancementField.projectNom, o.nom, e.nom, index: i);
      add(EnhancementField.projectTechnologies, o.technologies, e.technologies,
          index: i);
      add(EnhancementField.projectDescription, o.description, e.description,
          index: i);
    });

    return changes;
  }

  /// Parcourt deux listes en parallele jusqu'au plus court (borne sure).
  static void _zip<O, E>(
    List<O> originals,
    List<E> enhanced,
    void Function(int index, O original, E enhanced) body,
  ) {
    final n = originals.length < enhanced.length
        ? originals.length
        : enhanced.length;
    for (var i = 0; i < n; i++) {
      body(i, originals[i], enhanced[i]);
    }
  }
}
