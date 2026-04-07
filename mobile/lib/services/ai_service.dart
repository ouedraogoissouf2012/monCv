import 'api_service.dart';

/// Service centralisant tous les appels IA.
/// Evite que les screens appellent ApiService directement.
class AiCvService {
  static final AiCvService _instance = AiCvService._();
  AiCvService._();
  factory AiCvService() => _instance;

  final _api = ApiService();

  /// Genere un resume professionnel.
  Future<String> generateResume({
    String? titrePoste,
    String? competences,
    String? experience,
  }) => _api.generateResume(titrePoste, competences, experience);

  /// Ameliore un CV complet (LITE / MEDIUM / MAX).
  Future<Map<String, dynamic>> enhanceCv(int cvId, String level) =>
      _api.enhanceCv(cvId, level);

  /// Analyse la correspondance CV / offre d'emploi.
  Future<Map<String, dynamic>> matchJob(int cvId, String jobDescription) =>
      _api.matchJob(cvId, jobDescription);

  /// Genere des suggestions de bullet points pour une experience.
  Future<List<String>> getSuggestions({
    required String poste,
    String? entreprise,
  }) => _api.getAiSuggestions(poste: poste, entreprise: entreprise);
}
