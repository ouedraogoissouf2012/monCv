import 'dart:async';

import 'package:flutter/painting.dart' show Color;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/models/cv_style.dart';
import 'package:cv_mobile/providers/cv_provider.dart';
import 'package:cv_mobile/services/sync_queue.dart';

import '../../flows/helpers/fake_data.dart';
import '../../flows/helpers/mock_definitions.dart';

/// Banc d'essai partage pour les tests de [CvProvider].
///
/// Regroupe le cablage commun (mocks, fallbacks, construction du provider)
/// des suites decoupees (`cv_provider_crud`, `cv_provider_variant`,
/// `cv_provider_offline`). Ne contient AUCUNE assertion metier : les
/// verifications restent dans chaque fichier de test, conformement a la
/// charte (#234 — les helpers restent specialises et sans assertion cachee).
class CvProviderHarness {
  late final MockGetAllCvsUseCase getAll;
  late final MockGetCvByIdUseCase getById;
  late final MockCreateCvUseCase create;
  late final MockUpdateCvUseCase update;
  late final MockDeleteCvUseCase delete;
  late final MockDuplicateCvUseCase duplicate;
  late final MockCreateVariantUseCase createVariant;
  late final MockCvRepository repository;
  late final MockConnectivityService connectivity;
  late final StreamController<bool> connectivityController;

  /// Initialise les mocks et les fallback values. A appeler dans `setUp()`.
  void setUp() {
    getAll = MockGetAllCvsUseCase();
    getById = MockGetCvByIdUseCase();
    create = MockCreateCvUseCase();
    update = MockUpdateCvUseCase();
    delete = MockDeleteCvUseCase();
    duplicate = MockDuplicateCvUseCase();
    createVariant = MockCreateVariantUseCase();
    repository = MockCvRepository();
    connectivity = MockConnectivityService();
    connectivityController = StreamController<bool>.broadcast();

    // registerAllFallbackValues() couvre deja NoParams, UpdateCvParams et
    // CreateVariantParams (cf. mock_definitions.dart) — pas de doublon ici.
    registerAllFallbackValues();

    when(() => connectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);
  }

  /// Libere le stream de connectivite. A appeler dans `tearDown()`.
  Future<void> tearDown() => connectivityController.close();

  /// Construit un provider cable sur les mocks du harness.
  ///
  /// [syncQueue] n'est fourni que par les scenarios offline persistants.
  CvProvider buildProvider({SyncQueue? syncQueue}) => CvProvider(
        getAllCvs: getAll,
        getCvById: getById,
        createCv: create,
        updateCv: update,
        deleteCv: delete,
        duplicateCv: duplicate,
        createVariantUseCase: createVariant,
        repository: repository,
        connectivity: connectivity,
        syncQueue: syncQueue,
      );

  /// Prepare une [SyncQueue] adossee a des SharedPreferences mockees.
  static Future<SyncQueue> newSyncQueue() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return SyncQueue(prefs);
  }
}

/// CV minimal (listes vides) pour les scenarios CRUD/offline ou seuls
/// l'`id`, le `titre` et le `style` importent. Distinct du [fakeCv] riche
/// de `fake_data.dart`, volontairement, pour ne pas coupler ces tests a
/// des donnees de contenu non pertinentes.
Cv minimalCv({
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

/// CV riche utilise par le scenario de relecture IA, ou chaque section
/// doit exister pour verifier que les corrections preservent les niveaux.
Cv aiReviewCv() => Cv(
      id: 42,
      titre: 'CV test',
      personalInfo: PersonalInfo(
        titrePoste: 'Comminoty manager',
        resumeProfessionnel: 'Developpeur de contenus',
      ),
      experiences: [
        Experience(id: 1, poste: 'Comminoty manager', description: 'Texte'),
      ],
      educations: [
        Education(
          id: 2,
          etablissement: 'lyce municipal',
          diplome: 'Baccalaureat',
        ),
      ],
      skills: [Skill(id: 3, nom: 'world', niveau: 1)],
      languages: [Language(id: 4, langue: 'Francais', niveau: 'NATIF')],
      certifications: [
        Certification(id: 5, nom: 'Certificat', organisme: 'Universite'),
      ],
      projects: [
        Project(id: 6, nom: 'Creation', technologies: 'excel, canva'),
      ],
    );

/// Payload de relecture IA correspondant a [aiReviewCv], avec accents et
/// orthographe corriges. Isole ici pour rester lisible dans le test.
Map<String, dynamic> aiReviewPayload() => {
      'titrePoste': 'Community manager',
      'resumeProfessionnel': 'Développeur de contenus',
      'experiences': [
        {'poste': 'Community manager', 'description': 'Texte'},
      ],
      'educations': [
        {
          'etablissement': 'lycée municipal',
          'diplome': 'Baccalauréat',
          'description': null,
        },
      ],
      'skills': [
        {'nom': 'Word', 'niveau': 1},
      ],
      'languages': [
        {'langue': 'Français'},
      ],
      'certifications': [
        {'nom': 'Certificat', 'organisme': 'Université'},
      ],
      'projects': [
        {'nom': 'Création', 'technologies': 'Excel, Canva'},
      ],
    };

/// Style non-defaut reutilise par le test `updateCvStyle`.
const CvStyle sampleStyle = CvStyle(
  templateId: 'classique',
  primaryColor: Color(0xFF10B981),
  fontFamily: 'Lato',
);
