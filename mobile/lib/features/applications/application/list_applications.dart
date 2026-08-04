import '../../../core/error/result.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/application_repository.dart';
import '../domain/job_application.dart';
import '../domain/job_application_status.dart';

class ListApplicationsParams {
  final JobApplicationStatus? status;
  const ListApplicationsParams({this.status});
}

/// Liste les candidatures (filtrees par statut si fourni) — issue #246, A2.
class ListApplicationsUseCase
    implements UseCase<List<JobApplication>, ListApplicationsParams> {
  const ListApplicationsUseCase(this._repository);

  final ApplicationRepository _repository;

  @override
  Future<Result<List<JobApplication>>> call(ListApplicationsParams params) =>
      _repository.list(status: params.status);
}
