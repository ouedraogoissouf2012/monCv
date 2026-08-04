import '../../../core/error/result.dart';
import '../../../core/error/safe_call.dart';
import '../domain/application_repository.dart';
import '../domain/job_application.dart';
import '../domain/job_application_status.dart';
import 'application_remote_data_source.dart';

/// Implementation du port [ApplicationRepository] (issue #246, A2).
///
/// Delegue au [ApplicationRemoteDataSource] et enveloppe chaque appel dans
/// [safeCall] : toute [AppException] levee par le transport devient un
/// `Result.failure` typé — jamais d'exception brute ni de `toString()`.
class ApplicationRepositoryImpl implements ApplicationRepository {
  ApplicationRepositoryImpl(this._remote);

  final ApplicationRemoteDataSource _remote;

  @override
  Future<Result<List<JobApplication>>> list({JobApplicationStatus? status}) =>
      safeCall(() => _remote.list(status: status));

  @override
  Future<Result<JobApplication>> create(JobApplication application) =>
      safeCall(() => _remote.create(application));

  @override
  Future<Result<JobApplication>> update(JobApplication application) =>
      safeCall(() => _remote.update(application));

  @override
  Future<Result<void>> delete(int id) => safeCall(() => _remote.delete(id));
}
