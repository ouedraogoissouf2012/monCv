import 'package:cv_mobile/features/cv_style/presentation/components/cv_style_options_pane.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:cv_mobile/models/cv_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifie la stabilite STRUCTURELLE de l'editeur de style (issue #247, B4a).
///
/// Remplace un golden pixel-perfect (fragile cross-plateforme : le projet n'a
/// aucun golden widget existant, et un ecart de police Windows/Linux CI casserait
/// le check). On verifie que les 3 familles d'options sont rendues et que la
/// selection remonte le bon CvStyle — ce qui capture les vraies regressions
/// fonctionnelles.
void main() {
  Widget host(CvStyle style, void Function(CvStyle) onSelect) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
            body: CvStyleOptionsPane(style: style, onSelect: onSelect)),
      );

  // Une grande vue partagee : la section police est en bas d'un ListView
  // scrollable, il faut de la hauteur pour la rendre. On reinitialise en fin de
  // CHAQUE test pour eviter toute fuite d'etat de vue entre tests.
  void useTallView(WidgetTester t) {
    t.view.physicalSize = const Size(500, 1600);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });
  }

  testWidgets('affiche les sections template / couleur / police', (t) async {
    useTallView(t);
    await t.pumpWidget(host(const CvStyle(), (_) {}));
    await t.pump();
    final l = AppLocalizations.of(t.element(find.byType(CvStyleOptionsPane)))!;
    expect(find.text(l.template), findsOneWidget);
    expect(find.text(l.color), findsOneWidget);
    expect(find.text(l.font), findsOneWidget);
    // Au moins un template et une police rendus.
    expect(find.text(CvStyle.templates.first.label), findsOneWidget);
    expect(find.text(CvStyle.fontFamilies.first), findsWidgets);
  });

  testWidgets('selectionner un template remonte le nouveau style', (t) async {
    useTallView(t);
    CvStyle? selected;
    await t.pumpWidget(
        host(const CvStyle(templateId: 'moderne'), (s) => selected = s));
    await t.pump();

    final other = CvStyle.templates.firstWhere((x) => x.id != 'moderne');
    await t.ensureVisible(find.text(other.label));
    await t.tap(find.text(other.label));
    await t.pump();

    expect(selected?.templateId, other.id);
  });

  testWidgets('selectionner une police remonte le nouveau style', (t) async {
    useTallView(t);
    CvStyle? selected;
    const fonts = CvStyle.fontFamilies;
    await t.pumpWidget(
        host(CvStyle(fontFamily: fonts.first), (s) => selected = s));
    await t.pump();

    await t.ensureVisible(find.text(fonts[1]));
    await t.tap(find.text(fonts[1]));
    await t.pump();

    expect(selected?.fontFamily, fonts[1]);
  });
}
