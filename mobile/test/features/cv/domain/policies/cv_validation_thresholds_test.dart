import 'package:cv_mobile/features/cv/domain/policies/cv_validation_thresholds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CvValidationThresholds - seuils nommes (#241, C5 de #238)', () {
    test('seuils de score regroupes, plus de magic numbers disperses', () {
      expect(CvValidationThresholds.maxScore, 100);
      expect(CvValidationThresholds.errorPenalty, 15);
      expect(CvValidationThresholds.warningPenalty, 5);
      expect(CvValidationThresholds.exportThreshold, 60);
    });

    test('seuils de qualite par regle (#241) centralises', () {
      expect(CvValidationThresholds.minSummaryLength, 100);
      expect(CvValidationThresholds.recommendedSkillCount, 5);
      expect(CvValidationThresholds.minProjectDescriptionLength, 30);
      expect(CvValidationThresholds.maxItemsBeforeOverflow, 25);
      expect(CvValidationThresholds.minSkillLevel, 1);
      expect(CvValidationThresholds.maxSkillLevel, 5);
      expect(CvValidationThresholds.futureDateToleranceDays, 30);
    });
  });
}
