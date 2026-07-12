import 'dart:async';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/core/usecase/usecase.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/models/cv_style.dart';
import 'package:cv_mobile/providers/cv_provider.dart';
import 'package:cv_mobile/repositories/cv_repository.dart';
import 'package:cv_mobile/services/connectivity_service.dart';
import 'package:cv_mobile/usecases/cv/get_all_cvs_usecase.dart';
import 'package:cv_mobile/usecases/cv/get_cv_by_id_usecase.dart';
import 'package:cv_mobile/usecases/cv/create_cv_usecase.dart';
import 'package:cv_mobile/usecases/cv/update_cv_usecase.dart';
import 'package:cv_mobile/usecases/cv/delete_cv_usecase.dart';
import 'package:cv_mobile/usecases/cv/duplicate_cv_usecase.dart';

class MockGetAllCvs extends Mock implements GetAllCvsUseCase {}

class MockGetCvById extends Mock implements GetCvByIdUseCase {}

class MockCreateCv extends Mock implements CreateCvUseCase {}

class MockUpdateCv extends Mock implements UpdateCvUseCase {}

class MockDeleteCv extends Mock implements DeleteCvUseCase {}

class MockDuplicateCv extends Mock implements DuplicateCvUseCase {}

class MockCvRepository extends Mock implements CvRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

Cv _fakeCv({
  int id = 1,
  String titre = 'Mon CV',
  CvStyle style = CvStyle.defaultStyle,
}) =>
    Cv(
      id: id,
      titre: titre,
      educations: const [],
      experiences: const [],
      skills: const [],
      languages: const [],
      style: style,
    );

