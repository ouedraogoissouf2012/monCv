import 'package:cv_mobile/features/cv/domain/validation/validation_code.dart';
import 'package:cv_mobile/features/cv/domain/validation/validation_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ValidationMessage - severite typee (#241)', () {
    test('factory error : severite error, isError vrai', () {
      final m = ValidationMessage.error('identite', ValidationCode.invalidEmail);
      expect(m.severity, ValidationSeverity.error);
      expect(m.isError, isTrue);
      expect(m.isWarning, isFalse);
      expect(m.section, 'identite');
    });

    test('factory warning : severite warning, isWarning vrai', () {
      final m =
          ValidationMessage.warning('profil', ValidationCode.summaryEmpty);
      expect(m.severity, ValidationSeverity.warning);
      expect(m.isWarning, isTrue);
      expect(m.isError, isFalse);
    });

    test('params conserves pour la traduction', () {
      final m = ValidationMessage.warning(
        'profil',
        ValidationCode.summaryShort,
        params: {'length': 42},
      );
      expect(m.params['length'], 42);
    });

    test('info : ni erreur ni avertissement', () {
      final m = ValidationMessage.info('profil', ValidationCode.noMetric);
      expect(m.isError, isFalse);
      expect(m.isWarning, isFalse);
      expect(m.severity, ValidationSeverity.info);
    });
  });

  group('ValidationOutcome - agregation deterministe (#241)', () {
    final messages = [
      ValidationMessage.error('identite', ValidationCode.requiredFieldMissing),
      ValidationMessage.warning('profil', ValidationCode.summaryEmpty),
      ValidationMessage.error('experiences', ValidationCode.descriptionMissing),
    ];

    test('errors ne retourne que les erreurs, dans l ordre', () {
      final outcome = ValidationOutcome(messages);
      expect(outcome.errors.map((m) => m.code), [
        ValidationCode.requiredFieldMissing,
        ValidationCode.descriptionMissing,
      ]);
    });

    test('warnings ne retourne que les avertissements', () {
      final outcome = ValidationOutcome(messages);
      expect(outcome.warnings.map((m) => m.code),
          [ValidationCode.summaryEmpty]);
    });

    test('hasErrors et firstError', () {
      final outcome = ValidationOutcome(messages);
      expect(outcome.hasErrors, isTrue);
      expect(outcome.firstError?.code, ValidationCode.requiredFieldMissing);
    });

    test('outcome vide : pas d erreur, firstError null', () {
      const outcome = ValidationOutcome.empty();
      expect(outcome.hasErrors, isFalse);
      expect(outcome.firstError, isNull);
      expect(outcome.messages, isEmpty);
    });
  });
}
