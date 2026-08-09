import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/password_reset/application/confirm_password_reset.dart';
import 'package:cv_mobile/features/password_reset/application/request_password_reset.dart';
import 'package:cv_mobile/features/password_reset/domain/password_reset_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPasswordResetRepository extends Mock
    implements PasswordResetRepository {}

/// Use cases reset (issue #381) : delegation stricte au port + propagation
/// TYPEE du Result (aucun throw ne doit fuir).
void main() {
  late _MockPasswordResetRepository repo;

  setUp(() => repo = _MockPasswordResetRepository());

  group('RequestPasswordResetUseCase', () {
    test('delegue l\'email et propage Success', () async {
      when(() => repo.requestReset('a@b.c'))
          .thenAnswer((_) async => const Result.success(null));

      final result = await RequestPasswordResetUseCase(repo)
          .call(const RequestPasswordResetParams(email: 'a@b.c'));

      expect(result, isA<Success<void>>());
      verify(() => repo.requestReset('a@b.c')).called(1);
    });

    test('propage l\'echec typé sans lever', () async {
      when(() => repo.requestReset(any()))
          .thenAnswer((_) async => const Result.failure(NetworkException()));

      final result = await RequestPasswordResetUseCase(repo)
          .call(const RequestPasswordResetParams(email: 'a@b.c'));

      expect(result, isA<Failure<void>>());
    });
  });

  group('ConfirmPasswordResetUseCase', () {
    test('delegue token + newPassword et propage Success', () async {
      when(() => repo.confirmReset(
              token: 'tok', newPassword: 'NouveauMotDePasse1'))
          .thenAnswer((_) async => const Result.success(null));

      final result = await ConfirmPasswordResetUseCase(repo).call(
        const ConfirmPasswordResetParams(
            token: 'tok', newPassword: 'NouveauMotDePasse1'),
      );

      expect(result, isA<Success<void>>());
      verify(() => repo.confirmReset(
          token: 'tok', newPassword: 'NouveauMotDePasse1')).called(1);
    });

    test('propage l\'echec (jeton invalide) en Failure', () async {
      when(() => repo.confirmReset(
            token: any(named: 'token'),
            newPassword: any(named: 'newPassword'),
          )).thenAnswer((_) async => const Result.failure(ServerException()));

      final result = await ConfirmPasswordResetUseCase(repo).call(
        const ConfirmPasswordResetParams(token: 'bad', newPassword: 'x'),
      );

      expect(result, isA<Failure<void>>());
    });
  });
}
