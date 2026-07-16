import 'package:cv_mobile/widgets/public_qr_code.dart';
import 'package:cv_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('affiche un QR code et son action de telechargement',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('fr'),
        home: Scaffold(
          body: PublicQrCode(
            url: 'https://moncv.example/#/public/cv/abc123',
          ),
        ),
      ),
    );

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Télécharger le QR code'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
