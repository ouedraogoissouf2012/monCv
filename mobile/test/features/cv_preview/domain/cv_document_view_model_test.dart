import 'package:cv_mobile/features/cv_preview/domain/cv_document_view_model.dart';
import 'package:cv_mobile/models/cv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CvDocumentViewModel.formatMonthYear (#243 E1)', () {
    test('formate MM/aaaa avec zero-padding', () {
      expect(CvDocumentViewModel.formatMonthYear(DateTime(2024, 3)), '03/2024');
      expect(CvDocumentViewModel.formatMonthYear(DateTime(2024, 11)),
          '11/2024');
    });

    test('date nulle -> chaine vide', () {
      expect(CvDocumentViewModel.formatMonthYear(null), '');
    });
  });

  group('CvDocumentViewModel.formatDateRange (#243 E1)', () {
    test('debut + fin distincts -> plage complete', () {
      expect(
        CvDocumentViewModel.formatDateRange(
          DateTime(2020, 1),
          DateTime(2022, 6),
          ongoingLabel: 'En cours',
        ),
        '01/2020 - 06/2022',
      );
    });

    test('actuel -> fin remplacee par le libelle en cours', () {
      expect(
        CvDocumentViewModel.formatDateRange(
          DateTime(2020, 1),
          null,
          ongoingLabel: 'En cours',
          actuel: true,
        ),
        '01/2020 - En cours',
      );
    });

    test('fin absente et debut present -> considere en cours', () {
      expect(
        CvDocumentViewModel.formatDateRange(
          DateTime(2020, 1),
          null,
          ongoingLabel: 'Present',
        ),
        '01/2020 - Present',
      );
    });

    test('meme annee debut/fin -> annee seule (collapse)', () {
      expect(
        CvDocumentViewModel.formatDateRange(
          DateTime(2021, 2),
          DateTime(2021, 9),
          ongoingLabel: 'x',
        ),
        '2021',
      );
    });

    test('deux bornes absentes -> chaine vide', () {
      expect(
        CvDocumentViewModel.formatDateRange(null, null, ongoingLabel: 'x'),
        '',
      );
    });
  });

  group('CvDocumentViewModel.skills (#243 E1)', () {
    CvDocumentViewModel vmWithSkills(List<Skill> skills) =>
        CvDocumentViewModel(Cv(titre: 'x', skills: skills));

    test('eclate "Java, Python; Go" en trois entrees', () {
      final views = vmWithSkills([const Skill(nom: 'Java, Python; Go', niveau: 4)]);
      expect(views.skills, [
        const SkillView('Java', 4),
        const SkillView('Python', 4),
        const SkillView('Go', 4),
      ]);
    });

    test('niveau absent -> defaut 3 (iso-comportement monolithe)', () {
      final views = vmWithSkills([const Skill(nom: 'Rust')]);
      expect(views.skills.single, const SkillView('Rust', 3));
    });

    test('ignore les fragments vides', () {
      final views = vmWithSkills([const Skill(nom: 'Java, , ;Go', niveau: 2)]);
      expect(views.skills.map((s) => s.name), ['Java', 'Go']);
    });
  });

  group('CvDocumentViewModel sections visibles (#243 E1)', () {
    test('sections vides -> non visibles', () {
      final vm = CvDocumentViewModel(Cv(titre: 'x'));
      expect(vm.hasSummary, isFalse);
      expect(vm.hasSkills, isFalse);
      expect(vm.hasExperiences, isFalse);
      expect(vm.hasProjects, isFalse);
    });

    test('resume renseigne -> hasSummary vrai', () {
      final vm = CvDocumentViewModel(Cv(
        titre: 'x',
        personalInfo: const PersonalInfo(resumeProfessionnel: 'Un resume.'),
      ));
      expect(vm.hasSummary, isTrue);
    });

    test('resume blanc -> hasSummary faux', () {
      final vm = CvDocumentViewModel(Cv(
        titre: 'x',
        personalInfo: const PersonalInfo(resumeProfessionnel: '   '),
      ));
      expect(vm.hasSummary, isFalse);
    });
  });
}
