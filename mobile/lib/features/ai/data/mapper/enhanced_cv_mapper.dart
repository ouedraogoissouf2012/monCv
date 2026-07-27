import '../../domain/entities/enhanced_cv.dart';
import '../dto/enhanced_cv_dto.dart';

/// Convertit le DTO `EnhanceCvResponse` en entité de domaine [EnhancedCv].
/// Pur, sans I/O ni JSON : c'est la frontiere data -> domaine.
abstract final class EnhancedCvMapper {
  static EnhancedCv fromDto(EnhancedCvDto dto) => EnhancedCv(
        titrePoste: dto.titrePoste,
        resumeProfessionnel: dto.resumeProfessionnel,
        titreOffre: dto.titreOffre,
        experiences: dto.experiences
            .map((e) => EnhancedExperience(
                  id: e.id,
                  poste: e.poste,
                  description: e.description,
                ))
            .toList(growable: false),
        educations: dto.educations
            .map((e) => EnhancedEducation(
                  id: e.id,
                  etablissement: e.etablissement,
                  diplome: e.diplome,
                  domaine: e.domaine,
                  description: e.description,
                ))
            .toList(growable: false),
        skills: dto.skills
            .map((e) => EnhancedSkill(nom: e.nom, niveau: e.niveau))
            .toList(growable: false),
        languages: dto.languages
            .map((e) => EnhancedLanguage(id: e.id, langue: e.langue))
            .toList(growable: false),
        certifications: dto.certifications
            .map((e) => EnhancedCertification(
                  id: e.id,
                  nom: e.nom,
                  organisme: e.organisme,
                ))
            .toList(growable: false),
        projects: dto.projects
            .map((e) => EnhancedProject(
                  id: e.id,
                  nom: e.nom,
                  description: e.description,
                  technologies: e.technologies,
                ))
            .toList(growable: false),
        warnings: dto.warnings,
        correctionCount: dto.correctionCount,
        aiGenerated: dto.aiGenerated,
        fallback: dto.fallback,
        level: dto.level,
      );
}
