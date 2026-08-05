import 'package:cv_mobile/features/applications/domain/job_application.dart';
import 'package:cv_mobile/features/applications/domain/job_application_status.dart';
import 'package:cv_mobile/features/applications/presentation/application_form/application_form_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ApplicationFormModel valid() => const ApplicationFormModel(
        company: 'Acme',
        position: 'Dev',
      );

  group('validation pure (#246 A5)', () {
    test('modele minimal valide', () {
      expect(valid().validate().isValid, isTrue);
    });

    test('company et position requis', () {
      final v = const ApplicationFormModel().validate();
      expect(v.errorFor(ApplicationFormField.company),
          ApplicationFieldError.required);
      expect(v.errorFor(ApplicationFormField.position),
          ApplicationFieldError.required);
    });

    test('company blanc (espaces) -> requis', () {
      final v = valid().copyWith(company: '   ').validate();
      expect(v.errorFor(ApplicationFormField.company),
          ApplicationFieldError.required);
    });

    test('URL vide -> pas d erreur (champ optionnel)', () {
      expect(valid().copyWith(offerUrl: '').validate().isValid, isTrue);
    });

    test('URL http/https valide -> pas d erreur', () {
      expect(
          valid().copyWith(offerUrl: 'https://acme.example/job').validate().isValid,
          isTrue);
    });

    test('URL invalide (schema dangereux) -> invalidUrl', () {
      final v = valid().copyWith(offerUrl: 'javascript:alert(1)').validate();
      expect(v.errorFor(ApplicationFormField.offerUrl),
          ApplicationFieldError.invalidUrl);
    });

    test('relance avant envoi -> followUpBeforeSent', () {
      final v = valid()
          .copyWith(
            sentDate: DateTime(2026, 6, 10),
            nextFollowUp: DateTime(2026, 6, 5),
          )
          .validate();
      expect(v.errorFor(ApplicationFormField.followUp),
          ApplicationFieldError.followUpBeforeSent);
    });

    test('relance apres envoi -> valide', () {
      final v = valid()
          .copyWith(
            sentDate: DateTime(2026, 6, 10),
            nextFollowUp: DateTime(2026, 6, 20),
          )
          .validate();
      expect(v.isValid, isTrue);
    });

    test('plusieurs erreurs cumulees', () {
      final v = const ApplicationFormModel(offerUrl: 'file:///x').validate();
      expect(v.errors, hasLength(3)); // company + position + url
    });
  });

  group('mapping entite (#246 A5)', () {
    test('toApplication trim et null-ifie les champs vides', () {
      final a = valid()
          .copyWith(company: '  Acme  ', offerUrl: '', notes: '   ')
          .toApplication();
      expect(a.company, 'Acme');
      expect(a.offerUrl, isNull);
      expect(a.notes, isNull);
    });

    test('fromApplication pre-remplit pour l edition', () {
      const src = JobApplication(
        id: 7,
        company: 'Beta',
        position: 'Lead',
        offerUrl: 'https://beta.example',
        status: JobApplicationStatus.interview,
      );
      final m = ApplicationFormModel.fromApplication(src);
      expect(m.id, 7);
      expect(m.company, 'Beta');
      expect(m.offerUrl, 'https://beta.example');
      expect(m.status, JobApplicationStatus.interview);
      // round-trip : le modele reconstruit une entite equivalente.
      expect(m.toApplication().company, 'Beta');
    });
  });
}
