/// Facade de compatibilite (issue #238).
///
/// Le modele monolithique historique `Cv` a ete decompose en une architecture
/// par couche :
/// - entites de domaine pures : `features/cv/domain/entities/`
/// - value objects : `features/cv/domain/value_objects/`
/// - politique de completion : `features/cv/domain/policies/`
/// - (de)serialisation JSON : `features/cv/data/` (`CvMapper`)
/// - modele de presentation `Cv` : `features/cv/presentation/`
///
/// Ce fichier ne fait plus que re-exporter ces symboles afin que les ecrans et
/// widgets non encore migres continuent de compiler. Il sera supprime une fois
/// la migration des consommateurs terminee.
///
/// Nouveau code : dependez de `CvEntity` (domaine) et de `CvMapper` (data),
/// pas de ce modele de presentation.
@Deprecated(
  'Migrer vers CvEntity (features/cv/domain) et CvMapper (features/cv/data). '
  'Ce modele de presentation sera supprime a la fin de #238.',
)
library;

export '../features/cv/domain/entities/certification.dart';
export '../features/cv/domain/entities/cv.dart';
export '../features/cv/domain/entities/education.dart';
export '../features/cv/domain/entities/experience.dart';
export '../features/cv/domain/entities/language.dart';
export '../features/cv/domain/entities/personal_info.dart';
export '../features/cv/domain/entities/project.dart';
export '../features/cv/domain/entities/skill.dart';
export '../features/cv/presentation/cv_presentation_model.dart';
