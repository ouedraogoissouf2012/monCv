import 'package:cv_mobile/features/ai/domain/entities/job_match.dart';
import 'package:cv_mobile/features/job_match/domain/job_score_snapshot.dart';
import 'package:cv_mobile/features/job_match/presentation/components/job_detail_cards.dart';
import 'package:cv_mobile/features/job_match/presentation/components/job_history_keywords.dart';
import 'package:cv_mobile/features/job_match/presentation/components/job_score_card.dart';
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

  group('JobScoreCard (#245 G2)', () {
    testWidgets('affiche le pourcentage', (tester) async {
      await pump(tester, const JobScoreCard(score: 78));
      expect(find.text('78%'), findsOneWidget);
    });

    test('seuils de couleur : good/average/low', () {
      expect(JobMatchScoreThresholds.colorFor(80),
          JobMatchScoreThresholds.colorFor(70));
      expect(JobMatchScoreThresholds.colorFor(50),
          isNot(JobMatchScoreThresholds.colorFor(80)));
      expect(JobMatchScoreThresholds.colorFor(20),
          isNot(JobMatchScoreThresholds.colorFor(50)));
    });
  });

  group('JobCategoryCard (#245 G2)', () {
    testWidgets('affiche label, score et jusqu a 2 preuves', (tester) async {
      await pump(
        tester,
        const JobCategoryCard(
          category: MatchCategory(
            label: 'Competences techniques',
            score: 65,
            summary: 'Bon niveau',
            evidence: ['Dart', 'Flutter', 'Ignoree'],
          ),
        ),
      );
      expect(find.text('Competences techniques'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      // Max 2 preuves affichees.
      expect(find.text('Ignoree'), findsNothing);
    });
  });

  group('JobFormatChecksCard (#245 G2)', () {
    testWidgets('liste vide -> message aucun risque', (tester) async {
      await pump(tester, const JobFormatChecksCard(formatChecks: []));
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('severity critical -> icone erreur', (tester) async {
      await pump(
        tester,
        const JobFormatChecksCard(formatChecks: [
          FormatCheck(severity: 'critical', label: 'Photo', detail: 'A retirer'),
        ]),
      );
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Photo'), findsOneWidget);
    });
  });

  group('JobHistoryCard (#245 G2)', () {
    testWidgets('libelle derive de isRerun + ecart entre runs', (tester) async {
      await pump(
        tester,
        JobHistoryCard(history: [
          JobScoreSnapshot(
              score: 80, createdAt: DateTime(2026, 1, 1, 14, 30), isRerun: true),
          JobScoreSnapshot(
              score: 60, createdAt: DateTime(2026, 1, 1, 14), isRerun: false),
        ]),
      );
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      // Ecart +20 pour la plus recente vs la precedente.
      expect(find.text('+20'), findsOneWidget);
      // Heure formatee HH:mm.
      expect(find.text('14:30'), findsOneWidget);
    });
  });

  group('JobKeywordSection (#245 G2)', () {
    testWidgets('affiche titre et mots-cles', (tester) async {
      await pump(
        tester,
        const JobKeywordSection(
          title: 'Matches',
          icon: Icons.check,
          color: Colors.green,
          keywords: ['Dart', 'CI'],
        ),
      );
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('CI'), findsOneWidget);
    });
  });
}
