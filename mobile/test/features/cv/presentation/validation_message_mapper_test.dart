import 'package:cv_mobile/features/cv/domain/validation/validation_code.dart';
import 'package:cv_mobile/features/cv/domain/validation/validation_result.dart';
import 'package:cv_mobile/features/cv/presentation/validation_message_mapper.dart';
import 'package:cv_mobile/l10n/app_localizations_en.dart';
import 'package:cv_mobile/l10n/app_localizations_fr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final mapperFr = ValidationMessageMapper(AppLocalizationsFr());
  final mapperEn = ValidationMessageMapper(AppLocalizationsEn());

  // Params minimaux pour les codes qui en exigent (index/length/count/name).
  ValidationMessage sample(ValidationCode code) => ValidationMessage.warning(
        'section',
        code,
        params: const {
          'index': 1,
          'length': 42,
          'count': 3,
          'name': 'X',
          'field': 'firstName',
        },
      );

  group('ValidationMessageMapper - exhaustivite (#241)', () {
    test('CHAQUE code a une traduction FR non vide', () {
      for (final code in ValidationCode.values) {
        final msg = mapperFr.message(sample(code));
        expect(msg, isNotEmpty, reason: 'FR manquant pour $code');
      }
    });

    test('CHAQUE code a une traduction EN non vide', () {
      for (final code in ValidationCode.values) {
        final msg = mapperEn.message(sample(code));
        expect(msg, isNotEmpty, reason: 'EN manquant pour $code');
      }
    });

    test('FR et EN different pour au moins un code (langues distinctes)', () {
      // Prend un code au message stable pour comparer les deux langues.
      final fr = mapperFr.message(sample(ValidationCode.noExperience));
      final en = mapperEn.message(sample(ValidationCode.noExperience));
      expect(fr, isNot(equals(en)));
    });
  });

  group('ValidationMessageMapper - params injectes (#241)', () {
    test('summaryShort injecte la longueur', () {
      final msg = mapperFr.message(ValidationMessage.warning(
          'profil', ValidationCode.summaryShort,
          params: const {'length': 87}));
      expect(msg, contains('87'));
    });

    test('fewSkills injecte le nombre', () {
      final msg = mapperFr.message(ValidationMessage.warning(
          'competences', ValidationCode.fewSkills,
          params: const {'count': 2}));
      expect(msg, contains('2'));
    });

    test('requiredFieldMissing route la cle de champ vers le libelle', () {
      final msg = mapperFr.message(ValidationMessage.error(
          'identite', ValidationCode.requiredFieldMissing,
          params: const {'field': 'email'}));
      // Le libelle email court doit apparaitre dans le message.
      expect(msg.toLowerCase(), contains('email'));
    });
  });
}
