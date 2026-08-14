import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/core/design_system/theme/app_theme_factory.dart';
import 'package:cv_mobile/core/design_system/theme/app_theme_modes.dart';
import 'package:cv_mobile/features/settings/presentation/components/destructive_action_tile.dart';
import 'package:cv_mobile/features/settings/presentation/components/settings_section.dart';
import 'package:cv_mobile/features/settings/presentation/components/settings_tile.dart';

/// Spec de theme reelle : enregistre l'extension AppColorTokens (token danger).
const _spec = AppThemeModes.minimal;

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: AppThemeFactory.build(_spec),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  group('SettingsSection (#250)', () {
    testWidgets('affiche le titre et son contenu', (tester) async {
      await _pump(
        tester,
        const SettingsSection(
          title: 'Apparence',
          child: Text('contenu-section'),
        ),
      );

      expect(find.text('Apparence'), findsOneWidget);
      expect(find.text('contenu-section'), findsOneWidget);
    });
  });

  group('SettingsCard (#250)', () {
    testWidgets('intercale N-1 filets entre N tuiles', (tester) async {
      await _pump(
        tester,
        const SettingsCard(children: [
          Text('a'),
          Text('b'),
          Text('c'),
        ]),
      );

      expect(find.byType(Divider), findsNWidgets(2));
      expect(find.text('a'), findsOneWidget);
      expect(find.text('c'), findsOneWidget);
    });

    testWidgets('aucun filet pour une seule tuile', (tester) async {
      await _pump(
        tester,
        const SettingsCard(children: [Text('seule')]),
      );

      expect(find.byType(Divider), findsNothing);
    });
  });

  group('SettingsTile action (#250)', () {
    testWidgets('affiche titre + sous-titre + chevron et declenche onTap',
        (tester) async {
      var tapped = 0;
      await _pump(
        tester,
        SettingsTile(
          icon: Icons.file_download_outlined,
          title: 'Exporter mes donnees',
          subtitle: 'Copier au format JSON',
          onTap: () => tapped++,
        ),
      );

      expect(find.text('Exporter mes donnees'), findsOneWidget);
      expect(find.text('Copier au format JSON'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.tap(find.text('Exporter mes donnees'));
      expect(tapped, 1);
    });

    testWidgets('sans onTap : pas de chevron ni de zone tappable',
        (tester) async {
      await _pump(
        tester,
        const SettingsTile(icon: Icons.info_outline, title: 'Lecture seule'),
      );

      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('SettingsTile.info (#250)', () {
    testWidgets('affiche libelle et valeur, sans chevron', (tester) async {
      await _pump(
        tester,
        const SettingsTile.info(
          icon: Icons.person_outline,
          label: 'Nom complet',
          value: 'John Doe',
        ),
      );

      expect(find.text('Nom complet'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });
  });

  group('DestructiveActionTile (#250)', () {
    testWidgets('utilise le token danger et non une couleur codee en dur',
        (tester) async {
      await _pump(
        tester,
        DestructiveActionTile(
          icon: Icons.delete_forever_outlined,
          title: 'Supprimer mon compte',
          subtitle: 'Action irreversible',
          onTap: () {},
        ),
      );

      final leadingIcon = tester.widget<Icon>(
        find.byIcon(Icons.delete_forever_outlined),
      );
      expect(leadingIcon.color, _spec.colorTokens.danger);
      // Le rouge Material brut ne doit jamais servir de couleur destructrice.
      expect(leadingIcon.color, isNot(Colors.red));
    });

    testWidgets('expose un role bouton accessible et declenche onTap',
        (tester) async {
      var tapped = 0;
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        DestructiveActionTile(
          icon: Icons.delete_forever_outlined,
          title: 'Supprimer mon compte',
          onTap: () => tapped++,
        ),
      );

      // containsSemantics (et non matchesSemantics) : verification PARTIELLE du
      // role bouton + label, sans exiger l'absence des actions tap/focus reelles
      // du bouton (matchesSemantics est strict et echouerait sur ces actions).
      expect(
        tester.getSemantics(find.byType(DestructiveActionTile)),
        containsSemantics(isButton: true, label: 'Supprimer mon compte'),
      );

      await tester.tap(find.text('Supprimer mon compte'));
      expect(tapped, 1);
      handle.dispose();
    });
  });
}
