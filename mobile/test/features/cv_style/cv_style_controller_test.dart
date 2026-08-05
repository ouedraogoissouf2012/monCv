import 'dart:async';

import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/cv_style/presentation/cv_style_controller.dart';
import 'package:cv_mobile/models/cv_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = CvStyle(templateId: 'moderne');
  final styleA = base.copyWith(templateId: 'classique');
  final styleB = base.copyWith(templateId: 'elegant');

  /// Debouncer manuel : capture le callback au lieu de demarrer un vrai Timer.
  /// `fire()` declenche la sauvegarde a la demande (temps controle).
  late void Function()? pending;
  Timer manualDebounce(Duration _, void Function() cb) {
    pending = cb;
    return Timer(Duration.zero, () {}); // timer inerte
  }

  Future<void> fire() async {
    final cb = pending;
    pending = null;
    cb?.call();
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() => pending = null);

  CvStyleController controller(SaveCvStyle save, {int maxRetries = 2}) =>
      CvStyleController(
        initial: base,
        save: save,
        maxRetries: maxRetries,
        scheduleDebounce: manualDebounce,
      );

  group('debounce + save (#247 B2)', () {
    test('select met a jour l etat optimiste immediatement', () {
      final c = controller((_) async => const Result.success(null));
      c.select(styleA);
      expect(c.style, styleA);
      // Pas encore sauvegarde tant que le debounce n'a pas fire.
      expect(c.savedStyle, base);
    });

    test('un seul save malgre plusieurs select rapides (debounce)', () async {
      var saves = 0;
      final c = controller((_) async {
        saves++;
        return const Result.success(null);
      });

      c.select(styleA);
      c.select(styleB); // remplace le precedent avant le fire
      await fire();

      expect(saves, 1, reason: 'debounce : une seule sauvegarde');
      expect(c.savedStyle, styleB, reason: 'last-write-wins');
      expect(c.status, StyleSaveStatus.saved);
    });

    test('select identique -> pas de sauvegarde', () async {
      var saves = 0;
      final c = controller((_) async {
        saves++;
        return const Result.success(null);
      });
      c.select(base); // == initial
      await fire();
      expect(saves, 0);
    });
  });

  group('retry + rollback (#247 B2)', () {
    test('echec transitoire puis succes via retry', () async {
      final answers = <Result<void>>[
        const Result.failure(NetworkException()),
        const Result.success(null),
      ];
      final c = controller((_) async => answers.removeAt(0));

      c.select(styleA);
      await fire();

      expect(c.savedStyle, styleA);
      expect(c.status, StyleSaveStatus.saved);
    });

    test('echec definitif -> status error, rollback visuel, selection gardee',
        () async {
      final c = controller(
        (_) async => const Result.failure(ServerException()),
        maxRetries: 1,
      );

      c.select(styleA);
      await fire();

      expect(c.status, StyleSaveStatus.error);
      // Rollback visuel : le dernier style REELLEMENT sauve reste `base`.
      expect(c.savedStyle, base);
      // Mais la selection en cours n'est PAS perdue (retry manuel possible).
      expect(c.style, styleA);
    });

    test('saveNow rejoue la sauvegarde apres une erreur', () async {
      final answers = <Result<void>>[
        const Result.failure(ServerException()),
        const Result.failure(ServerException()),
        const Result.success(null),
      ];
      final c = controller((_) async => answers.removeAt(0), maxRetries: 0);

      c.select(styleA);
      await fire(); // 1er cycle : 1 tentative -> echec
      expect(c.status, StyleSaveStatus.error);

      await c.saveNow(); // 2e cycle : echec
      await c.saveNow(); // 3e cycle : succes
      expect(c.status, StyleSaveStatus.saved);
      expect(c.savedStyle, styleA);
    });
  });

  group('concurrence / last-write-wins (#247 B2)', () {
    test('une selection plus recente pendant un save -> resultat perime ignore',
        () async {
      final completers = <Completer<Result<void>>>[];
      final c = controller((_) async {
        final completer = Completer<Result<void>>();
        completers.add(completer);
        return completer.future;
      });

      c.select(styleA);
      await fire(); // lance save(styleA) — completer[0] en attente
      c.select(styleB);
      await fire(); // lance save(styleB) — completer[1] en attente

      // La reponse du PREMIER save (perimee) arrive apres : doit etre ignoree.
      completers[0].complete(const Result.success(null));
      await Future<void>.delayed(Duration.zero);
      completers[1].complete(const Result.success(null));
      await Future<void>.delayed(Duration.zero);

      expect(c.savedStyle, styleB, reason: 'seul le dernier save compte');
    });
  });
}
