import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/repositories/cv_repository.dart';
import 'package:cv_mobile/screens/cv/controllers/cv_form_controller.dart';
import 'package:cv_mobile/screens/cv/validators/cv_form_validator.dart';
import 'package:cv_mobile/services/cv_readiness_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCvRepository extends Mock implements CvRepository {}

void main() {
  late MockCvRepository repository;
  late CvFormController controller;

  setUpAll(() => registerFallbackValue(Cv(titre: 'Fallback')));

  setUp(() {
    repository = MockCvRepository();
    controller = CvFormController(
      repository: repository,
      fallbackTitle: 'Mon CV',
      titleBuilder: (firstName, lastName) => 'CV de $firstName $lastName',
    );
  });

  tearDown(() => controller.dispose());

  test('etat initial vide', () {
    expect(controller.currentStep, 0);
    expect(controller.currentCv.titre, 'Mon CV');
    expect(controller.completionPercent, 0);
    expect(
      controller.validation[CvFormSection.identity],
      CvFormValidationState.empty,
    );
  });

  test('met a jour toutes les sections et la completion', () {
    controller.updatePersonalInfo(PersonalInfo(
      prenom: 'Awa',
      nom: 'Kone',
      email: 'awa@example.com',
    ));
    controller.addExperience(Experience(poste: 'Dev'));
    controller.addEducation(Education(diplome: 'Master'));
    controller.addSkill(Skill(nom: 'Flutter', niveau: 4));
    controller.addProject(Project(nom: 'MonCV'));

    expect(controller.currentCv.titre, 'CV de Awa Kone');
    expect(
      controller.completionPercent,
      const CvReadinessService().evaluate(controller.currentCv).score,
    );
    expect(controller.experiences, hasLength(1));
    expect(controller.educations, hasLength(1));
    expect(controller.skills, hasLength(1));
    expect(controller.projects, hasLength(1));
  });

  test('navigation refuse les index hors limites', () {
    expect(controller.goToStep(-1), false);
    expect(controller.goToStep(5), false);
    expect(controller.goToStep(1), true);
    expect(controller.currentStep, 1);
  });

  test('creation sauvegardee via repository injecte', () async {
    controller.updatePersonalInfo(PersonalInfo(
      prenom: 'Awa',
      nom: 'Kone',
      email: 'awa@example.com',
    ));
    when(() => repository.createCv(any())).thenAnswer(
      (invocation) async => Result.success(
        (invocation.positionalArguments.first as Cv).copyWith(id: 42),
      ),
    );

    expect(await controller.save(), true);
    expect(controller.savedCv?.id, 42);
    expect(controller.error, isNull);
    verify(() => repository.createCv(any())).called(1);
  });

  test('erreur repository exposee au formulaire', () async {
    when(() => repository.createCv(any())).thenAnswer(
      (_) async => const Result.failure(
        NetworkException(message: 'Connexion indisponible'),
      ),
    );

    expect(await controller.save(), false);
    expect(controller.error, 'Connexion indisponible');
    expect(controller.isLoading, false);
  });

  test('edition preserve le style et utilise update', () async {
    final initial = Cv(id: 7, titre: 'CV Senior');
    controller.dispose();
    controller = CvFormController(
      repository: repository,
      initialCv: initial,
      fallbackTitle: 'Mon CV',
    );
    when(() => repository.updateCv(7, any())).thenAnswer(
      (invocation) async =>
          Result.success(invocation.positionalArguments[1] as Cv),
    );

    expect(await controller.save(), true);
    verify(() => repository.updateCv(7, any())).called(1);
    expect(controller.currentCv.titre, 'CV Senior');
    expect(controller.currentCv.style, initial.style);
  });
}
