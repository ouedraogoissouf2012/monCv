import '../../../features/cv/presentation/cv_presentation_model.dart';

/// Une competence unitaire prete a afficher : un nom + un niveau borne
/// (issue #243). Les competences saisies "Java, Python; Go" sont eclatees en
/// entrees distinctes par [CvDocumentViewModel.skills].
class SkillView {
  const SkillView(this.name, this.level);

  final String name;
  final int level;

  @override
  bool operator ==(Object other) =>
      other is SkillView && other.name == name && other.level == level;

  @override
  int get hashCode => Object.hash(name, level);

  @override
  String toString() => 'SkillView($name, $level)';
}

/// Vue purement metier d'un CV pour le rendu document (preview ET, a terme,
/// PDF) — issue #243.
///
/// Ne depend NI de Material NI du package pdf : uniquement du modele [Cv] et de
/// dart:core. Prepare le formatage des dates, l'eclatement des competences et
/// la liste des sections reellement visibles, pour que les templates n'aient
/// plus a reimplementer cette logique (aujourd'hui dupliquee dans le
/// monolithe `cv_preview.dart`).
class CvDocumentViewModel {
  const CvDocumentViewModel(this.cv);

  final Cv cv;

  static const int _defaultSkillLevel = 3;

  /// Competences eclatees (une entree par nom). Reproduit a l'identique le
  /// comportement du monolithe : niveau par defaut [_defaultSkillLevel] si
  /// absent, aucune borne appliquee (l'affichage des barres borne cote
  /// template). Iso-comportement pour la parite (#243).
  List<SkillView> get skills => splitSkills(cv.skills);

  /// Eclate une liste de [Skill] "Java, Python; Go" en [SkillView] unitaires.
  /// Expose en statique pour etre utilisable sans instancier le view model.
  static List<SkillView> splitSkills(List<Skill> skills) {
    final result = <SkillView>[];
    for (final skill in skills) {
      final level = skill.niveau ?? _defaultSkillLevel;
      for (final part in (skill.nom ?? '').split(RegExp(r'[,;]+'))) {
        final name = part.trim();
        if (name.isNotEmpty) result.add(SkillView(name, level));
      }
    }
    return result;
  }

  /// Formate une date en `MM/aaaa`, ou chaine vide si absente.
  static String formatMonthYear(DateTime? date) {
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    return '$month/${date.year}';
  }

  /// Plage de dates `MM/aaaa - MM/aaaa`. Si [actuel] (ou fin absente et debut
  /// present), remplace la fin par [ongoingLabel]. Collapse les cas degeneres
  /// (meme mois, meme annee, une seule borne).
  static String formatDateRange(
    DateTime? debut,
    DateTime? fin, {
    required String ongoingLabel,
    bool actuel = false,
  }) {
    final start = formatMonthYear(debut);
    if (actuel || (fin == null && debut != null)) {
      return start.isEmpty ? ongoingLabel : '$start - $ongoingLabel';
    }
    final end = formatMonthYear(fin);
    if (start.isEmpty && end.isEmpty) return '';
    if (end.isEmpty) return start;
    if (start == end) return start;
    if (debut?.year == fin?.year) return '${debut!.year}';
    return '$start - $end';
  }

  // ── Sections visibles ──────────────────────────────────────────
  // Une section n'est rendue que si elle a du contenu : evite les titres
  // orphelins dans le document.

  bool get hasSummary =>
      (cv.personalInfo?.resumeProfessionnel ?? '').trim().isNotEmpty;
  bool get hasSkills => skills.isNotEmpty;
  bool get hasLanguages => cv.languages.isNotEmpty;
  bool get hasExperiences => cv.experiences.isNotEmpty;
  bool get hasEducations => cv.educations.isNotEmpty;
  bool get hasCertifications => cv.certifications.isNotEmpty;
  bool get hasProjects => cv.projects.isNotEmpty;
}
