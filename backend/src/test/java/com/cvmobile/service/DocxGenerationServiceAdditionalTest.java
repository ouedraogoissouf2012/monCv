package com.cvmobile.service;

import com.cvmobile.model.Certification;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Education;
import com.cvmobile.model.Experience;
import com.cvmobile.model.Language;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.Project;
import com.cvmobile.model.Skill;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.apache.poi.xwpf.usermodel.XWPFParagraph;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Complement de {@link DocxGenerationServiceTest} (issue #258) : couvre les
 * branches conditionnelles (contact, profil, niveaux, dates, sections
 * vides/nulles) de {@link DocxGenerationService} non exercees par le test
 * de structure existant.
 */
class DocxGenerationServiceAdditionalTest {

    private final DocxGenerationService service = new DocxGenerationService();

    @Test
    void generatesMinimalDocumentWhenPersonalInfoIsAbsent() throws Exception {
        Cv cv = Cv.builder().build();

        try (XWPFDocument document = openDocument(service.generate(cv))) {
            String text = joinText(document);
            assertThat(text).contains("CV");
            assertThat(text).doesNotContain("PROFIL", "COMPETENCES", "LANGUES");
        }
    }

    @Test
    void buildsFullContactLineAndProfilSection() throws Exception {
        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder()
                        .prenom("Awa").nom("Kone")
                        .titrePoste("Ingenieure logicielle")
                        .email("awa@example.com")
                        .telephone("+237600000000")
                        .ville("Douala")
                        .pays("Cameroun")
                        .resumeProfessionnel("Dix ans d'experience en developpement.")
                        .build())
                .build();

        try (XWPFDocument document = openDocument(service.generate(cv))) {
            String text = joinText(document);
            assertThat(text)
                    .contains("Ingenieure logicielle")
                    .contains("awa@example.com  |  +237600000000  |  Douala, Cameroun")
                    .contains("PROFIL")
                    .contains("Dix ans d'expérience en développement.");
        }
    }

    @Test
    void skipsProfilSectionWhenResumeProfessionnelIsBlank() throws Exception {
        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder().prenom("Awa").nom("Kone")
                        .resumeProfessionnel("   ")
                        .build())
                .build();

        try (XWPFDocument document = openDocument(service.generate(cv))) {
            assertThat(joinText(document)).doesNotContain("PROFIL");
        }
    }

    @Test
    void rendersAllSkillLevelLabelsIncludingMissingAndOutOfRange() throws Exception {
        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder().prenom("Awa").nom("Kone").build())
                .skills(List.of(
                        Skill.builder().nom("SansNiveau").build(),
                        Skill.builder().nom("Junior").niveau(1).build(),
                        Skill.builder().nom("Intermediaire").niveau(2).build(),
                        Skill.builder().nom("Confirme").niveau(4).build(),
                        Skill.builder().nom("ClampBas").niveau(0).build(),
                        Skill.builder().nom("ClampHaut").niveau(6).build()))
                .build();

        try (XWPFDocument document = openDocument(service.generate(cv))) {
            String text = joinText(document);
            assertThat(text)
                    .contains("SansNiveau")
                    .contains("Junior (Débutant)")
                    .contains("Intermédiaire (Intermédiaire)")
                    .contains("Confirme (Confirmé)")
                    .contains("ClampBas (Débutant)")
                    .contains("ClampHaut (Expert)");
        }
    }

    @Test
    void rendersAllLanguageLevelLabelsIncludingUnknown() throws Exception {
        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder().prenom("Awa").nom("Kone").build())
                .languages(List.of(
                        Language.builder().langue("Allemand").niveau(Language.NiveauLangue.A1).build(),
                        Language.builder().langue("Espagnol").niveau(Language.NiveauLangue.A2).build(),
                        Language.builder().langue("Italien").niveau(Language.NiveauLangue.B1).build(),
                        Language.builder().langue("Portugais").niveau(Language.NiveauLangue.B2).build(),
                        Language.builder().langue("Chinois").niveau(Language.NiveauLangue.C2).build(),
                        Language.builder().langue("Inconnue").build()))
                .build();

        try (XWPFDocument document = openDocument(service.generate(cv))) {
            String text = joinText(document);
            assertThat(text)
                    .contains("Allemand (A1 - Débutant)")
                    .contains("Espagnol (A2 - Élémentaire)")
                    .contains("Italien (B1 - Intermédiaire)")
                    .contains("Portugais (B2 - Intermédiaire avancé)")
                    .contains("Chinois (C2 - Maîtrise)")
                    .contains("Inconnue ()");
        }
    }

    @Test
    void rendersExperiencesAcrossDateAndDescriptionBranches() throws Exception {
        Experience current = Experience.builder()
                .entreprise("EntrepriseA").poste("PosteA").lieu("Douala")
                .dateDebut(LocalDate.of(2022, 1, 15)).actuel(true)
                .description("- Point A\n\nPlain point\n* Point B")
                .build();
        Experience samePeriod = Experience.builder()
                .entreprise("EntrepriseB").poste("PosteB")
                .dateDebut(LocalDate.of(2021, 3, 1)).dateFin(LocalDate.of(2021, 3, 20))
                .build();
        Experience range = Experience.builder()
                .entreprise("EntrepriseC").poste("PosteC").lieu("Paris")
                .dateDebut(LocalDate.of(2018, 3, 1)).dateFin(LocalDate.of(2019, 7, 1))
                .description("   ")
                .build();
        Experience undated = Experience.builder()
                .entreprise("EntrepriseD").poste("PosteD")
                .build();

        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder().prenom("Awa").nom("Kone").build())
                .experiences(List.of(current, samePeriod, range, undated))
                .build();

        try (XWPFDocument document = openDocument(service.generate(cv))) {
            String text = joinText(document);
            assertThat(text)
                    .contains("EXPERIENCE PROFESSIONNELLE")
                    .contains("01/2022 - Present")
                    .contains("EntrepriseA, Douala")
                    .contains("Point A").contains("Plain point").contains("Point B")
                    .contains("EntrepriseB")
                    .doesNotContain("EntrepriseB,")
                    .contains("03/2018 - 07/2019")
                    .contains("EntrepriseC, Paris");

            boolean undatedTitleHasNoDateSuffix = document.getParagraphs().stream()
                    .anyMatch(p -> p.getText().equals("PosteD"));
            assertThat(undatedTitleHasNoDateSuffix).isTrue();
        }
    }

    @Test
    void rendersEducationsAcrossDateAndEtablissementBranches() throws Exception {
        Education samePeriod = Education.builder()
                .diplome("DiplomeA")
                .dateDebut(LocalDate.of(2016, 9, 1)).dateFin(LocalDate.of(2016, 9, 15))
                .build();
        Education endOnly = Education.builder()
                .diplome("DiplomeB").etablissement("UniversiteB")
                .dateFin(LocalDate.of(2019, 6, 30))
                .build();
        Education range = Education.builder()
                .diplome("DiplomeC")
                .dateDebut(LocalDate.of(2013, 9, 1)).dateFin(LocalDate.of(2015, 6, 30))
                .build();

        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder().prenom("Awa").nom("Kone").build())
                .educations(List.of(samePeriod, endOnly, range))
                .build();

        try (XWPFDocument document = openDocument(service.generate(cv))) {
            String text = joinText(document);
            assertThat(text)
                    .contains("FORMATION")
                    .contains("DiplomeA").contains("09/2016")
                    .contains("DiplomeB").contains("UniversiteB").contains("06/2019")
                    .contains("DiplomeC").contains("09/2013 - 06/2015");
        }
    }

    @Test
    void rendersCertificationsWithAndWithoutDateOrOrganisme() throws Exception {
        Certification withBoth = Certification.builder()
                .nom("CertA").organisme("OrgA")
                .dateObtention(LocalDate.of(2020, 5, 10))
                .build();
        Certification withNeither = Certification.builder()
                .nom("CertB")
                .build();

        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder().prenom("Awa").nom("Kone").build())
                .certifications(List.of(withBoth, withNeither))
                .build();

        try (XWPFDocument document = openDocument(service.generate(cv))) {
            String text = joinText(document);
            assertThat(text)
                    .contains("CERTIFICATIONS")
                    .contains("CertA").contains("OrgA").contains("05/2020")
                    .contains("CertB");
        }
    }

    @Test
    void rendersProjectsWithMissingTechnologiesOrDescription() throws Exception {
        Project noTech = Project.builder().nom("ProjetA").description("Description A").build();
        Project noDescription = Project.builder().nom("ProjetB").technologies("Java, Kafka").build();

        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder().prenom("Awa").nom("Kone").build())
                .projects(List.of(noTech, noDescription))
                .build();

        try (XWPFDocument document = openDocument(service.generate(cv))) {
            String text = joinText(document);
            assertThat(text)
                    .contains("PROJETS")
                    .contains("ProjetA").contains("Description A")
                    .contains("ProjetB").contains("Java, Kafka");
        }
    }

    private static XWPFDocument openDocument(byte[] bytes) throws IOException {
        return new XWPFDocument(new ByteArrayInputStream(bytes));
    }

    private static String joinText(XWPFDocument document) {
        return document.getParagraphs().stream()
                .map(XWPFParagraph::getText)
                .reduce("", (left, right) -> left + "\n" + right);
    }
}
