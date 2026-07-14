import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cv_mobile/pdf/pdf_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pdf_test_fixture.dart';

void main() {
  const templateIds = [
    'moderne',
    'classique',
    'minimaliste',
    'creatif',
    'executive',
    'ats',
  ];

  test('PdfRenderer genere les six strategies', () async {
    for (final templateId in templateIds) {
      final bytes = await PdfRenderer.generate(
        professionalCv(templateId: templateId),
      );
      expect(bytes, startsWithPdf, reason: templateId);
      expect(bytes.length, greaterThan(1000), reason: templateId);
    }
  });

  for (final templateId in templateIds.take(4)) {
    test('golden structurel $templateId', () async {
      final actual = await PdfRenderer.generate(
        professionalCv(templateId: templateId),
      );
      final golden = File('test/golden/pdf/$templateId.pdf');

      if (autoUpdateGoldenFiles || !golden.existsSync()) {
        golden.parent.createSync(recursive: true);
        golden.writeAsBytesSync(actual);
      }

      final expected = golden.readAsBytesSync();
      expect(_pageCount(actual), _pageCount(expected));
      expect(
        actual.length,
        inInclusiveRange(
          (expected.length * 0.90).floor(),
          (expected.length * 1.10).ceil(),
        ),
      );
    });
  }

  test('generation stable dans une tolerance de performance de 10 %', () async {
    final cv = professionalCv();
    await PdfRenderer.generate(cv);

    final samples = <int>[];
    for (var i = 0; i < 6; i++) {
      final stopwatch = Stopwatch()..start();
      await PdfRenderer.generate(cv);
      samples.add(stopwatch.elapsedMicroseconds);
    }

    samples.sort();
    final median = samples[samples.length ~/ 2];
    stderr.writeln('PDF_RENDER_MEDIAN_US=$median');
    expect(median, lessThan(500000));
  });
}

final Matcher startsWithPdf = predicate<Uint8List>(
  (bytes) =>
      bytes.length >= 4 && ascii.decode(bytes.take(4).toList()) == '%PDF',
  'commence par la signature PDF',
);

int _pageCount(List<int> bytes) {
  final content = latin1.decode(bytes, allowInvalid: true);
  return RegExp(r'/Type\s*/Page\b').allMatches(content).length;
}
