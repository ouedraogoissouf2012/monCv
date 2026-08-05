import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/applications/application/delete_application.dart';
import 'package:cv_mobile/features/applications/application/list_applications.dart';
import 'package:cv_mobile/features/applications/application/save_application.dart';
import 'package:cv_mobile/features/applications/domain/application_repository.dart';
import 'package:cv_mobile/features/applications/domain/job_application.dart';
import 'package:cv_mobile/features/applications/domain/job_application_status.dart';
import 'package:cv_mobile/features/applications/presentation/application_list_controller.dart';
import 'package:cv_mobile/features/applications/presentation/application_list_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ApplicationRepository {}

void main() {
  late _MockRepo repo;

  // Horloge deterministe pour les relances.
  DateTime clock() => DateTime(2026, 6, 15);

  ApplicationListController controller() => ApplicationListController(
        listApplications: ListApplicationsUseCase(repo),
        saveApplication: SaveApplicationUseCase(repo),
        deleteApplication: DeleteApplicationUseCase(repo),
        clock: clock,
      );

  const app = JobApplication(id: 1, company: 'Acme', position: 'Dev');
  final dueApp = JobApplication(
    id: 2,
    company: 'Beta',
    position: 'Dev',
    status: JobApplicationStatus.sent,
    nextFollowUp: DateTime(2026, 6, 10), // passee -> due au 15/06
  );

  setUpAll(() => registerFallbackValue(app));
  setUp(() => repo = _MockRepo());

  group('load (#246 A4)', () {
    test('succes -> items dans l etat, loading false, filtre conserve',
        () async {
      when(() => repo.list(status: JobApplicationStatus.sent))
          .thenAnswer((_) async => const Result.success([app]));
      final c = controller();

      await c.load(status: JobApplicationStatus.sent);

      expect(c.state.items, hasLength(1));
      expect(c.state.loading, isFalse);
      expect(c.state.filter, JobApplicationStatus.sent);
      expect(c.state.error, isNull);
    });

    test('echec -> erreur TYPEE exposee, pas d items', () async {
      when(() => repo.list(status: any(named: 'status')))
          .thenAnswer((_) async => const Result.failure(NetworkException()));
      final c = controller();

      await c.load();

      expect(c.state.error, isA<NetworkException>());
      expect(c.state.items, isEmpty);
      expect(c.state.loading, isFalse);
    });
  });

  group('dueItems - horloge injectee (#246 A4)', () {
    test('ne retient que les relances dues a l heure du controller', () async {
      when(() => repo.list(status: any(named: 'status')))
          .thenAnswer((_) async => Result.success([app, dueApp]));
      final c = controller();

      await c.load();

      expect(c.dueItems, hasLength(1));
      expect(c.dueItems.first.id, 2);
    });
  });

  group('save (#246 A4)', () {
    test('succes -> recharge la liste avec le filtre courant', () async {
      when(() => repo.list(status: any(named: 'status')))
          .thenAnswer((_) async => const Result.success([app]));
      when(() => repo.create(any()))
          .thenAnswer((_) async => const Result.success(app));
      final c = controller();

      final ok = await c.save(
          const JobApplication(company: 'Acme', position: 'Dev'));

      expect(ok, isTrue);
      verify(() => repo.create(any())).called(1);
      verify(() => repo.list(status: any(named: 'status'))).called(1);
    });

    test('echec -> erreur exposee, retourne false', () async {
      when(() => repo.create(any()))
          .thenAnswer((_) async => const Result.failure(ServerException()));
      final c = controller();

      final ok = await c.save(
          const JobApplication(company: 'Acme', position: 'Dev'));

      expect(ok, isFalse);
      expect(c.state.error, isA<ServerException>());
    });
  });

  group('delete (#246 A4)', () {
    test('succes -> retire l item de l etat sans rechargement reseau',
        () async {
      when(() => repo.list(status: any(named: 'status')))
          .thenAnswer((_) async => Result.success([app, dueApp]));
      when(() => repo.delete(1)).thenAnswer((_) async => const Result.success(null));
      final c = controller();
      await c.load();
      clearInteractions(repo);

      final ok = await c.delete(1);

      expect(ok, isTrue);
      expect(c.state.items.map((e) => e.id), [2]);
      verifyNever(() => repo.list(status: any(named: 'status')));
    });
  });

  group('etat immuable (#246 A4)', () {
    test('copyWith clearFilter remet le filtre a null', () {
      const s = ApplicationListState(filter: JobApplicationStatus.offer);
      expect(s.copyWith(clearFilter: true).filter, isNull);
    });
  });
}
