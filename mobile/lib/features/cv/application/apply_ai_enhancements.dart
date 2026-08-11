import '../../../models/cv.dart';
import '../../ai/domain/entities/enhanced_cv.dart';

/// Applique un resultat d'amelioration IA sur un CV et retourne le CV enrichi.
///
/// Mapping *pur* et synchrone (aucun I/O, aucun etat) : extrait de
/// `CvProvider.applyAiEnhancements` pour sortir la logique de mapping du
/// provider (issue #240). Chaque section n'est modifiee que si l'IA fournit
/// une valeur non vide ; les identifiants et champs non touches sont conserves.
///
/// Deux entrees :
/// - [call] : `Map<String, dynamic>` (voie historique, contrat transport IA) ;
/// - [fromEnhanced] : entite typee [EnhancedCv] (voie #244, sans aucun `Map`
///   en presentation). Les deux appliquent EXACTEMENT la meme regle de merge.
class ApplyAiEnhancements {
  const ApplyAiEnhancements();

  /// Retourne une copie de [cv] enrichie par le resultat typé [enhanced]
  /// (issue #244). Meme semantique que [call] : chaque champ n'est remplace que
  /// si l'IA fournit une valeur non vide ; IDs et champs non touches conserves.
  Cv fromEnhanced(Cv cv, EnhancedCv enhanced) {
    final info = cv.personalInfo;
    return cv.copyWith(
      personalInfo: info == null
          ? null
          : (_has(enhanced.titrePoste) || _has(enhanced.resumeProfessionnel))
              ? PersonalInfo(
                  nom: info.nom,
                  prenom: info.prenom,
                  email: info.email,
                  telephone: info.telephone,
                  adresse: info.adresse,
                  ville: info.ville,
                  codePostal: info.codePostal,
                  pays: info.pays,
                  titrePoste:
                      _has(enhanced.titrePoste) ? enhanced.titrePoste : info.titrePoste,
                  linkedIn: info.linkedIn,
                  portfolio: info.portfolio,
                  photoUrl: info.photoUrl,
                  resumeProfessionnel: _has(enhanced.resumeProfessionnel)
                      ? enhanced.resumeProfessionnel
                      : info.resumeProfessionnel,
                )
              : info,
      experiences: _zipMerge(cv.experiences, enhanced.experiences, (old, e) {
        if (!_has(e.poste) && !_has(e.description)) return old;
        return Experience(
          id: old.id,
          poste: _has(e.poste) ? e.poste! : old.poste,
          entreprise: old.entreprise,
          lieu: old.lieu,
          dateDebut: old.dateDebut,
          dateFin: old.dateFin,
          actuel: old.actuel,
          description: _has(e.description) ? e.description! : old.description,
        );
      }),
      educations: _zipMerge(cv.educations, enhanced.educations, (old, e) {
        if (!_has(e.etablissement) &&
            !_has(e.diplome) &&
            !_has(e.domaine) &&
            !_has(e.description)) {
          return old;
        }
        return Education(
          id: old.id,
          etablissement:
              _has(e.etablissement) ? e.etablissement! : old.etablissement,
          diplome: _has(e.diplome) ? e.diplome! : old.diplome,
          domaine: _has(e.domaine) ? e.domaine! : old.domaine,
          dateDebut: old.dateDebut,
          dateFin: old.dateFin,
          description: _has(e.description) ? e.description! : old.description,
        );
      }),
      skills: _zipMerge(cv.skills, enhanced.skills, (old, s) {
        if (!_has(s.nom) && s.niveau == null) return old;
        return Skill(
          id: old.id,
          nom: _has(s.nom) ? s.nom : old.nom,
          niveau: s.niveau ?? old.niveau,
          categorie: old.categorie,
        );
      }),
      languages: _zipMerge(cv.languages, enhanced.languages, (old, e) {
        if (!_has(e.langue)) return old;
        return Language(id: old.id, langue: e.langue!, niveau: old.niveau);
      }),
      certifications:
          _zipMerge(cv.certifications, enhanced.certifications, (old, e) {
        if (!_has(e.nom) && !_has(e.organisme)) return old;
        return Certification(
          id: old.id,
          nom: _has(e.nom) ? e.nom! : old.nom,
          organisme: _has(e.organisme) ? e.organisme! : old.organisme,
          dateObtention: old.dateObtention,
          dateExpiration: old.dateExpiration,
          credentialUrl: old.credentialUrl,
        );
      }),
      projects: _zipMerge(cv.projects, enhanced.projects, (old, e) {
        if (!_has(e.nom) && !_has(e.description) && !_has(e.technologies)) {
          return old;
        }
        return Project(
          id: old.id,
          nom: _has(e.nom) ? e.nom! : old.nom,
          description: _has(e.description) ? e.description! : old.description,
          technologies:
              _has(e.technologies) ? e.technologies! : old.technologies,
          lien: old.lien,
          dateDebut: old.dateDebut,
          dateFin: old.dateFin,
        );
      }),
    );
  }

