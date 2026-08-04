import 'package:cv_mobile/features/applications/domain/job_application.dart';
import 'package:cv_mobile/features/applications/domain/job_application_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  JobApplication app({
    JobApplicationStatus status = JobApplicationStatus.sent,
    DateTime? nextFollowUp,
  }) =>
      JobApplication(
        company: 'Acme',
        position: 'Dev',
        status: status,
        nextFollowUp: nextFollowUp,
      );

  group('isFollowUpDue - horloge injectee (#246 A1)', () {
    final now = DateTime(2026, 6, 15, 10, 30);

    test('relance passee + statut actif -> due', () {
      final a = app(nextFollowUp: DateTime(2026, 6, 14));
      expect(a.isFollowUpDue(now), isTrue);
    });

    test('relance aujourd hui (au jour pres) -> due', () {
      // Heure de la relance anterieure a "now" mais meme jour : comparaison au
      // jour, donc due.
      final a = app(nextFollowUp: DateTime(2026, 6, 15, 8));
      expect(a.isFollowUpDue(now), isTrue);
    });

    test('relance future -> pas due', () {
      final a = app(nextFollowUp: DateTime(2026, 6, 16));
      expect(a.isFollowUpDue(now), isFalse);
    });

    test('sans date de relance -> pas due', () {
      expect(app(nextFollowUp: null).isFollowUpDue(now), isFalse);
    });

    test('statut termine -> jamais due meme si date passee', () {
      for (final s in [
        JobApplicationStatus.offer,
        JobApplicationStatus.rejected,
        JobApplicationStatus.archived,
      ]) {
        final a = app(status: s, nextFollowUp: DateTime(2026, 1, 1));
        expect(a.isFollowUpDue(now), isFalse, reason: 'statut $s est termine');
      }
    });

    test('deterministe : ne depend pas de l heure systeme', () {
      final a = app(nextFollowUp: DateTime(2030, 1, 1));
      // Avec une horloge en 2031, la meme entite devient due.
      expect(a.isFollowUpDue(DateTime(2029)), isFalse);
      expect(a.isFollowUpDue(DateTime(2031)), isTrue);
    });
  });

  group('JobApplicationStatus (#246 A1)', () {
    test('apiValue et fromApi sont reciproques', () {
      for (final s in JobApplicationStatus.values) {
        expect(JobApplicationStatus.fromApi(s.apiValue), s);
      }
    });

    test('valeur API inconnue -> draft', () {
      expect(JobApplicationStatus.fromApi('WAT'), JobApplicationStatus.draft);
    });

    test('isClosed exhaustif', () {
      expect(JobApplicationStatus.offer.isClosed, isTrue);
      expect(JobApplicationStatus.rejected.isClosed, isTrue);
      expect(JobApplicationStatus.archived.isClosed, isTrue);
      expect(JobApplicationStatus.sent.isClosed, isFalse);
      expect(JobApplicationStatus.interview.isClosed, isFalse);
    });
  });

  group('copyWith (#246 A1)', () {
    test('remplace uniquement les champs fournis', () {
      final a = app(status: JobApplicationStatus.draft);
      final b = a.copyWith(status: JobApplicationStatus.interview);
      expect(b.status, JobApplicationStatus.interview);
      expect(b.company, a.company);
      expect(b.position, a.position);
    });
  });
}
