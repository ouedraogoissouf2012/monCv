import 'package:cv_mobile/features/ai/application/get_ai_status_usecase.dart';
import 'package:cv_mobile/providers/ai_status_provider.dart';
import 'package:cv_mobile/widgets/ai_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetAiStatus extends Mock implements GetAiStatusUseCase {}

void main() {
  testWidgets('bouton desactive avec tooltip si IA indisponible', (
    tester,
  ) async {
    final provider = AiStatusProvider(
      getAiStatus: _MockGetAiStatus(),
      initialStatus: const AiStatus(
        available: false,
        primaryStatus: 'KEY_INVALID',
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: AiButton(
              onPressed: () {},
              icon: const Icon(Icons.auto_awesome),
              label: 'Ameliorer',
            ),
          ),
        ),
      ),
    );

    final filledButton =
        find.byWidgetPredicate((widget) => widget is FilledButton);
    final button = tester.widget<FilledButton>(filledButton);
    expect(button.onPressed, isNull);

    await tester.longPress(find.byType(Tooltip));
    await tester.pumpAndSettle();
    expect(find.text('Service IA mal configure'), findsOneWidget);
  });
}