  /// Fusionne deux listes par index jusqu'au plus court ; les elements
  /// au-dela de la liste amelioree restent inchanges (borne sure, aucun ID
  /// perdu).
  static List<O> _zipMerge<O, E>(
      List<O> originals, List<E> enhanced, O Function(O old, E e) merge) {
    final updated = List<O>.of(originals);
    final n = originals.length < enhanced.length
        ? originals.length
        : enhanced.length;
    for (var i = 0; i < n; i++) {
      updated[i] = merge(originals[i], enhanced[i]);
    }
    return updated;
  }

  /// Retourne une copie de [cv] enrichie par [result].
  Cv call(Cv cv, Map<String, dynamic> result) {
    return cv.copyWith(
      personalInfo: _mergePersonalInfo(cv.personalInfo, result),
      experiences: _mergeExperiences(cv.experiences, result['experiences']),
      educations: _mergeEducations(cv.educations, result['educations']),
      skills: _mergeSkills(cv.skills, result['skills']),
      languages: _mergeLanguages(cv.languages, result['languages']),
      certifications:
          _mergeCertifications(cv.certifications, result['certifications']),
      projects: _mergeProjects(cv.projects, result['projects']),
    );
  }

  static bool _has(String? v) => v != null && v.isNotEmpty;

  PersonalInfo? _mergePersonalInfo(
      PersonalInfo? info, Map<String, dynamic> result) {
    if (info == null) return null;
    final newTitre = result['titrePoste'] as String?;
    final newResume = result['resumeProfessionnel'] as String?;
    if (!_has(newTitre) && !_has(newResume)) return info;
    return PersonalInfo(
      nom: info.nom,
      prenom: info.prenom,
      email: info.email,
      telephone: info.telephone,
      adresse: info.adresse,
      ville: info.ville,
      codePostal: info.codePostal,
      pays: info.pays,
      titrePoste: _has(newTitre) ? newTitre : info.titrePoste,
      linkedIn: info.linkedIn,
      portfolio: info.portfolio,
      photoUrl: info.photoUrl,
      resumeProfessionnel:
          _has(newResume) ? newResume : info.resumeProfessionnel,
    );
  }

  List<Experience> _mergeExperiences(List<Experience> current, dynamic raw) {
    final updated = List<Experience>.from(current);
    if (raw is! List) return updated;
    for (var i = 0; i < raw.length && i < updated.length; i++) {
      final newPoste = raw[i]['poste'] as String?;
      final newDesc = raw[i]['description'] as String?;
      if (!_has(newPoste) && !_has(newDesc)) continue;
      final old = updated[i];
      updated[i] = Experience(
        id: old.id,
        poste: _has(newPoste) ? newPoste! : old.poste,
        entreprise: old.entreprise,
        lieu: old.lieu,
        dateDebut: old.dateDebut,
        dateFin: old.dateFin,
        actuel: old.actuel,
        description: _has(newDesc) ? newDesc! : old.description,
      );
    }
    return updated;
  }

