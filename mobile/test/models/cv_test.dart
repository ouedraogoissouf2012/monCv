import 'dart:ui';

import 'package:cv_mobile/models/cv.dart';
import 'package:cv_mobile/models/cv_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cv style JSON', () {
    test('toJson inclut le style visuel', () {
      const style = CvStyle(
        templateId: 'classique',
        primaryColor: Color(0xFF10B981),
        fontFamily: 'Lato',
      );
      final cv = Cv(id: 1, titre: 'CV test', style: style);

      final json = cv.toJson();

      expect(json['style'], {
        'templateId': 'classique',
        'primaryColor': 0xFF10B981,
        'fontFamily': 'Lato',
      });
    });

    test('fromJson restaure le style visuel', () {
      final cv = Cv.fromJson({
        'id': 1,
        'titre': 'CV test',
        'style': {
          'templateId': 'classique',
          'primaryColor': 0xFF10B981,
          'fontFamily': 'Lato',
        },
      });

      expect(cv.style.templateId, 'classique');
      expect(cv.style.primaryColor.toARGB32(), 0xFF10B981);
      expect(cv.style.fontFamily, 'Lato');
    });
  });
}
