import 'dart:async';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/ai/application/enhance_cv_usecase.dart';
import 'package:cv_mobile/features/ai/domain/entities/enhanced_cv.dart';
import 'package:cv_mobile/features/ai/domain/repositories/ai_repository.dart';
import 'package:cv_mobile/features/ai_enhancement/domain/enhancement_level.dart';
import 'package:cv_mobile/features/ai_enhancement/presentation/enhancement_controller.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAiRepo extends Mock implements AiRepository {}

void main() {
  late _MockAiRepo repo;

  Cv savedCv() => Cv(
        id: 42,
        titre: 'CV',
        personalInfo: const PersonalInfo(titrePoste: 'Dev'),
      );

  EnhancementController controller({
    Cv? cv,
    bool proofreadOnly = false,
    void Function(AiException)? onAiError,
  }) =>
      EnhancementController(
        cv: cv ?? savedCv(),
        enhanceCv: EnhanceCvUseCase(repo),
        proofreadOnly: proofreadOnly,
        onAiError: onAiError,
      );

  setUp(() => repo = _MockAiRepo());

  group('EnhancementController - niveau (#244 F2)', () {
    test('niveau initial par defaut : MEDIUM', () {
      expect(controller().level, EnhancementLevel.medium);
    });

    test('mode relecture -> verrouille strictement LITE', () {
      final c = controller(proofreadOnly: true);
      expect(c.level, EnhancementLevel.lite);
      c.selectLevel(EnhancementLevel.max);
      expect(c.level, EnhancementLevel.lite, reason: 'verrouille en relecture');
    });

    test('selectLevel change le niveau hors relecture', () {
      final c = controller()..selectLevel(EnhancementLevel.max);
      expect(c.level, EnhancementLevel.max);
    });
  });

  group('EnhancementController - garde-fous (#244 F2)', () {
    test('sans consentement -> canEnhance faux et enhance() sans effet',
        () async {
      final c = controller();
      expect(c.canEnhance, isFalse);
      await c.enhance();
      verifyNever(() => repo.enhanceCv(any(), any(), consentAccepted: any(named: 'consentAccepted')));
    });

    test('CV non persiste (id null) -> canEnhance faux', () {
      final c = controller(cv: Cv(titre: 'brouillon'))..setConsent(true);
      expect(c.canEnhance, isFalse);
    });
  });

  group('EnhancementController - succes (#244 F2)', () {
    test('resultat typee + diff construits, loading retombe', () async {
      when(() => repo.enhanceCv(42, 'MEDIUM', consentAccepted: true))
          .thenAnswer(
        (_) async => const Result.success(
            EnhancedCv(titrePoste: 'Developpeur Senior', aiGenerated: true)),
      );
      final c = controller()..setConsent(true);

      final states = <bool>[];
      c.addListener(() => states.add(c.loading));
      await c.enhance();

      expect(c.result?.titrePoste, 'Developpeur Senior');
      expect(c.changes, hasLength(1)); // titre Dev -> Developpeur Senior
      expect(c.error, isNull);
      expect(c.loading, isFalse);
      expect(states.first, isTrue, reason: 'loading pendant l appel');
      expect(states.last, isFalse);
    });

    test('relecture : accents seuls -> aucun change', () async {
      when(() => repo.enhanceCv(42, 'LITE', consentAccepted: true)).thenAnswer(
        (_) async => const Result.success(EnhancedCv(
          experiences: [
            EnhancedExperience(poste: 'Développeur Web Full Stack'),
          ],
          aiGenerated: true,
        )),
      );
      final c = controller(
        cv: Cv(
          id: 42,
          titre: 'CV',
          experiences: [
            const Experience(poste: 'Developpeur Web Full Stack'),
          ],
        ),
        proofreadOnly: true,
      )..setConsent(true);

      await c.enhance();

      expect(c.result, isNotNull);
      expect(c.changes, isEmpty);
      expect(c.error, isNull);
    });

    test('le niveau selectionne est transmis au contrat backend', () async {
      when(() => repo.enhanceCv(42, 'MAX', consentAccepted: true)).thenAnswer(
          (_) async => const Result.success(EnhancedCv()));
      final c = controller()
        ..setConsent(true)
        ..selectLevel(EnhancementLevel.max);
      await c.enhance();
      verify(() => repo.enhanceCv(42, 'MAX', consentAccepted: true)).called(1);
    });
  });

  group('EnhancementController - erreurs et retry (#244 F2)', () {
    test('erreur IA typee -> exposee + onAiError notifie', () async {
      const aiError = AiException(
          code: 'AI_PROVIDER_DOWN', message: 'indisponible');
      when(() => repo.enhanceCv(any(), any(), consentAccepted: any(named: 'consentAccepted')))
          .thenAnswer((_) async => const Result.failure(aiError));
      AiException? received;
      final c = controller(onAiError: (e) => received = e)..setConsent(true);

      await c.enhance();

      expect(c.error, same(aiError));
      expect(received, same(aiError));
      expect(c.result, isNull);
    });

    test('erreur reseau generique -> exposee, sans callback IA', () async {
      when(() => repo.enhanceCv(any(), any(), consentAccepted: any(named: 'consentAccepted'))).thenAnswer(
          (_) async => const Result.failure(NetworkException()));
      AiException? received;
      final c = controller(onAiError: (e) => received = e)..setConsent(true);

      await c.enhance();

      expect(c.error, isA<NetworkException>());
      expect(received, isNull);
    });

    test('retry apres echec : erreur effacee puis succes', () async {
      final answers = <Result<EnhancedCv>>[
        const Result.failure(NetworkException()),
        const Result.success(EnhancedCv(titrePoste: 'Mieux')),
      ];
      when(() => repo.enhanceCv(any(), any(), consentAccepted: any(named: 'consentAccepted')))
          .thenAnswer((_) async => answers.removeAt(0));
      final c = controller()..setConsent(true);

      await c.enhance();
      expect(c.error, isNotNull);

      await c.enhance(); // retry
      expect(c.error, isNull);
      expect(c.result?.titrePoste, 'Mieux');
      verify(() => repo.enhanceCv(any(), any(), consentAccepted: any(named: 'consentAccepted'))).called(2);
    });

    test('dispose pendant l appel -> pas de notifyListeners', () async {
      final gate = Completer<Result<EnhancedCv>>();
      when(() => repo.enhanceCv(any(), any(),
              consentAccepted: any(named: 'consentAccepted')))
          .thenAnswer((_) => gate.future);
      final c = controller()..setConsent(true);

      final pending = c.enhance();
      c.dispose();
      gate.complete(const Result.success(EnhancedCv(titrePoste: 'Dev')));

      await expectLater(pending, completes);
    });
  });
}