  List<Education> _mergeEducations(List<Education> current, dynamic raw) {
    final updated = List<Education>.from(current);
    if (raw is! List) return updated;
    for (var i = 0; i < raw.length && i < updated.length; i++) {
      final etab = raw[i]['etablissement'] as String?;
      final diplome = raw[i]['diplome'] as String?;
      final domaine = raw[i]['domaine'] as String?;
      final desc = raw[i]['description'] as String?;
      if (!_has(etab) && !_has(diplome) && !_has(domaine) && !_has(desc)) {
        continue;
      }
      final old = updated[i];
      updated[i] = Education(
        id: old.id,
        etablissement: _has(etab) ? etab! : old.etablissement,
        diplome: _has(diplome) ? diplome! : old.diplome,
        domaine: _has(domaine) ? domaine! : old.domaine,
        dateDebut: old.dateDebut,
        dateFin: old.dateFin,
        description: _has(desc) ? desc! : old.description,
      );
    }
    return updated;
  }

  List<Skill> _mergeSkills(List<Skill> current, dynamic raw) {
    final updated = List<Skill>.from(current);
    if (raw is! List) return updated;
    for (var i = 0; i < raw.length && i < updated.length; i++) {
      final nom = raw[i]['nom'] as String?;
      final niveau = raw[i]['niveau'] as int?;
      if (!_has(nom) && niveau == null) continue;
      final old = updated[i];
      updated[i] = Skill(
        id: old.id,
        nom: _has(nom) ? nom : old.nom,
        niveau: niveau ?? old.niveau,
        categorie: old.categorie,
      );
    }
    return updated;
  }

  List<Language> _mergeLanguages(List<Language> current, dynamic raw) {
    final updated = List<Language>.from(current);
    if (raw is! List) return updated;
    for (var i = 0; i < raw.length && i < updated.length; i++) {
      final newName = raw[i]['langue'] as String?;
      if (!_has(newName)) continue;
      final old = updated[i];
      updated[i] = Language(id: old.id, langue: newName!, niveau: old.niveau);
    }
    return updated;
  }

  List<Certification> _mergeCertifications(
      List<Certification> current, dynamic raw) {
    final updated = List<Certification>.from(current);
    if (raw is! List) return updated;
    for (var i = 0; i < raw.length && i < updated.length; i++) {
      final newName = raw[i]['nom'] as String?;
      final newOrg = raw[i]['organisme'] as String?;
      if (!_has(newName) && !_has(newOrg)) continue;
      final old = updated[i];
      updated[i] = Certification(
        id: old.id,
        nom: _has(newName) ? newName! : old.nom,
        organisme: _has(newOrg) ? newOrg! : old.organisme,
        dateObtention: old.dateObtention,
        dateExpiration: old.dateExpiration,
        credentialUrl: old.credentialUrl,
      );
    }
    return updated;
  }

  List<Project> _mergeProjects(List<Project> current, dynamic raw) {
    final updated = List<Project>.from(current);
    if (raw is! List) return updated;
    for (var i = 0; i < raw.length && i < updated.length; i++) {
      final newName = raw[i]['nom'] as String?;
      final newDesc = raw[i]['description'] as String?;
      final newTech = raw[i]['technologies'] as String?;
      if (!_has(newName) && !_has(newDesc) && !_has(newTech)) continue;
      final old = updated[i];
      updated[i] = Project(
        id: old.id,
        nom: _has(newName) ? newName! : old.nom,
        description: _has(newDesc) ? newDesc! : old.description,
        technologies: _has(newTech) ? newTech! : old.technologies,
        lien: old.lien,
        dateDebut: old.dateDebut,
        dateFin: old.dateFin,
      );
    }
    return updated;
  }
}
