import 'package:cv_mobile/features/cv/domain/policies/cv_validation_thresholds.dart';
import 'package:cv_mobile/features/cv_list/presentation/components/cv_card.dart';
import 'package:cv_mobile/features/cv_list/presentation/components/cv_card_actions.dart';
import 'package:cv_mobile/features/cv_list/presentation/components/cv_card_badges.dart';
import 'package:cv_mobile/features/cv_list/presentation/components/cv_card_header.dart';
import 'package:cv_mobile/features/cv_list/presentation/components/cv_score_presentation.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:cv_mobile/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget child) => t.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ));

  group('CvScorePresentation - seuils #241 (#249 D3)', () {
    test('couleur derive des seuils display de la politique', () {
      expect(CvScorePresentation.color(CvValidationThresholds.displayGoodThreshold),
          AppColors.success);
      expect(
          CvScorePresentation.color(
              CvValidationThresholds.displayMediumThreshold),
          AppColors.warning);
      expect(
          CvScorePresentation.color(
              CvValidationThresholds.displayMediumThreshold - 1),
          AppColors.error);
    });
  });

  group('CvCardBadges (#249 D3)', () {
    testWidgets('CV standard sans badge -> rien', (t) async {
      await pump(t, CvCardBadges(cv: Cv(id: 1, titre: 'CV')));
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('variante -> badge avec le libelle', (t) async {
      await pump(t,
          CvCardBadges(cv: Cv(id: 1, titre: 'CV', varianteLabel: 'ATS')));
      expect(find.textContaining('ATS'), findsOneWidget);
    });

    testWidgets('CV non synchronise (id negatif) -> badge sync', (t) async {
      await pump(t, CvCardBadges(cv: Cv(id: -5, titre: 'CV')));
      final l = AppLocalizations.of(t.element(find.byType(CvCardBadges)))!;
      expect(find.text(l.pendingSync), findsOneWidget);
    });
  });

  group('CvCardActions (#249 D3)', () {
    testWidgets('chaque bouton declenche son callback', (t) async {
      var view = 0, share = 0, pdf = 0, docx = 0;
      await pump(
        t,
        CvCardActions(
          onView: () => view++,
          onShare: () => share++,
          onDownloadPdf: () => pdf++,
          onDownloadDocx: () => docx++,
        ),
      );
      final l = AppLocalizations.of(t.element(find.byType(CvCardActions)))!;
      await t.tap(find.text(l.view));
      await t.tap(find.byIcon(Icons.share_outlined));
      await t.tap(find.text(l.pdf));
      await t.tap(find.text(l.docx));
      expect([view, share, pdf, docx], [1, 1, 1, 1]);
    });
  });

  group('CvCard composition (#249 D3)', () {
    testWidgets('compose badges/header/actions et route le menu delete',
        (t) async {
      var deleted = 0;
      await pump(
        t,
        CvCard(
          cv: Cv(id: 1, titre: 'Mon CV', experiences: const []),
          onTap: () {},
          onEdit: () {},
          onDownloadPdf: () {},
          onDownloadDocx: () {},
          onDelete: () => deleted++,
          onDuplicate: () {},
          onShare: () {},
        ),
      );
      expect(find.text('Mon CV'), findsOneWidget);
      expect(find.byType(CvCardHeader), findsOneWidget);
      expect(find.byType(CvCardActions), findsOneWidget);

      // Ouvre le menu et supprime.
      await t.tap(find.byIcon(Icons.more_vert));
      await t.pumpAndSettle();
      final l = AppLocalizations.of(t.element(find.byType(CvCard)))!;
      await t.tap(find.text(l.delete).last);
      await t.pumpAndSettle();
      expect(deleted, 1);
    });
  });
}
