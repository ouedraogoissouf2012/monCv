import 'package:flutter_test/flutter_test.dart';
import 'package:cv_mobile/models/job_application.dart';

void main() {
  test('parses application status and linked CV', () {
    final value = JobApplication.fromJson({
      'id': 4,
      'cvId': 9,
      'cvTitle': 'CV Produit',
      'cvVariant': true,
      'company': 'Acme',
      'position': 'Product Manager',
      'status': 'INTERVIEW',
      'sentDate': '2026-07-14',
      'nextFollowUp': '2026-07-21',
    });

    expect(value.status, JobApplicationStatus.interview);
    expect(value.cvVariant, isTrue);
    expect(value.cvId, 9);
    expect(value.toJson()['status'], 'INTERVIEW');
  });

  test('marks a due non-terminal follow-up', () {
    final value = JobApplication(
      company: 'Acme',
      position: 'PM',
      status: JobApplicationStatus.sent,
      nextFollowUp: DateTime.now().subtract(const Duration(days: 1)),
    );
    expect(value.followUpDue, isTrue);
  });

  test('does not mark archived applications as due', () {
    final value = JobApplication(
      company: 'Acme',
      position: 'PM',
      status: JobApplicationStatus.archived,
      nextFollowUp: DateTime.now().subtract(const Duration(days: 1)),
    );
    expect(value.followUpDue, isFalse);
  });
}
