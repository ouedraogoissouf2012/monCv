import '../domain/entities/application_messages.dart';
import '../domain/entities/enhanced_cv.dart';
import '../domain/entities/job_match.dart';

/// Reconvertit les entités de domaine IA en `Map<String, dynamic>` a la forme du
/// payload backend, pour les widgets pas encore migres (#244/#245) qui lisent
/// encore des Map. Transitoire : disparait avec la facade @Deprecated.
extension EnhancedCvLegacyMap on EnhancedCv {
  Map<String, dynamic> toLegacyMap() => {
        'titrePoste': titrePoste,
        'resumeProfessionnel': resumeProfessionnel,
        'titreOffre': titreOffre,
        'experiences': experiences
            .map((e) => {
                  'id': e.id,
                  'poste': e.poste,
                  'description': e.description,
                })
            .toList(),
        'educations': educations
            .map((e) => {
                  'id': e.id,
                  'etablissement': e.etablissement,
                  'diplome': e.diplome,
                  'domaine': e.domaine,
                  'description': e.description,
                })
            .toList(),
        'skills':
            skills.map((e) => {'nom': e.nom, 'niveau': e.niveau}).toList(),
        'languages':
            languages.map((e) => {'id': e.id, 'langue': e.langue}).toList(),
        'certifications': certifications
            .map((e) => {'id': e.id, 'nom': e.nom, 'organisme': e.organisme})
            .toList(),
        'projects': projects
            .map((e) => {
                  'id': e.id,
                  'nom': e.nom,
                  'description': e.description,
                  'technologies': e.technologies,
                })
            .toList(),
        'warnings': warnings,
        'correctionCount': correctionCount,
        'aiGenerated': aiGenerated,
        'fallback': fallback,
        'level': level,
      };
}

extension JobMatchLegacyMap on JobMatch {
  Map<String, dynamic> toLegacyMap() => {
        'score': score,
        'matchedKeywords': matchedKeywords,
        'missingKeywords': missingKeywords,
        'suggestions': suggestions,
        'categories': categories
            .map((c) => {
                  'key': c.key,
                  'label': c.label,
                  'score': c.score,
                  'summary': c.summary,
                  'evidence': c.evidence,
                })
            .toList(),
        'prioritizedRecommendations': prioritizedRecommendations
            .map((r) => {
                  'priority': r.priority,
                  'title': r.title,
                  'description': r.description,
                  'keywords': r.keywords,
                })
            .toList(),
        'formatChecks': formatChecks
            .map((f) => {
                  'severity': f.severity,
                  'label': f.label,
                  'detail': f.detail,
                })
            .toList(),
        'optimizedResume': optimizedResume,
        'aiGenerated': aiGenerated,
        'fallback': fallback,
      };
}

extension ApplicationMessagesLegacyMap on ApplicationMessages {
  Map<String, dynamic> toLegacyMap() => {
        'coverLetter': coverLetter,
        'email': email,
        'linkedIn': linkedIn,
        'whatsApp': whatsApp,
        'tone': tone,
        'aiGenerated': aiGenerated,
        'fallback': fallback,
      };
}
