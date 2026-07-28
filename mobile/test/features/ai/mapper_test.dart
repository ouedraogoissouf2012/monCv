import 'package:cv_mobile/features/ai/data/dto/application_messages_dto.dart';
import 'package:cv_mobile/features/ai/data/dto/enhanced_cv_dto.dart';
import 'package:cv_mobile/features/ai/data/dto/job_match_dto.dart';
import 'package:cv_mobile/features/ai/data/mapper/application_messages_mapper.dart';
import 'package:cv_mobile/features/ai/data/mapper/enhanced_cv_mapper.dart';
import 'package:cv_mobile/features/ai/data/mapper/job_match_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/ai_fixtures.dart';

/// Couverture directe des DTO (fromJson defensif) et des mappers (DTO -> domaine).
void main() {
  group('EnhancedCvDto.fromJson', () {
    test('decode le payload complet', () {
      final dto = EnhancedCvDto.fromJson(enhanceCvResponseJson);
      expect(dto.titrePoste, 'Developpeur Flutter');
      expect(dto.experiences, hasLength(1));
      expect(dto.skills.single.niveau, 5);
      expect(dto.correctionCount, 3);
    });

    test('tolere les listes absentes ou malformees', () {
      final dto = EnhancedCvDto.fromJson({'experiences': 'pas une liste'});
      expect(dto.experiences, isEmpty);
      expect(dto.aiGenerated, isFalse);
      expect(dto.correctionCount, 0);
    });

    test('ignore les elements non-Map d une liste', () {
      final dto = EnhancedCvDto.fromJson({
        'skills': [
          {'nom': 'Dart'},
          'bruit',
          42,
        ],
      });
      expect(dto.skills, hasLength(1));
      expect(dto.skills.single.nom, 'Dart');
    });
  });

  test('EnhancedCvMapper preserve tous les champs imbriques', () {
    final cv = EnhancedCvMapper.fromDto(
      EnhancedCvDto.fromJson(enhanceCvResponseJson),
    );
    expect(cv.educations.single.diplome, 'Master');
    expect(cv.languages.single.langue, 'Anglais');
    expect(cv.certifications.single.nom, 'AWS');
    expect(cv.projects.single.technologies, 'Flutter');
    expect(cv.warnings, ['Verifier les dates']);
  });

  test('JobMatchMapper preserve categories et checks', () {
    final match = JobMatchMapper.fromDto(
      JobMatchDto.fromJson(jobMatchResponseJson),
    );
    expect(match.score, 82);
    expect(match.categories.single.summary, 'Bon match');
    expect(match.prioritizedRecommendations.single.title, 'Mots-cles');
    expect(match.formatChecks.single.detail, 'CV trop long');
  });

  test('ApplicationMessagesMapper mappe les 4 canaux + tone', () {
    final messages = ApplicationMessagesMapper.fromDto(
      ApplicationMessagesDto.fromJson(applicationMessagesResponseJson),
    );
    expect(messages.coverLetter, 'Lettre de motivation.');
    expect(messages.whatsApp, 'Message WhatsApp.');
    expect(messages.tone, 'FORMAL');
  });
}
