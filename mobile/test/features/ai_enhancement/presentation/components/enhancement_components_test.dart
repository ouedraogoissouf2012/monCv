import 'package:cv_mobile/features/ai_enhancement/domain/enhancement_change.dart';
import 'package:cv_mobile/features/ai_enhancement/domain/enhancement_level.dart';
import 'package:cv_mobile/features/ai_enhancement/presentation/components/before_after_row.dart';
import 'package:cv_mobile/features/ai_enhancement/presentation/components/consent_notice.dart';
import 'package:cv_mobile/features/ai_enhancement/presentation/components/enhancement_result_list.dart';
import 'package:cv_mobile/features/ai_enhancement/presentation/components/level_selector.dart';
import 'package:cv_mobile/features/ai_enhancement/presentation/components/status_banner.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr'), Locale('en')],
      locale: const Locale('fr'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ));
  }

  group('LevelSelector (#244 F3)', () {
    testWidgets('affiche les 3 niveaux et remonte la selection', (tester) async {
      EnhancementLevel? picked;
      await pump(
        tester,
        LevelSelector(
          selected: EnhancementLevel.medium,
          onSelected: (l) => picked = l,
        ),
      );

      // 3 tuiles rendues (une par niveau LITE/MEDIUM/MAX).
      expect(find.byType(GestureDetector), findsNWidgets(3));

      await tester.tap(find.byType(GestureDetector).last); // MAX
      await tester.pumpAndSettle();
      expect(picked, EnhancementLevel.max);
    });

    testWidgets('enabled=false -> onSelected non appele (#244 F3)',
        (tester) async {
      var called = false;
      await pump(
        tester,
        LevelSelector(
          selected: EnhancementLevel.lite,
          enabled: false,
          onSelected: (_) => called = true,
        ),
      );
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      expect(called, isFalse);
    });
  });

  group('ConsentNotice (#244 F3)', () {
    testWidgets('coche -> onChanged(true)', (tester) async {
      bool? value;
      await pump(
        tester,
        ConsentNotice(accepted: false, onChanged: (v) => value = v),
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });
  });

  group('StatusBanner (#244 F3)', () {
    testWidgets('aiGenerated -> libelle genere; sinon fallback',
        (tester) async {
      await pump(tester, const StatusBanner(aiGenerated: true));
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

      await pump(tester, const StatusBanner(aiGenerated: false));
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });

  group('BeforeAfterRow (#244 F3)', () {
    testWidgets('affiche avant (barre) et apres', (tester) async {
      await pump(tester,
          const BeforeAfterRow(before: 'ancien texte', after: 'nouveau texte'));
      expect(find.text('ancien texte'), findsOneWidget);
      expect(find.text('nouveau texte'), findsOneWidget);
    });

    testWidgets('before vide -> pas de bloc avant', (tester) async {
      await pump(tester,
          const BeforeAfterRow(before: '', after: 'nouveau texte'));
      expect(find.text('nouveau texte'), findsOneWidget);
    });
  });

  group('EnhancementResultList (#244 F3)', () {
    testWidgets('mappe le champ typé vers un libelle localise indexe',
        (tester) async {
      await pump(
        tester,
        const EnhancementResultList(changes: [
          EnhancementChange(
            field: EnhancementField.experienceDescription,
            before: 'ancienne',
            after: 'amelioree',
            index: 1,
          ),
        ]),
      );
      // "Experiences 2 - Description" (index 1 -> element 2).
      expect(find.textContaining('2'), findsWidgets);
      expect(find.text('amelioree'), findsOneWidget);
      expect(find.byType(BeforeAfterRow), findsOneWidget);
    });

    testWidgets('liste vide -> aucun BeforeAfterRow', (tester) async {
      await pump(tester, const EnhancementResultList(changes: []));
      expect(find.byType(BeforeAfterRow), findsNothing);
    });
  });
}
