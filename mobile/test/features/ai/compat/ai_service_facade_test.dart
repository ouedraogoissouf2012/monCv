// La facade est @Deprecated par conception (transitoire #245) mais reste
// testee tant qu'elle est en production.
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:cv_mobile/features/ai/compat/ai_service_facade.dart';
import 'package:cv_mobile/features/ai/data/ai_remote_data_source.dart';
import 'package:cv_mobile/features/ai/domain/entities/application_messages.dart';
import 'package:cv_mobile/features/ai/domain/entities/enhanced_cv.dart';
import 'package:cv_mobile/features/ai/domain/entities/job_match.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements AiRemoteDataSource {}

/// Verifie que la facade delegue au data source ET reconvertit les entités
/// typees en Map a la forme backend (via toLegacyMap) pour les widgets #245.
void main() {
  late _MockDataSource ds;
  late AiCvService facade;

  setUp(() {
    ds = _MockDataSource();
    facade = AiCvService(ds);
  });

  test('enhanceCv reconvertit EnhancedCv en Map backend (toutes sections)',
      () async {
    when(() => ds.enhanceCv(1, 'MAX')).thenAnswer(
      (_) async => const EnhancedCv(
        titrePoste: 'Dev',
        resumeProfessionnel: 'resume',
        titreOffre: 'Lead Mobile',
        aiGenerated: true,
        correctionCount: 2,
        experiences: [EnhancedExperience(id: 3, poste: 'Lead')],
        educations: [EnhancedEducation(id: 4, diplome: 'Master')],
        skills: [EnhancedSkill(nom: 'Dart', niveau: 5)],
        languages: [EnhancedLanguage(id: 6, langue: 'Anglais')],
        certifications: [EnhancedCertification(id: 7, nom: 'AWS')],
        projects: [EnhancedProject(id: 8, nom: 'MonCV', technologies: 'Flutter')],
        warnings: ['w1'],
        level: 'MAX',
      ),
    );

    final map = await facade.enhanceCv(1, 'MAX');

    expect(map['titrePoste'], 'Dev');
    expect(map['resumeProfessionnel'], 'resume');
    expect(map['titreOffre'], 'Lead Mobile');
    expect(map['aiGenerated'], true);
    expect(map['correctionCount'], 2);
    expect((map['experiences'] as List).single['poste'], 'Lead');
    expect((map['educations'] as List).single['diplome'], 'Master');
    expect((map['skills'] as List).single['niveau'], 5);
    expect((map['languages'] as List).single['langue'], 'Anglais');
    expect((map['certifications'] as List).single['nom'], 'AWS');
    expect((map['projects'] as List).single['technologies'], 'Flutter');
    expect(map['warnings'], ['w1']);
    expect(map['level'], 'MAX');
  });

  test('enhanceCv sans sous-listes -> Map avec listes vides (null-safe)',
      () async {
    when(() => ds.enhanceCv(1, 'LITE'))
        .thenAnswer((_) async => const EnhancedCv(aiGenerated: true));

    final map = await facade.enhanceCv(1, 'LITE');

    expect(map['experiences'], isEmpty);
    expect(map['educations'], isEmpty);
    expect(map['skills'], isEmpty);
    expect(map['warnings'], isEmpty);
    expect(map['aiGenerated'], true);
  });

  test('matchJob reconvertit JobMatch en Map backend', () async {
    when(() => ds.matchJob(2, 'Offre')).thenAnswer(
      (_) async => const JobMatch(
        score: 88,
        matchedKeywords: ['Flutter'],
        categories: [
          MatchCategory(label: 'Skills', score: 90, evidence: ['Dart']),
        ],
        prioritizedRecommendations: [
          PrioritizedRecommendation(priority: 1, title: 'T', keywords: ['k']),
        ],
        formatChecks: [FormatCheck(severity: 'WARN', label: 'L', detail: 'D')],
        optimizedResume: 'opt',
      ),
    );

    final map = await facade.matchJob(2, 'Offre');

    expect(map['score'], 88);
    expect(map['matchedKeywords'], ['Flutter']);
    expect((map['categories'] as List).single['label'], 'Skills');
    expect(
      (map['prioritizedRecommendations'] as List).single['priority'],
      1,
    );
    expect((map['formatChecks'] as List).single['severity'], 'WARN');
    expect(map['optimizedResume'], 'opt');
  });

  test('generateApplicationMessages reconvertit en Map 4 canaux', () async {
    when(() => ds.generateApplicationMessages(3, 'Offre', 'FORMAL')).thenAnswer(
      (_) async => const ApplicationMessages(
        coverLetter: 'lettre',
        email: 'email',
        linkedIn: 'li',
        whatsApp: 'wa',
        tone: 'FORMAL',
      ),
    );

    final map = await facade.generateApplicationMessages(3, 'Offre', 'FORMAL');

    expect(map['coverLetter'], 'lettre');
    expect(map['email'], 'email');
    expect(map['linkedIn'], 'li');
    expect(map['whatsApp'], 'wa');
    expect(map['tone'], 'FORMAL');
  });

  test('generateResume delegue sans conversion', () async {
    when(() => ds.generateResume('Dev', 'Dart', '3 ans'))
        .thenAnswer((_) async => 'resume');

    final result = await facade.generateResume(
      titrePoste: 'Dev',
      competences: 'Dart',
      experience: '3 ans',
    );

    expect(result, 'resume');
  });

  test('getSuggestions delegue les parametres', () async {
    when(() => ds.getSuggestions(
          poste: 'Dev',
          entreprise: 'ACME',
          description: null,
        )).thenAnswer((_) async => ['a', 'b']);

    final result = await facade.getSuggestions(poste: 'Dev', entreprise: 'ACME');

    expect(result, ['a', 'b']);
  });
}
