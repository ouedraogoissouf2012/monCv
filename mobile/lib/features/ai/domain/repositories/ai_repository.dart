import '../../../../core/error/result.dart';
import '../../../../models/ai_status.dart';
import '../entities/application_messages.dart';
import '../entities/enhanced_cv.dart';
import '../entities/job_match.dart';

/// Port de domaine du sous-systeme IA.
///
/// Les use cases dependent de ce contrat, jamais du transport ni d'un data
/// source concret (regle de frontiere ADR 002). Chaque methode renvoie un
/// [Result] : la couche `data` est le seul endroit ou une exception peut etre
/// levee, elle y est convertie en [Result.failure].
abstract interface class AiRepository {
  /// Ameliore un CV complet (niveaux LITE / MEDIUM / MAX).
  Future<Result<EnhancedCv>> enhanceCv(int cvId, String level);

  /// Analyse la correspondance entre un CV et une offre d'emploi.
  Future<Result<JobMatch>> matchJob(int cvId, String jobDescription);

  /// Genere les textes de candidature adaptes au CV et a l'offre.
  Future<Result<ApplicationMessages>> generateApplicationMessages(
    int cvId,
    String jobDescription,
    String tone,
  );

  /// Genere un resume professionnel a partir de champs libres.
  Future<Result<String>> generateResume(
    String? titrePoste,
    String? competences,
    String? experience,
  );

  /// Genere des suggestions de bullet points pour une experience.
  Future<Result<List<String>>> getSuggestions({
    required String poste,
    String? entreprise,
    String? description,
  });

  /// Etat courant du sous-systeme IA.
  Future<Result<AiStatus>> getStatus();
}
