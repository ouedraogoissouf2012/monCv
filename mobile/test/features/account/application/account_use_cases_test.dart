import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/account/application/delete_account.dart';
import 'package:cv_mobile/features/account/application/export_account_data.dart';
import 'package:cv_mobile/features/account/domain/account_repository.dart';

/// Repository de compte factice, comportement pilote par le test.
class _FakeAccountRepository implements AccountRepository {
  _FakeAccountRepository({this.exportResult, this.exportError, this.deleteError});

  Map<String, dynamic>? exportResult;
  Object? exportError;
  Object? deleteError;
  int deleteCalls = 0;

  @override
  Future<Map<String, dynamic>> exportData() async {
    if (exportError != null) throw exportError!;
    return exportResult ?? const {};
  }

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    if (deleteError != null) throw deleteError!;
  }
}

void main() {
  group('ExportAccountDataUseCase (#250 E2)', () {
    test('succes : JSON indente qui reserialise vers les memes donnees',
        () async {
      final repo = _FakeAccountRepository(
        exportResult: {'email': 'a@b.c', 'cvs': 3},
      );
      final result = await ExportAccountDataUseCase(repo).call();

      expect(result, isA<Success<String>>());
      final json = (result as Success<String>).data;
      // Indente (multi-lignes) et fidele au contenu.
      expect(json, contains('\n'));
      expect(jsonDecode(json), {'email': 'a@b.c', 'cvs': 3});
    });

    test('echec transport -> Result.failure (pas de throw)', () async {
      final repo = _FakeAccountRepository(exportError: Exception('reseau'));
      final result = await ExportAccountDataUseCase(repo).call();

      expect(result, isA<Failure<String>>());
      expect((result as Failure<String>).exception, isA<AppException>());
    });
  });

  group('DeleteAccountUseCase (#250 E2)', () {
    test('succes : appelle le repository et retourne Success', () async {
      final repo = _FakeAccountRepository();
      final result = await DeleteAccountUseCase(repo).call();

      expect(result, isA<Success<void>>());
      expect(repo.deleteCalls, 1);
    });

    test('echec backend -> Result.failure', () async {
      final repo = _FakeAccountRepository(deleteError: Exception('500'));
      final result = await DeleteAccountUseCase(repo).call();

      expect(result, isA<Failure<void>>());
    });
  });
}