void main() {
  late MockGetAllCvs mockGetAll;
  late MockGetCvById mockGetById;
  late MockCreateCv mockCreate;
  late MockUpdateCv mockUpdate;
  late MockDeleteCv mockDelete;
  late MockDuplicateCv mockDuplicate;
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
    mockRepo = MockCvRepository();
    mockConnectivity = MockConnectivityService();
    connectivityCtrl = StreamController<bool>.broadcast();

    registerFallbackValue(_fakeCv());
    registerFallbackValue(const NoParams());
    registerFallbackValue(UpdateCvParams(id: 0, cv: _fakeCv()));

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
      when(() => mockGetAll(any()))
          .thenAnswer((_) async => Result.success(cvs));

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
      when(() => mockCreate(any()))
          .thenAnswer((_) async => Result.success(newCv));

      final provider = buildProvider();
      final result = await provider.createCv(_fakeCv(titre: 'Nouveau CV'));

      expect(result, true);
      expect(provider.cvs.length, 1);
    });

    test('createCv echec', () async {
      when(() => mockCreate(any())).thenAnswer((_) async =>
          const Result.failure(
              ServerException(message: 'Creation impossible')));

      final provider = buildProvider();
      final result = await provider.createCv(_fakeCv());

      expect(result, false);
      expect(provider.error, 'Creation impossible');
    });

    test('updateCv succes', () async {
      final original = _fakeCv(id: 5, titre: 'Ancien');
      final updated = _fakeCv(id: 5, titre: 'Nouveau');
      when(() => mockGetAll(any()))
          .thenAnswer((_) async => Result.success([original]));
      when(() => mockUpdate(any()))
          .thenAnswer((_) async => Result.success(updated));

      final provider = buildProvider();
      await provider.loadCvs();
      final result = await provider.updateCv(5, updated);

      expect(result, true);
      expect(provider.cvs.first.titre, 'Nouveau');
    });

    test('deleteCv succes', () async {
      final cv = _fakeCv(id: 3);
      when(() => mockGetAll(any()))
          .thenAnswer((_) async => Result.success([cv]));
      when(() => mockDelete(3))
          .thenAnswer((_) async => const Result.success(null));

      final provider = buildProvider();
      await provider.loadCvs();
      final result = await provider.deleteCv(3);

      expect(result, true);
      expect(provider.cvs, isEmpty);
    });

    test('deleteCv echec', () async {
      when(() => mockDelete(any())).thenAnswer((_) async =>
          const Result.failure(
              ServerException(message: 'Suppression impossible')));

      final provider = buildProvider();
      final result = await provider.deleteCv(99);

      expect(result, false);
      expect(provider.error, 'Suppression impossible');
    });

    test('duplicateCv succes', () async {
      final copy = _fakeCv(id: 6, titre: 'Copie');
      when(() => mockGetAll(any()))
          .thenAnswer((_) async => Result.success([_fakeCv(id: 5)]));
      when(() => mockDuplicate(5))
          .thenAnswer((_) async => Result.success(copy));

      final provider = buildProvider();
      await provider.loadCvs();
      final result = await provider.duplicateCv(5);

      expect(result, true);
      expect(provider.cvs.length, 2);
    });

    test('updateCvStyle sauvegarde le style via le repository', () async {
      const style = CvStyle(
        templateId: 'classique',
        primaryColor: Color(0xFF10B981),
        fontFamily: 'Lato',
      );
      final cv = _fakeCv(id: 7);
      when(() => mockRepo.updateCv(7, any())).thenAnswer((invocation) async {
        return Result.success(invocation.positionalArguments[1] as Cv);
      });

      final provider = buildProvider();
      provider.setCurrentCv(cv);

      final result = await provider.updateCvStyle(7, style);

      expect(result, true);
      expect(provider.currentCv?.style.templateId, 'classique');
      expect(provider.currentCv?.style.primaryColor.toARGB32(), 0xFF10B981);
      expect(provider.currentCv?.style.fontFamily, 'Lato');
      verify(() => mockRepo.updateCv(7, any())).called(1);
    });

    test('applyAiEnhancements applique la relecture sans perdre les niveaux',
        () async {
      final cv = Cv(
        id: 42,
        titre: 'CV test',
        personalInfo: PersonalInfo(
          titrePoste: 'Comminoty manager',
          resumeProfessionnel: 'Developpeur de contenus',
        ),
        experiences: [
          Experience(id: 1, poste: 'Comminoty manager', description: 'Texte')
        ],
        educations: [
          Education(
            id: 2,
            etablissement: 'lyce municipal',
            diplome: 'Baccalaureat',
          )
        ],
        skills: [Skill(id: 3, nom: 'world', niveau: 1)],
        languages: [Language(id: 4, langue: 'Francais', niveau: 'NATIF')],
        certifications: [
          Certification(id: 5, nom: 'Certificat', organisme: 'Universite')
        ],
        projects: [
          Project(id: 6, nom: 'Creation', technologies: 'excel, canva')
        ],
      );
      when(() => mockRepo.updateCv(42, any())).thenAnswer((invocation) async {
        return Result.success(invocation.positionalArguments[1] as Cv);
      });

      final provider = buildProvider()..setCurrentCv(cv);
      final result = await provider.applyAiEnhancements(42, {
        'titrePoste': 'Community manager',
        'resumeProfessionnel': 'Développeur de contenus',
        'experiences': [
          {'poste': 'Community manager', 'description': 'Texte'}
        ],
        'educations': [
          {
            'etablissement': 'lycée municipal',
            'diplome': 'Baccalauréat',
            'description': null,
          }
        ],
        'skills': [
          {'nom': 'Word', 'niveau': 1}
        ],
        'languages': [
          {'langue': 'Français'}
        ],
        'certifications': [
          {'nom': 'Certificat', 'organisme': 'Université'}
        ],
        'projects': [
          {'nom': 'Création', 'technologies': 'Excel, Canva'}
        ],
      });

      expect(result, true);
      expect(provider.currentCv?.personalInfo?.titrePoste, 'Community manager');
      expect(provider.currentCv?.experiences.first.poste, 'Community manager');
      expect(provider.currentCv?.educations.first.etablissement,
          'lycée municipal');
      expect(provider.currentCv?.skills.first.nom, 'Word');
      expect(provider.currentCv?.skills.first.niveau, 1);
      expect(provider.currentCv?.languages.first.langue, 'Français');
      expect(provider.currentCv?.certifications.first.organisme, 'Université');
      expect(provider.currentCv?.projects.first.technologies, 'Excel, Canva');
      verify(() => mockRepo.updateCv(42, any())).called(1);
    });

    test('connectivity offline', () async {
      final provider = buildProvider();
      connectivityCtrl.add(false);
      await Future.microtask(() {});
      expect(provider.isOffline, true);
    });

    test('connectivity restored', () async {
      when(() => mockGetAll(any()))
          .thenAnswer((_) async => const Result.success([]));

      final provider = buildProvider();
      connectivityCtrl.add(false);
      await Future.microtask(() {});
      connectivityCtrl.add(true);
      await Future.microtask(() {});
      expect(provider.isOffline, false);
    });
  });
}
