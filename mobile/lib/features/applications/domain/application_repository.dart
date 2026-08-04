import '../../../core/error/result.dart';
import 'job_application.dart';
import 'job_application_status.dart';

/// Port d'acces aux candidatures (issue #246).
///
/// Abstraction du domaine : aucune dependance au transport. L'implementation
/// (data source typee) vit dans `data/`. Toutes les operations renvoient un
/// [Result] : les exceptions systeme sont converties en [AppException] typees,
/// jamais propagees brutes.
abstract interface class ApplicationRepository {
  /// Liste les candidatures, filtrees par [status] si fourni.
  Future<Result<List<JobApplication>>> list({JobApplicationStatus? status});

  /// Cree une candidature et renvoie l'entite persistee.
  Future<Result<JobApplication>> create(JobApplication application);

  /// Met a jour une candidature existante.
  Future<Result<JobApplication>> update(JobApplication application);

  /// Supprime la candidature [id].
  Future<Result<void>> delete(int id);
}
