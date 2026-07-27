import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_mobile/core/design_system/tokens/app_typography.dart';

/// Preuve que les polices de l'app sont reellement embarquees et chargeables
/// par le moteur Flutter (issue #233 : "resolues de facon deterministe;
/// aucun ecran n'appelle GoogleFonts"). Detecte un `.ttf` corrompu ou absent —
/// ce qu'un simple test de couleur ne verrait pas.
///
/// La liste des assets est verrouillee ici et doit rester synchrone avec la
/// section `flutter > fonts` de `pubspec.yaml`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const bodyAssets = <String>[
    'assets/fonts/Poppins-Light.ttf',
    'assets/fonts/Poppins-Regular.ttf',
    'assets/fonts/Poppins-Medium.ttf',
    'assets/fonts/Poppins-SemiBold.ttf',
    'assets/fonts/Poppins-Bold.ttf',
  ];
  const displayAssets = <String>[
    'assets/fonts/PlayfairDisplay-VariableFont_wght.ttf',
  ];

  Future<void> loadFamily(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final path in assets) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'police absente: $path');
      loader.addFont(
        file.readAsBytes().then((b) => ByteData.view(b.buffer)),
      );
    }
    // Echoue si un .ttf est invalide / illisible par le moteur.
    await loader.load();
  }

  test('embedded body font family loads', () async {
    await loadFamily(AppTypography.fontFamilyBody, bodyAssets);
  });

  test('embedded display font family loads', () async {
    await loadFamily(AppTypography.fontFamilyDisplay, displayAssets);
  });

  testWidgets('display family renders across weights without fallback error',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              for (final w in [FontWeight.w400, FontWeight.w500, FontWeight.w600])
                Text('MonCV',
                    style: AppTypography.display(fontSize: 24, fontWeight: w)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('MonCV'), findsNWidgets(3));
  });
}
