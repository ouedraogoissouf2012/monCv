import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/screens/cv/sections/experience_section.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

List<Experience> _fakeExperiences() => [
      Experience(
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
}
