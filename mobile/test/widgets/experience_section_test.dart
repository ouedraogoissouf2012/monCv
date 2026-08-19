import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cv_mobile/core/error/result.dart';
import 'package:cv_mobile/features/ai/application/suggest_bullets_usecase.dart';
import 'package:cv_mobile/features/ai/domain/repositories/ai_repository.dart';
import 'package:cv_mobile/features/cv/presentation/section_editor/ai_suggestions_sheet.dart';
import 'package:cv_mobile/features/cv/domain/entities/experience.dart';
import 'package:cv_mobile/screens/cv/sections/experience_section.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockAiRepository extends Mock implements AiRepository {}

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

List<Experience> _fakeExperiences() => [
      const Experience(
        poste: 'Développeur Flutter',
        entreprise: 'TechCorp',
        lieu: 'Paris',
        description: 'Développement mobile.',
        actuel: true,
      ),
      Experience(
        poste: 'Stagiaire',
        entreprise: 'StartupXYZ',
        dateDebut: DateTime(2022, 1),
        dateFin: DateTime(2022, 6),
        actuel: false,
      ),
    ];

void main() {
  group('ExperienceSection', () {
    testWidgets('affiche SectionEmptyState quand la liste est vide', (tester) async {
      await tester.pumpWidget(_wrap(
        ExperienceSection(experiences: const [], onChanged: (_) {}),
      ));
      expect(find.text('Aucune expérience ajoutée'), findsOneWidget);
    });

    testWidgets('affiche les expériences existantes', (tester) async {
      await tester.pumpWidget(_wrap(
        ExperienceSection(experiences: _fakeExperiences(), onChanged: (_) {}),
      ));
      expect(find.text('Développeur Flutter'), findsOneWidget);
      expect(find.text('Stagiaire'), findsOneWidget);
    });

    testWidgets('badge "En poste" affiché pour actuel=true', (tester) async {
      await tester.pumpWidget(_wrap(
        ExperienceSection(experiences: _fakeExperiences(), onChanged: (_) {}),
      ));
      expect(find.text('En poste'), findsOneWidget);
    });

    testWidgets('bouton "Ajouter une expérience" toujours visible', (tester) async {
      await tester.pumpWidget(_wrap(
        ExperienceSection(experiences: const [], onChanged: (_) {}),
      ));
      expect(find.text('Ajouter une expérience'), findsOneWidget);
    });

    testWidgets('ouvre la bottom sheet au tap sur Ajouter', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_wrap(
        ExperienceSection(experiences: const [], onChanged: (_) {}),
      ));
      await tester.tap(find.text('Ajouter une expérience'));
      await tester.pumpAndSettle();
      expect(find.text('Ajouter une expérience'), findsWidgets);
      expect(find.text('Intitulé du poste *'), findsOneWidget);
    });

    testWidgets('le bouton "Suggestions IA" apparaît dans la sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_wrap(
        ExperienceSection(experiences: const [], onChanged: (_) {}),
      ));
      await tester.tap(find.text('Ajouter une expérience'));
      await tester.pumpAndSettle();
      expect(find.text('Suggestions IA'), findsOneWidget);
    });

    testWidgets('supprime une expérience via onDelete', (tester) async {
      final List<Experience> updated = [];
      await tester.pumpWidget(_wrap(
        ExperienceSection(
          experiences: _fakeExperiences(),
          onChanged: (list) => updated.addAll(list),
        ),
      ));
      // Tap delete on first item
      final deleteIcons = find.byIcon(Icons.delete_outline);
      await tester.tap(deleteIcons.first);
      await tester.pump();
      expect(updated.length, 1);
      expect(updated.first.poste, 'Stagiaire');
    });

    testWidgets('ouvre la sheet en mode édition avec données pré-remplies', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_wrap(
        ExperienceSection(experiences: _fakeExperiences(), onChanged: (_) {}),
      ));
      final editIcons = find.byIcon(Icons.edit_outlined);
      await tester.tap(editIcons.first);
      await tester.pumpAndSettle();
      expect(find.text('Modifier l\'expérience'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Développeur Flutter'), findsOneWidget);
    });
  });

  group('showSuggestionsSheet', () {
    testWidgets('affiche les suggestions dans la sheet', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showSuggestionsSheet(
                ctx,
                ['Développé une API REST', 'Réduit le temps de réponse de 30%'],
                ctrl,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('• Développé une API REST'), findsOneWidget);
      expect(find.text('• Réduit le temps de réponse de 30%'), findsOneWidget);
    });

    testWidgets('tap sur suggestion l\'ajoute au controller et ferme la sheet', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showSuggestionsSheet(ctx, ['Optimisé les performances'], ctrl),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('• Optimisé les performances'));
      await tester.pumpAndSettle();
      expect(ctrl.text, '• Optimisé les performances');
      // sheet should be dismissed
      expect(find.text('• Optimisé les performances'), findsNothing);
    });

    testWidgets('ajoute sur une nouvelle ligne si description non vide', (tester) async {
      final ctrl = TextEditingController(text: 'Première ligne');
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showSuggestionsSheet(ctx, ['Deuxième point'], ctrl),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('• Deuxième point'));
      await tester.pumpAndSettle();
      expect(ctrl.text, 'Première ligne\n• Deuxième point');
    });
  });

  group('AiSuggestButton via use case (issue #332)', () {
    Future<void> openEditorAndTapAi(
      WidgetTester tester,
      SuggestBulletsUseCase useCase,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(ExperienceSection(
        experiences: const [],
        onChanged: (_) {},
        suggestBullets: useCase,
      )));
      await tester.tap(find.text('Ajouter une expérience'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(find.text('Suggestions IA'));
      await tester.tap(find.text('Suggestions IA'));
    }

    testWidgets('succès : la section délègue au use case et affiche la sheet',
        (tester) async {
      final repo = _MockAiRepository();
      when(() => repo.getSuggestions(
            poste: any(named: 'poste'),
            entreprise: any(named: 'entreprise'),
            description: any(named: 'description'),
            consentAccepted: any(named: 'consentAccepted'),
          )).thenAnswer(
        (_) async => const Result.success(['Piloté une migration cloud']),
      );

      await openEditorAndTapAi(tester, SuggestBulletsUseCase(repo));
      // Pas de pumpAndSettle : le bouton reste en loading (spinner) tant que la
      // sheet de suggestions est ouverte -> on avance par pas explicites.
      await tester.pump(); // resout le future du use case
      await tester.pump(const Duration(milliseconds: 400)); // ouvre la sheet

      expect(find.text('• Piloté une migration cloud'), findsOneWidget);
      verify(() => repo.getSuggestions(
            poste: any(named: 'poste'),
            entreprise: any(named: 'entreprise'),
            description: any(named: 'description'),
            consentAccepted: true,
          )).called(1);
    });

    testWidgets('échec : affiche un snackbar et ne plante pas', (tester) async {
      final repo = _MockAiRepository();
      when(() => repo.getSuggestions(
            poste: any(named: 'poste'),
            entreprise: any(named: 'entreprise'),
            description: any(named: 'description'),
            consentAccepted: any(named: 'consentAccepted'),
          )).thenAnswer((_) async => const Result.failure(NetworkException()));

      await openEditorAndTapAi(tester, SuggestBulletsUseCase(repo));
      await tester.pump(); // microtache du use case
      await tester.pump(const Duration(milliseconds: 300)); // entree snackbar

      expect(find.byType(SnackBar), findsOneWidget);
      // Aucune sheet de suggestions n'a ete ouverte.
      expect(find.textContaining('• '), findsNothing);

      // Laisse le timer d'auto-dismiss du SnackBar s'ecouler (evite un
      // "pending timer" en fin de test).
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}
