import 'dart:ui';

import 'package:cv_mobile/features/cv/data/mappers/cv_mapper.dart';
import 'package:cv_mobile/features/cv/presentation/cv_presentation_model.dart';
import 'package:cv_mobile/models/cv_style.dart';
import 'package:flutter_test/flutter_test.dart';

/// La (de)serialisation du style vit desormais dans `CvMapper` (couche data).
/// Ces tests verifient le round-trip du style visuel a travers le format
/// reseau et la conversion `CvStyle <-> CvStyleRef` du modele de presentation.
void main() {
  const mapper = CvMapper();

  group('Cv style — serialisation reseau', () {
    test('toNetworkJson inclut le style visuel (int ARGB)', () {
      const style = CvStyle(
        templateId: 'classique',
        primaryColor: Color(0xFF10B981),
        fontFamily: 'Lato',
      );
      final cv = Cv(id: 1, titre: 'CV test', style: style);

      final json = mapper.toNetworkJson(cv.entity);

      expect(json['style'], {
        'templateId': 'classique',
        'primaryColor': 0xFF10B981,
        'fontFamily': 'Lato',
      });
    });

    test('fromNetworkJson restaure le style visuel', () {
      final cv = Cv.fromEntity(mapper.fromNetworkJson({
        'id': 1,
        'titre': 'CV test',
        'style': {
          'templateId': 'classique',
          'primaryColor': 0xFF10B981,
          'fontFamily': 'Lato',
        },
      }));

      expect(cv.style.templateId, 'classique');
      expect(cv.style.primaryColor.toARGB32(), 0xFF10B981);
      expect(cv.style.fontFamily, 'Lato');
    });
  });
}
