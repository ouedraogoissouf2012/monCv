import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cv_mobile/providers/theme_provider.dart';
import 'package:cv_mobile/widgets/theme_selector.dart';

void main() {
  group('ThemeSelector', () {
    testWidgets('affiche les 3 labels de thèmes (Minimal, Vibrant, Premium)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
              child: const ThemeSelector(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Minimal'), findsOneWidget);
      expect(find.text('Vibrant'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
    });
  });
}
