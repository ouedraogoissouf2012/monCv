import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/ai/application/match_job_usecase.dart';
import 'package:cv_mobile/features/ai/domain/entities/job_match.dart';
import 'package:cv_mobile/features/ai/domain/repositories/ai_repository.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_detail_controller.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_editor_controller.dart';
import 'package:cv_mobile/features/cv/presentation/controllers/cv_list_controller.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:cv_mobile/features/cv/presentation/cv_store.dart';
import 'package:cv_mobile/features/job_match/presentation/job_match_controller.dart';
import 'package:cv_mobile/screens/cv/controllers/cv_form_controller.dart';
import 'package:cv_mobile/usecases/cv/update_cv_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../flows/helpers/mock_definitions.dart';

class _MockAiRepo extends Mock implements AiRepository {}

/// Anti-regression de l'issue #501 : CV edite affichant des donnees perimees.
///
/// Le bug venait de DEUX voies d'ecriture concurrentes : le formulaire ecrivait
/// via `CvRepository` puis rechargeait la liste, ce qui laissait `currentCv`
/// (lu par l'ecran de detail) sur la copie chargee a l'ouverture. Le correctif
/// initial avait deplace la reconciliation dans le widget via un service
/// locator, deplacant le probleme au lieu de le supprimer.
///
/// Ces tests verifient le contrat inverse : toute ecriture declenchee par l'UI
/// passe par le port `CvWriter` et laisse l'etat partage aligne sur la version
/// persistee, SANS rechargement reseau.
void main() {
  setUpAll(registerAllFallbackValues);

  late MockCreateCvUseCase createCv;
  late MockUpdateCvUseCase updateCv;
  late MockCreateVariantUseCase createVariant;
  late MockGetAllCvsUseCase getAllCvs;
  late MockGetCvByIdUseCase getCvById;
  late _MockAiRepo aiRepo;
  late CvStore store;
  late CvEditorController editor;

  setUp(() {
    createCv = MockCreateCvUseCase();
    updateCv = MockUpdateCvUseCase();
    createVariant = MockCreateVariantUseCase();
    getAllCvs = MockGetAllCvsUseCase();
    getCvById = MockGetCvByIdUseCase();
    aiRepo = _MockAiRepo();
    store = CvStore();
    editor = CvEditorController(
      createCv: createCv,
      updateCv: updateCv,
      deleteCv: MockDeleteCvUseCase(),
      duplicateCv: MockDuplicateCvUseCase(),
      createVariant: createVariant,
      repository: MockCvRepository(),
      store: store,
    );
  });

  Cv cvWithTitle(String titrePoste, {int? id}) => Cv(
        id: id,
        titre: 'CV',
        personalInfo: PersonalInfo(
          prenom: 'Awa',
          nom: 'Kone',
          email: 'awa@example.com',
          titrePoste: titrePoste,
        ),
      );

  /// Le serveur renvoie le CV tel qu'il a ete envoye (echo).
  void stubUpdateEcho() =>
      when(() => updateCv(any())).thenAnswer((invocation) async => Success(
          (invocation.positionalArguments.first as UpdateCvParams).cv));

  CvFormController formFor(Cv? initial) {
    final form = CvFormController(
      writer: editor,
      initialCv: initial,
      fallbackTitle: 'Mon CV',
    );
    addTearDown(form.dispose);
    return form;
  }

  void renameTo(CvFormController form, String titrePoste) =>
      form.updatePersonalInfo(PersonalInfo(
        prenom: 'Awa',
        nom: 'Kone',
        email: 'awa@example.com',
        titrePoste: titrePoste,
      ));

  group('Edition depuis le formulaire (#501)', () {
    test('apres save(), le CV courant du store porte le nouveau contenu',
        () async {
      final existing = cvWithTitle('Dev Junior', id: 1);
      store.setCvs([existing]);
      // L'ecran de detail a charge le CV courant a l'ouverture.
      store.setCurrentCv(existing);
      stubUpdateEcho();

      final form = formFor(existing);
      renameTo(form, 'Dev Senior');

      expect(await form.save(), isTrue);
      expect(store.currentCv?.personalInfo?.titrePoste, 'Dev Senior',
          reason: 'le detail lit store.currentCv, il doit refleter l edition');
      expect(store.cvs.single.personalInfo?.titrePoste, 'Dev Senior',
          reason: 'la liste aussi, sans rechargement reseau');
    });

    test('save() ne declenche aucun rechargement de liste', () async {
      final existing = cvWithTitle('Dev Junior', id: 1);
      store.setCvs([existing]);
      store.setCurrentCv(existing);
      stubUpdateEcho();

      final form = formFor(existing);
      renameTo(form, 'Dev Senior');
      await form.save();

      // Le refetch etait le pansement que cette correction supprime : la
      // reconciliation vient du store, pas d'un aller-retour reseau.
      verifyNever(() => getAllCvs(any()));
      verifyNever(() => getCvById(any()));
    });

    test('creation : le nouveau CV entre dans la liste et devient courant',
        () async {
      when(() => createCv(any())).thenAnswer((invocation) async =>
          Success((invocation.positionalArguments.first as Cv).copyWith(id: 7)));

      final form = formFor(null);
      renameTo(form, 'Dev');

      expect(await form.save(), isTrue);
      expect(store.cvs.map((c) => c.id), [7]);
      expect(store.currentCv?.id, 7);
    });

    test('echec serveur : le store garde la version persistee', () async {
      final existing = cvWithTitle('Dev Junior', id: 1);
      store.setCvs([existing]);
      store.setCurrentCv(existing);
      when(() => updateCv(any())).thenAnswer(
          (_) async => const Failure(ServerException(message: 'boom')));

      final form = formFor(existing);
      renameTo(form, 'Dev Senior');

      expect(await form.save(), isFalse);
      expect(store.currentCv?.personalInfo?.titrePoste, 'Dev Junior',
          reason: 'jamais afficher comme sauvegarde un contenu non persiste');
      expect(form.error, 'boom');
    });
  });

  group('Variante Job Match (#501)', () {
    /// Controller d'analyse dont le rapport a abouti (prealable a la variante).
    Future<JobMatchController> analyzed() async {
      when(() => aiRepo.matchJob(1, any(),
              consentAccepted: any(named: 'consentAccepted')))
          .thenAnswer((_) async =>
              const Result.success(JobMatch(score: 80, aiGenerated: true)));
      final controller = JobMatchController(
        cvId: 1,
        matchJob: MatchJobUseCase(aiRepo),
        cvWriter: editor,
      );
      addTearDown(controller.dispose);
      controller
        ..setConsent(true)
        ..setJobDescription('Une offre suffisamment longue pour analyse.');
      await controller.analyze();
      return controller;
    }

    test('la variante creee apparait dans la liste des CV', () async {
      store.setCvs([cvWithTitle('Dev', id: 1)]);
      when(() => createVariant(any())).thenAnswer((_) async =>
          Success(Cv(id: 9, titre: 'CV', parentCvId: 1, varianteLabel: 'ATS')));

      final controller = await analyzed();
      await controller.createVariant();

      expect(controller.variantCreated, isTrue);
      expect(store.cvs.map((c) => c.id), [1, 9],
          reason: 'sans passage par le port, la variante restait invisible');
      expect(controller.variant?.label, 'ATS');
    });

    test('les notes de fidelite IA restent exposees a la vue', () async {
      store.setCvs([cvWithTitle('Dev', id: 1)]);
      when(() => createVariant(any())).thenAnswer((_) async => Success(Cv(
            id: 9,
            titre: 'CV',
            parentCvId: 1,
            varianteLabel: 'ATS',
            fidelityNotes: const ['annees inventees refusees'],
          )));

      final controller = await analyzed();
      await controller.createVariant();

      expect(controller.variant?.refusedNotes, ['annees inventees refusees'],
          reason: 'le passage par le port ne doit rien perdre de #508');
    });

    test('echec : aucune entree dans la liste, erreur typee exposee', () async {
      store.setCvs([cvWithTitle('Dev', id: 1)]);
      when(() => createVariant(any())).thenAnswer((_) async =>
          const Failure(AiException(code: 'AI_DOWN', message: 'ko')));

      final controller = await analyzed();
      await controller.createVariant();

      expect(controller.variantCreated, isFalse);
      expect(controller.variantError, isA<AiException>());
      expect(store.cvs.map((c) => c.id), [1]);
    });
  });

  group('Rafraichissement complet de la liste (#501)', () {
    test('le CV courant suit la version rechargee', () async {
      final stale = cvWithTitle('Dev Junior', id: 1);
      store.setCurrentCv(stale);
      store.setCvs([stale]);
      when(() => getAllCvs(any()))
          .thenAnswer((_) async => Success([cvWithTitle('Dev Senior', id: 1)]));

      await CvListController(getAllCvs: getAllCvs, store: store).load();

      expect(store.currentCv?.personalInfo?.titrePoste, 'Dev Senior',
          reason: 'pull-to-refresh ne doit pas laisser le detail perime');
    });

    test('CvDetailController garde la voie de chargement du CV courant',
        () async {
      when(() => getCvById(1))
          .thenAnswer((_) async => Success(cvWithTitle('Dev', id: 1)));

      await CvDetailController(getCvById: getCvById, store: store).load(1);

      expect(store.currentCv?.id, 1);
    });
  });
}
