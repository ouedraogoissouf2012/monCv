import '../../domain/value_objects/cv_style_ref.dart';
import '../mappers/json_codec_helpers.dart';

/// (De)serialise le style d'un CV entre JSON et le value object pur
/// [CvStyleRef]. La couleur primaire circule en entier ARGB, jamais en `Color`.
///
/// Format historique preserve : `{templateId, primaryColor(int ARGB),
/// fontFamily}`. Les valeurs manquantes retombent sur le style par defaut.
final class CvStyleDto {
  const CvStyleDto();

  CvStyleRef fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return CvStyleRef.fallback;
    return CvStyleRef(
      templateId: asString(raw['templateId']) ?? CvStyleRef.fallback.templateId,
      fontFamily: asString(raw['fontFamily']) ?? CvStyleRef.fallback.fontFamily,
      primaryColorArgb:
          asInt(raw['primaryColor']) ?? CvStyleRef.fallback.primaryColorArgb,
    );
  }

  Map<String, dynamic> toJson(CvStyleRef style) => {
        'templateId': style.templateId,
        'primaryColor': style.primaryColorArgb,
        'fontFamily': style.fontFamily,
      };
}
