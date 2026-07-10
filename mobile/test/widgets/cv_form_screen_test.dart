import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:cv_mobile/providers/cv_provider.dart';
import 'package:cv_mobile/screens/cv/cv_form_screen.dart';

class MockCvProvider extends Mock implements CvProvider {}

void _setMobileViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
}

Widget _buildSubject(CvProvider cvProvider) {
  final router = GoRouter(
    initialLocation: '/cvs/create',
    routes: [
      GoRoute(
        path: '/cvs/create',
        builder: (context, state) => ChangeNotifierProvider<CvProvider>.value(
          value: cvProvider,
          child: const CvFormScreen(),
        ),
      ),
    ],
  );

  return MaterialApp.router(
    theme: ThemeData(useMaterial3: true),
    routerConfig: router,
  );
}

void main() {
  testWidgets('CvFormScreen mobile affiche la premiere etape sans exception',
      (tester) async {
    _setMobileViewport(tester);
    addTearDown(tester.view.resetPhysicalSize);

    final cvProvider = MockCvProvider();
    when(() => cvProvider.addListener(any())).thenReturn(null);
    when(() => cvProvider.removeListener(any())).thenReturn(null);

    await tester.pumpWidget(_buildSubject(cvProvider));
    await tester.pumpAndSettle();

    expect(find.text('Nouveau CV'), findsOneWidget);
    expect(find.text('Identite'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
