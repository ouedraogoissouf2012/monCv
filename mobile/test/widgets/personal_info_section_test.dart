import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/screens/cv/sections/personal_info_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(PersonalInfoSection section) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: section),
      ),
    );

void main() {
  testWidgets('la ville propose Abidjan selon le pays', (tester) async {
    PersonalInfo? latest;
    await tester.pumpWidget(_wrap(PersonalInfoSection(
      personalInfo: PersonalInfo(pays: "Côte d'Ivoire"),
      onChanged: (value) => latest = value,
    )));

    await tester.enterText(find.byKey(const Key('city-field')), 'abi');
    await tester.pumpAndSettle();

    expect(find.text('Abidjan'), findsOneWidget);
    await tester.tap(find.text('Abidjan'));
    await tester.pumpAndSettle();

    expect(latest?.ville, 'Abidjan');
  });

  testWidgets('la ville reste libre pour un pays non couvert', (tester) async {
    PersonalInfo? latest;
    await tester.pumpWidget(_wrap(PersonalInfoSection(
      personalInfo: PersonalInfo(pays: 'Japon'),
      onChanged: (value) => latest = value,
    )));

    await tester.enterText(find.byKey(const Key('city-field')), 'Tokyo');
    await tester.pump();

    expect(latest?.ville, 'Tokyo');
  });
}
