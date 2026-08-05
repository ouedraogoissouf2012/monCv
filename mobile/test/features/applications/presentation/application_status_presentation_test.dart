import 'package:cv_mobile/features/applications/domain/job_application_status.dart';
import 'package:cv_mobile/features/applications/presentation/components/application_status_presentation.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/l10n/app_localizations_fr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AppLocalizations l = AppLocalizationsFr();

  group('ApplicationStatusPresentation - exhaustif (#246 A6a)', () {
    test('un label non vide pour CHAQUE statut', () {
      for (final s in JobApplicationStatus.values) {
        expect(ApplicationStatusPresentation.label(l, s), isNotEmpty,
            reason: 'label manquant pour $s');
      }
    });

    test('les 7 statuts ont des libelles distincts', () {
      final labels = JobApplicationStatus.values
          .map((s) => ApplicationStatusPresentation.label(l, s))
          .toSet();
      expect(labels, hasLength(JobApplicationStatus.values.length));
    });

    test('une couleur et une icone pour chaque statut (pas d exception)', () {
      for (final s in JobApplicationStatus.values) {
        expect(() => ApplicationStatusPresentation.color(s), returnsNormally);
        expect(() => ApplicationStatusPresentation.icon(s), returnsNormally);
      }
    });

    test('couleurs distinctes entre statuts fonctionnels cles', () {
      // draft / offer / rejected doivent se distinguer visuellement.
      final draft = ApplicationStatusPresentation.color(JobApplicationStatus.draft);
      final offer = ApplicationStatusPresentation.color(JobApplicationStatus.offer);
      final rejected =
          ApplicationStatusPresentation.color(JobApplicationStatus.rejected);
      expect({draft, offer, rejected}, hasLength(3));
    });
  });
}
