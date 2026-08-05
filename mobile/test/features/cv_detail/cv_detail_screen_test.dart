import 'package:cv_mobile/features/cv_detail/presentation/components/cv_detail_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifie que la barre d'actions du detail reflete l'etat d'export et rend une
/// seule action par commande (issue #247, B4b). Le comportement des exports est
/// couvert par les tests de CvDetailController (B3).
void main() {
  CvDetailAppBar bar({bool pdf = false, bool docx = false}) => CvDetailAppBar(
        title: 'Mon CV',
        exportingPdf: pdf,
        exportingDocx: docx,
        tooltips: const CvDetailTooltips(
          proofread: 'p',
          enhance: 'e',
          adaptToJob: 'a',
          customize: 'c',
          downloadPdf: 'pdf',
          downloadDocx: 'docx',
          edit: 'ed',
        ),
        onBack: () {},
        onProofread: () {},
        onEnhance: () {},
        onAdaptToJob: () {},
        onCustomize: () {},
        onExportPdf: () {},
        onExportDocx: () {},
        onEdit: () {},
      );

  Widget host(CvDetailAppBar appBar) =>
      MaterialApp(home: Scaffold(appBar: appBar));

  testWidgets('etat repos : le titre et les actions sont affiches', (t) async {
    await t.pumpWidget(host(bar()));
    expect(find.text('Mon CV'), findsOneWidget);
    // Icones d'export presentes (pas de spinner au repos).
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('export PDF en cours : spinner a la place de l icone PDF',
      (t) async {
    await t.pumpWidget(host(bar(pdf: true)));
    // L'icone PDF est remplacee par un spinner ; l'icone DOCX reste.
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
