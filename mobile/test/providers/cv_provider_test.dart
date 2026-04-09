import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/core/usecase/usecase.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/providers/cv_provider.dart';
import 'package:cv_mobile/repositories/cv_repository.dart';
import 'package:cv_mobile/services/connectivity_service.dart';
import 'package:cv_mobile/usecases/cv/get_all_cvs_usecase.dart';
import 'package:cv_mobile/usecases/cv/get_cv_by_id_usecase.dart';
import 'package:cv_mobile/usecases/cv/create_cv_usecase.dart';
import 'package:cv_mobile/usecases/cv/update_cv_usecase.dart';
import 'package:cv_mobile/usecases/cv/delete_cv_usecase.dart';
import 'package:cv_mobile/usecases/cv/duplicate_cv_usecase.dart';
import 'package:cv_mobile/usecases/cv/create_variant_usecase.dart';

class MockGetAllCvs extends Mock implements GetAllCvsUseCase {}
class MockGetCvById extends Mock implements GetCvByIdUseCase {}
class MockCreateCv extends Mock implements CreateCvUseCase {}
class MockUpdateCv extends Mock implements UpdateCvUseCase {}
class MockDeleteCv extends Mock implements DeleteCvUseCase {}
class MockDuplicateCv extends Mock implements DuplicateCvUseCase {}
class MockCreateVariant extends Mock implements CreateVariantUseCase {}
class MockCvRepository extends Mock implements CvRepository {}
class MockConnectivityService extends Mock implements ConnectivityService {}

Cv _fakeCv({int id = 1, String titre = 'Mon CV'}) => Cv(
      id: id,
      titre: titre,
      educations: const [],
      experiences: const [],
      skills: const [],
      languages: const [],
    );

