import 'dart:io';

import 'package:cv_mobile/features/cv/domain/value_objects/cv_style_ref.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CvStyleRef', () {
    test('valeurs par defaut alignees sur le style historique', () {
      const style = CvStyleRef();
      expect(style.templateId, 'moderne');
      expect(style.fontFamily, 'Roboto');
      expect(style.primaryColorArgb, 0xFF2563EB);
    });

    test('fallback est le style par defaut', () {
      expect(CvStyleRef.fallback, const CvStyleRef());
    });

    test('egalite structurelle sur les trois champs', () {
      const a = CvStyleRef(
        templateId: 'ats',
        fontFamily: 'Lato',
        primaryColorArgb: 0xFF10B981,
      );
      const b = CvStyleRef(
        templateId: 'ats',
        fontFamily: 'Lato',
        primaryColorArgb: 0xFF10B981,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('une difference de couleur casse l egalite', () {
      expect(
        const CvStyleRef(primaryColorArgb: 0xFF000000) ==
            const CvStyleRef(primaryColorArgb: 0xFFFFFFFF),
        isFalse,
      );
    });

    group('copyWith', () {
      test('conserve les champs non passes', () {
        const base = CvStyleRef(
          templateId: 'creatif',
          fontFamily: 'Poppins',
          primaryColorArgb: 0xFFEC4899,
        );
        final copy = base.copyWith(templateId: 'ats');
        expect(copy.templateId, 'ats');
        expect(copy.fontFamily, 'Poppins');
        expect(copy.primaryColorArgb, 0xFFEC4899);
      });

      test('remplace chaque champ passe', () {
        final copy = const CvStyleRef().copyWith(
          templateId: 'executive',
          fontFamily: 'Merriweather',
          primaryColorArgb: 0xFF111827,
        );
        expect(copy.templateId, 'executive');
        expect(copy.fontFamily, 'Merriweather');
        expect(copy.primaryColorArgb, 0xFF111827);
      });
    });

    test('toString expose les trois champs pour le debug', () {
      const style = CvStyleRef(
        templateId: 'ats',
        fontFamily: 'Lato',
        primaryColorArgb: 0xFF10B981,
      );
      final text = style.toString();
      expect(text, contains('ats'));
      expect(text, contains('Lato'));
    });

    test('purete : le domaine n importe ni dart:ui ni Flutter', () {
      // Garde-fou ADR 002 : domain/ ne doit pas dependre de Flutter/dart:ui.
      // Le guard CI (flutter_import_guard) ne scanne pas features/, on verifie
      // donc la purete ici, directement sur le source du value object.
      final source = File(
        'lib/features/cv/domain/value_objects/cv_style_ref.dart',
      ).readAsStringSync();
      expect(source.contains("import 'dart:ui'"), isFalse);
      expect(source.contains('package:flutter/'), isFalse);
    });
  });
}
