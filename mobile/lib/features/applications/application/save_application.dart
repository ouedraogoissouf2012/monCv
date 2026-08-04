import '../../../core/error/result.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/application_repository.dart';
import '../domain/job_application.dart';

/// Enregistre une candidature — issue #246, A2.
///
/// Cree si l'entite n'a pas d'`id`, met a jour sinon. Regroupe la regle metier
/// "creer ou mettre a jour" a un seul endroit (le monolithe la portait dans le
/// Provider).
class SaveApplicationUseCase implements UseCase<JobApplication, JobApplication> {
  const SaveApplicationUseCase(this._repository);

  final ApplicationRepository _repository;

  @override
  Future<Result<JobApplication>> call(JobApplication application) =>
      application.id == null
          ? _repository.create(application)
          : _repository.update(application);
}
