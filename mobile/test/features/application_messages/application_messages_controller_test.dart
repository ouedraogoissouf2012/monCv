import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/ai/application/generate_application_messages_usecase.dart';
import 'package:cv_mobile/features/ai/domain/entities/application_messages.dart';
import 'package:cv_mobile/features/ai/domain/repositories/ai_repository.dart';
import 'package:cv_mobile/features/application_messages/domain/clipboard_copier.dart';
import 'package:cv_mobile/features/application_messages/presentation/application_messages_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAiRepo extends Mock implements AiRepository {}

/// Presse-papier en memoire : enregistre le dernier texte copie, sans toucher
/// au systeme. Prouve que la copie est bien DELEGUEE (separee de la generation).
class _SpyClipboard implements ClipboardCopier {
  final List<String> copied = [];
  @override
  Future<void> copy(String text) async => copied.add(text);
}

void main() {
  late _MockAiRepo repo;
  late _SpyClipboard clipboard;

  ApplicationMessagesController controller() => ApplicationMessagesController(
        cvId: 42,
        jobDescription: 'Une offre de developpeur full stack.',
        generate: GenerateApplicationMessagesUseCase(repo),
        clipboard: clipboard,
      );

  setUp(() {
    repo = _MockAiRepo();
    clipboard = _SpyClipboard();
  });

  const okMessages = ApplicationMessages(
    coverLetter: 'Lettre',
    email: 'Email',
    linkedIn: 'LinkedIn',
    whatsApp: 'WhatsApp',
    tone: 'PROFESSIONAL',
    aiGenerated: true,
  );

  group('generation (#245 G5)', () {
    test('ton par defaut = PROFESSIONAL', () {
      expect(controller().tone, 'PROFESSIONAL');
    });

    test('succes -> messages typés exposes', () async {
      when(() => repo.generateApplicationMessages(42, any(), any()))
          .thenAnswer((_) async => const Result.success(okMessages));
      final c = controller();

      await c.generate();

      expect(c.messages?.coverLetter, 'Lettre');
      expect(c.textOf(MessageKind.email), 'Email');
      expect(c.error, isNull);
      expect(c.loading, isFalse);
    });

    test('erreur IA typee -> exposee + onAiError notifie', () async {
      const aiError =
          AiException(code: 'AI_PROVIDER_DOWN', message: 'indisponible');
      when(() => repo.generateApplicationMessages(any(), any(), any()))
          .thenAnswer((_) async => const Result.failure(aiError));
      AiException? received;
      final c = ApplicationMessagesController(
        cvId: 42,
        jobDescription: 'offre',
        generate: GenerateApplicationMessagesUseCase(repo),
        clipboard: clipboard,
        onAiError: (e) => received = e,
      );

      await c.generate();

      expect(c.error, same(aiError));
      expect(received, same(aiError));
      expect(c.messages, isNull);
    });

    test('changer de ton invalide le resultat courant', () async {
      when(() => repo.generateApplicationMessages(42, any(), any()))
          .thenAnswer((_) async => const Result.success(okMessages));
      final c = controller();
      await c.generate();
      expect(c.messages, isNotNull);

      c.selectTone('DIRECT');

      expect(c.tone, 'DIRECT');
      expect(c.messages, isNull, reason: 'le resultat ne correspond plus');
    });
  });

  group('copie separee de la generation (#245 G5)', () {
    test('copie le texte du canal via ClipboardCopier, retourne true',
        () async {
      when(() => repo.generateApplicationMessages(42, any(), any()))
          .thenAnswer((_) async => const Result.success(okMessages));
      final c = controller();
      await c.generate();

      final ok = await c.copy(MessageKind.linkedIn);

      expect(ok, isTrue);
      expect(clipboard.copied, ['LinkedIn'],
          reason: 'la copie est deleguee au service, pas a Clipboard direct');
    });

    test('copie sans generation prealable -> rien copie, retourne false',
        () async {
      final c = controller();

      final ok = await c.copy(MessageKind.coverLetter);

      expect(ok, isFalse);
      expect(clipboard.copied, isEmpty);
    });

    test('canal vide -> rien copie', () async {
      when(() => repo.generateApplicationMessages(42, any(), any()))
          .thenAnswer((_) async =>
              const Result.success(ApplicationMessages(coverLetter: 'X')));
      final c = controller();
      await c.generate();

      // email est null -> aucune copie.
      final ok = await c.copy(MessageKind.email);

      expect(ok, isFalse);
      expect(clipboard.copied, isEmpty);
    });
  });
}
