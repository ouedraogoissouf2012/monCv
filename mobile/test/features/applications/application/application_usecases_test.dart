import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/applications/application/delete_application.dart';
import 'package:cv_mobile/features/applications/application/list_applications.dart';
import 'package:cv_mobile/features/applications/application/save_application.dart';
import 'package:cv_mobile/features/applications/data/application_remote_data_source.dart';
import 'package:cv_mobile/features/applications/data/application_repository_impl.dart';
import 'package:cv_mobile/features/applications/domain/job_application.dart';
import 'package:cv_mobile/features/applications/domain/job_application_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements ApplicationRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late ApplicationRepositoryImpl repo;

  const app = JobApplication(company: 'Acme', position: 'Dev');
  final saved = app.copyWith(id: 7);

  setUpAll(() => registerFallbackValue(app));

  setUp(() {
    remote = _MockRemote();
    repo = ApplicationRepositoryImpl(remote);
  });

  group('repository -> Result (#246 A2)', () {
    test('succes de list -> Result.success', () async {
      when(() => remote.list(status: any(named: 'status')))
          .thenAnswer((_) async => [saved]);

      final r = await repo.list();

      expect(r, isA<Success<List<JobApplication>>>());
      expect((r as Success).data, hasLength(1));
    });

    test('exception du data source -> Result.failure (pas de throw)', () async {
      when(() => remote.list(status: any(named: 'status')))
          .thenThrow(const NetworkException());

      final r = await repo.list();

      expect(r, isA<Failure<List<JobApplication>>>());
      expect((r as Failure).exception, isA<NetworkException>());
    });
  });

  group('ListApplicationsUseCase (#246 A2)', () {
    test('propage le filtre de statut au repository', () async {
      when(() => remote.list(status: JobApplicationStatus.sent))
          .thenAnswer((_) async => const []);

      await ListApplicationsUseCase(repo)
          .call(const ListApplicationsParams(status: JobApplicationStatus.sent));

      verify(() => remote.list(status: JobApplicationStatus.sent)).called(1);
    });
  });

  group('SaveApplicationUseCase (#246 A2)', () {
    test('sans id -> create', () async {
      when(() => remote.create(any())).thenAnswer((_) async => saved);

      final r = await SaveApplicationUseCase(repo).call(app);

      expect((r as Success).data.id, 7);
      verify(() => remote.create(any())).called(1);
      verifyNever(() => remote.update(any()));
    });

    test('avec id -> update', () async {
      when(() => remote.update(any())).thenAnswer((_) async => saved);

      await SaveApplicationUseCase(repo).call(saved);

      verify(() => remote.update(any())).called(1);
      verifyNever(() => remote.create(any()));
    });
  });

  group('DeleteApplicationUseCase (#246 A2)', () {
    test('delegue la suppression par id', () async {
      when(() => remote.delete(7)).thenAnswer((_) async {});

      final r = await DeleteApplicationUseCase(repo).call(7);

      expect(r, isA<Success<void>>());
      verify(() => remote.delete(7)).called(1);
    });
  });
}
