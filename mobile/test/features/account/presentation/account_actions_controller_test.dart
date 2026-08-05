import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/features/account/application/delete_account.dart';
import 'package:cv_mobile/features/account/application/export_account_data.dart';
import 'package:cv_mobile/features/account/domain/account_repository.dart';
import 'package:cv_mobile/features/account/presentation/account_actions_controller.dart';

class _FakeAccountRepository implements AccountRepository {
  _FakeAccountRepository({this.exportResult, this.exportError, this.deleteError});

  Map<String, dynamic>? exportResult;
  Object? exportError;
  Object? deleteError;

  @override
  Future<Map<String, dynamic>> exportData() async {
    if (exportError != null) throw exportError!;
    return exportResult ?? const {};
  }

  @override
  Future<void> deleteAccount() async {
    if (deleteError != null) throw deleteError!;
  }
}

AccountActionsController _controller(
  _FakeAccountRepository repo, {
  required void Function() onClearSession,
}) =>
    AccountActionsController(
      exportData: ExportAccountDataUseCase(repo),
      deleteAccount: DeleteAccountUseCase(repo),
      clearSession: () async => onClearSession(),
    );

void main() {
  group('AccountActionsController.exportData (#250 E2)', () {
    test('succes : expose le JSON a copier, sans erreur', () async {
      final repo = _FakeAccountRepository(exportResult: {'email': 'a@b.c'});
      final controller = _controller(repo, onClearSession: () {});

      final outcome = await controller.exportData();

      expect(outcome, AccountActionOutcome.success);
      expect(controller.exportedJson, contains('a@b.c'));
      expect(controller.errorCode, isNull);
      expect(controller.exporting, isFalse);
    });

    test('echec : errorCode renseigne, aucun JSON', () async {
      final repo = _FakeAccountRepository(exportError: Exception('reseau'));
      final controller = _controller(repo, onClearSession: () {});

      final outcome = await controller.exportData();

      expect(outcome, AccountActionOutcome.failure);
      expect(controller.exportedJson, isNull);
      expect(controller.errorCode, isNotNull);
      expect(controller.exporting, isFalse);
    });
  });

  group('AccountActionsController.deleteAccount (#250 E2)', () {
    test('succes : nettoie la session APRES confirmation backend', () async {
      final repo = _FakeAccountRepository();
      var cleared = 0;
      final controller = _controller(repo, onClearSession: () => cleared++);

      final outcome = await controller.deleteAccount();

      expect(outcome, AccountActionOutcome.success);
      expect(cleared, 1);
      expect(controller.deleting, isFalse);
      expect(controller.errorCode, isNull);
    });

    test('echec backend : session INTACTE (pas de nettoyage)', () async {
      final repo = _FakeAccountRepository(deleteError: Exception('500'));
      var cleared = 0;
      final controller = _controller(repo, onClearSession: () => cleared++);

      final outcome = await controller.deleteAccount();

      expect(outcome, AccountActionOutcome.failure);
      expect(cleared, 0);
      expect(controller.errorCode, isNotNull);
      expect(controller.deleting, isFalse);
    });

    test('notifie les listeners (debut + fin)', () async {
      final repo = _FakeAccountRepository();
      final controller = _controller(repo, onClearSession: () {});
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.deleteAccount();

      expect(notifications, greaterThanOrEqualTo(2));
    });
  });
}
