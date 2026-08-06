import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/core/design_system/tokens/app_spacing.dart';
import 'package:cv_mobile/features/landing/presentation/components/landing_section.dart';
import 'package:cv_mobile/features/landing/presentation/components/landing_section_header.dart';
import 'package:cv_mobile/features/landing/presentation/landing_metrics.dart';

Future<void> _pump(WidgetTester tester, Widget child, {required double width}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

EdgeInsets _sectionPadding(WidgetTester tester) {
  final container = tester.widget<Container>(find.descendant(
    of: find.byType(LandingSection),
    matching: find.byType(Container),
  ));
  return container.padding! as EdgeInsets;
}

void main() {
  group('LandingSection (#251)', () {
    testWidgets('desktop (>=800) : gouttiere large', (tester) async {
      await _pump(tester, const LandingSection(child: Text('c')), width: 1000);

      final padding = _sectionPadding(tester);
      expect(padding.left, AppSpacing.gutterWide);
      expect(padding.top, LandingMetrics.sectionVerticalPadding);
      expect(find.text('c'), findsOneWidget);
    });

    testWidgets('mobile (<800) : gouttiere etroite', (tester) async {
      await _pump(tester, const LandingSection(child: Text('c')), width: 400);

      expect(_sectionPadding(tester).left, AppSpacing.xxl);
    });

    testWidgets('horizontalPadding fixe ignore le breakpoint', (tester) async {
      await _pump(
        tester,
        const LandingSection(
            horizontalPadding: AppSpacing.xxl, child: Text('c')),
        width: 1400,
      );

      // Meme sur tres large, la gouttiere reste la valeur fixe fournie.
      expect(_sectionPadding(tester).left, AppSpacing.xxl);
    });

    testWidgets('applique la couleur de fond fournie', (tester) async {
      await _pump(
        tester,
        const LandingSection(background: Color(0xFF123456), child: Text('c')),
        width: 400,
      );

      final container = tester.widget<Container>(find.descendant(
        of: find.byType(LandingSection),
        matching: find.byType(Container),
      ));
      expect(container.color, const Color(0xFF123456));
    });
  });

  group('LandingSectionHeader (#251)', () {
    testWidgets('affiche titre seul quand pas de sous-titre', (tester) async {
      await _pump(tester, const LandingSectionHeader(title: 'Titre'), width: 800);

      expect(find.text('Titre'), findsOneWidget);
      // Un seul Text (pas de sous-titre).
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('affiche titre + sous-titre', (tester) async {
      await _pump(
        tester,
        const LandingSectionHeader(title: 'Titre', subtitle: 'Sous-titre'),
        width: 800,
      );

      expect(find.text('Titre'), findsOneWidget);
      expect(find.text('Sous-titre'), findsOneWidget);
    });

    testWidgets('onColor : titre blanc', (tester) async {
      await _pump(
        tester,
        const LandingSectionHeader(title: 'Titre', onColor: true),
        width: 800,
      );

      final title = tester.widget<Text>(find.text('Titre'));
      expect(title.style?.color, Colors.white);
    });
  });

  group('LandingMetrics.isWide (#251)', () {
    testWidgets('vrai a 800, faux en dessous', (tester) async {
      bool? at800;
      bool? at799;
      await _pump(
        tester,
        Builder(builder: (context) {
          at800 = LandingMetrics.isWide(context);
          return const SizedBox();
        }),
        width: 800,
      );
      await _pump(
        tester,
        Builder(builder: (context) {
          at799 = LandingMetrics.isWide(context);
          return const SizedBox();
        }),
        width: 799,
      );

      expect(at800, isTrue);
      expect(at799, isFalse);
    });
  });
}