void main() {
  late MockGetAllCvs mockGetAll;
  late MockGetCvById mockGetById;
  late MockCreateCv mockCreate;
  late MockUpdateCv mockUpdate;
  late MockDeleteCv mockDelete;
  late MockDuplicateCv mockDuplicate;
  late MockCreateVariant mockCreateVariant;
  late MockCvRepository mockRepo;
  late MockConnectivityService mockConnectivity;
  late StreamController<bool> connectivityCtrl;

  setUp(() {
    mockGetAll = MockGetAllCvs();
    mockGetById = MockGetCvById();
    mockCreate = MockCreateCv();
    mockUpdate = MockUpdateCv();
    mockDelete = MockDeleteCv();
    mockDuplicate = MockDuplicateCv();
    mockCreateVariant = MockCreateVariant();
    mockRepo = MockCvRepository();
    mockConnectivity = MockConnectivityService();
    connectivityCtrl = StreamController<bool>.broadcast();

    registerFallbackValue(_fakeCv());
    registerFallbackValue(const NoParams());
    registerFallbackValue(UpdateCvParams(id: 0, cv: _fakeCv()));
    registerFallbackValue(const CreateVariantParams(cvId: 0, jobDescription: ''));

    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityCtrl.stream);
  });

  tearDown(() => connectivityCtrl.close());

  CvProvider buildProvider() => CvProvider(
        getAllCvs: mockGetAll,
        getCvById: mockGetById,
        createCv: mockCreate,
        updateCv: mockUpdate,
        deleteCv: mockDelete,
        duplicateCv: mockDuplicate,
        createVariantUseCase: mockCreateVariant,
        repository: mockRepo,
        connectivity: mockConnectivity,
      );

  group('CvProvider', () {
    test('etat initial : liste vide', () {
      final provider = buildProvider();
      expect(provider.cvs, isEmpty);
      expect(provider.isLoading, false);
    });

    test('loadCvs succes', () async {
      final cvs = [_fakeCv(id: 1), _fakeCv(id: 2, titre: 'CV 2')];
      when(() => mockGetAll(any())).thenAnswer((_) async => Result.success(cvs));

      final provider = buildProvider();
      await provider.loadCvs();

      expect(provider.cvs.length, 2);
    });

    test('loadCvs echec', () async {
      when(() => mockGetAll(any())).thenAnswer((_) async =>
          const Result.failure(NetworkException(message: 'Erreur reseau')));

      final provider = buildProvider();
      await provider.loadCvs();

      expect(provider.cvs, isEmpty);
      expect(provider.error, 'Erreur reseau');
    });

    test('loadCvById succes', () async {
      final cv = _fakeCv(id: 42, titre: 'CV Detail');
      when(() => mockGetById(42)).thenAnswer((_) async => Result.success(cv));

      final provider = buildProvider();
      await provider.loadCvById(42);

      expect(provider.currentCv?.id, 42);
    });

    test('createCv succes', () async {
      final newCv = _fakeCv(id: 10, titre: 'Nouveau CV');
      when(() => mockCreate(any())).thenAnswer((_) async => Result.success(newCv));

      final provider = buildProvider();
      final result = await provider.createCv(_fakeCv(titre: 'Nouveau CV'));

      expect(result, true);
      expect(provider.cvs.length, 1);
    });

    test('createCv echec', () async {
      when(() => mockCreate(any())).thenAnswer((_) async =>
          const Result.failure(ServerException(message: 'Creation impossible')));

      final provider = buildProvider();
      final result = await provider.createCv(_fakeCv());

      expect(result, false);
      expect(provider.error, 'Creation impossible');
    });

    test('updateCv succes', () async {
      final original = _fakeCv(id: 5, titre: 'Ancien');
      final updated = _fakeCv(id: 5, titre: 'Nouveau');
      when(() => mockGetAll(any())).thenAnswer((_) async => Result.success([original]));
      when(() => mockUpdate(any())).thenAnswer((_) async => Result.success(updated));

      final provider = buildProvider();
      await provider.loadCvs();
      final result = await provider.updateCv(5, updated);

      expect(result, true);
      expect(provider.cvs.first.titre, 'Nouveau');
    });

    test('deleteCv succes', () async {
      final cv = _fakeCv(id: 3);
      when(() => mockGetAll(any())).thenAnswer((_) async => Result.success([cv]));
      when(() => mockDelete(3)).thenAnswer((_) async => const Result.success(null));

      final provider = buildProvider();
      await provider.loadCvs();
      final result = await provider.deleteCv(3);

      expect(result, true);
      expect(provider.cvs, isEmpty);
    });

    test('deleteCv echec', () async {
      when(() => mockDelete(any())).thenAnswer((_) async =>
          const Result.failure(ServerException(message: 'Suppression impossible')));

      final provider = buildProvider();
      final result = await provider.deleteCv(99);

      expect(result, false);
      expect(provider.error, 'Suppression impossible');
    });

    test('duplicateCv succes', () async {
      final copy = _fakeCv(id: 6, titre: 'Copie');
      when(() => mockGetAll(any())).thenAnswer((_) async => Result.success([_fakeCv(id: 5)]));
      when(() => mockDuplicate(5)).thenAnswer((_) async => Result.success(copy));

      final provider = buildProvider();
      await provider.loadCvs();
      final result = await provider.duplicateCv(5);

      expect(result, true);
      expect(provider.cvs.length, 2);
    });

    test('connectivity offline', () async {
      final provider = buildProvider();
      connectivityCtrl.add(false);
      await Future.microtask(() {});
      expect(provider.isOffline, true);
    });

    test('connectivity restored', () async {
      when(() => mockGetAll(any())).thenAnswer((_) async => const Result.success([]));

      final provider = buildProvider();
      connectivityCtrl.add(false);
      await Future.microtask(() {});
      connectivityCtrl.add(true);
      await Future.microtask(() {});
      expect(provider.isOffline, false);
    });

    // ── Tests variantes ───────────────────────────────────────

    test('createVariant succes : ajoute la variante a la liste', () async {
      final variant = _fakeCv(id: 20, titre: 'Mon CV — Dev Backend');
      when(() => mockCreateVariant(any()))
          .thenAnswer((_) async => Result.success(variant));

      final provider = buildProvider();
      final result = await provider.createVariant(10, 'Offre dev backend');

      expect(result, isNotNull);
      expect(result!.id, 20);
      expect(provider.cvs.length, 1);
      expect(provider.cvs.first.titre, 'Mon CV — Dev Backend');
    });

    test('createVariant echec : retourne null, error defini', () async {
      when(() => mockCreateVariant(any())).thenAnswer((_) async =>
          const Result.failure(ServerException(message: 'IA indisponible')));

      final provider = buildProvider();
      final result = await provider.createVariant(10, 'Offre');

      expect(result, isNull);
      expect(provider.error, 'IA indisponible');
    });

    test('Cv.isVariante retourne true quand varianteLabel defini', () {
      final variant = Cv(
        id: 20, titre: 'Variante',
        varianteLabel: 'Dev Backend', parentCvId: 10,
      );
      final original = _fakeCv(id: 10);

      expect(variant.isVariante, true);
      expect(original.isVariante, false);
    });
  });
}
