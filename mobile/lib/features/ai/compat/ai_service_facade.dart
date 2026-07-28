import '../data/ai_remote_data_source.dart';
import 'ai_legacy_map.dart';

/// Façade de compatibilité `@Deprecated` (ADR 002 : migration incrementale).
///
/// Conserve la signature de l'ancien `AiCvService` (retours `Map`) pour que les
/// widgets pas encore migres — `job_match_sheet` et `application_messages_sheet`
/// (#245) — compilent inchanges, tout en s'appuyant sur le nouveau
/// [AiRemoteDataSource] typé. Les entités de domaine sont reconverties en `Map`
/// via [toLegacyMap]. Le flux d'exceptions (`AppException`/`AiException`) que
/// ces widgets interceptent est preserve : le data source les leve toujours.
///
/// A supprimer avec #245 (une fois ces deux sheets migres vers les use cases
/// typés). Date de suppression cible : 2027-01-31.
@Deprecated(
  'Utiliser AiRepository / les use cases typés. Supprime par #245 (voir #237). '
  'Expire le 2027-01-31.',
)
class AiCvService {
  AiCvService(this._dataSource);

  final AiRemoteDataSource _dataSource;

  Future<String> generateResume({
    String? titrePoste,
    String? competences,
    String? experience,
  }) =>
      _dataSource.generateResume(titrePoste, competences, experience);

  Future<Map<String, dynamic>> enhanceCv(int cvId, String level) async =>
      (await _dataSource.enhanceCv(cvId, level)).toLegacyMap();

  Future<Map<String, dynamic>> matchJob(int cvId, String jobDescription) async =>
      (await _dataSource.matchJob(cvId, jobDescription)).toLegacyMap();

  Future<Map<String, dynamic>> generateApplicationMessages(
    int cvId,
    String jobDescription,
    String tone,
  ) async =>
      (await _dataSource.generateApplicationMessages(
        cvId,
        jobDescription,
        tone,
      ))
          .toLegacyMap();

  Future<List<String>> getSuggestions({
    required String poste,
    String? entreprise,
    String? description,
  }) =>
      _dataSource.getSuggestions(
        poste: poste,
        entreprise: entreprise,
        description: description,
      );
}
