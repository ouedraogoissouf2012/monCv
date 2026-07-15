package com.cvmobile.service;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.exception.PdfGenerationException;
import com.cvmobile.model.PdfTemplate;
import com.lowagie.text.pdf.PdfReader;
import com.lowagie.text.pdf.parser.PdfTextExtractor;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class PdfGenerationServiceTest {

    private final PdfGenerationService service = new PdfGenerationService();

    @ParameterizedTest
    @EnumSource(PdfTemplate.class)
    void eachTemplateGeneratesACompletePdf(PdfTemplate template) throws Exception {
        byte[] pdf = service.generateCvPdf(completeCv(), template);

        assertThat(pdf).hasSizeGreaterThan(1_000);
        String text = extractText(pdf);
        assertThat(text)
                .contains("Awa Kone")
                .contains("EXPÉRIENCES PROFESSIONNELLES")
                .contains("FORMATIONS")
                .contains("COMPÉTENCES")
                .contains("LANGUES")
                .contains("CERTIFICATIONS")
                .contains("PROJETS");
    }

    @Test
    void modernTemplateMatchesTextGoldenSnapshot() throws Exception {
        String snapshot = normalize(extractText(service.generateCvPdf(completeCv(), PdfTemplate.MODERNE)));

        assertThat(snapshot).isEqualTo(
                "Awa Kone Product Manager awa@example.com | +225 01 02 03 04 | Abidjan, Côte d'Ivoire "
                        + "Pilote des produits numériques utiles et mesurables. Product Manager Senior — Fintech Africa "
                        + "01/2023 — Présent | Abidjan Pilotage de la feuille de route produit. "
                        + "Master Management — Université de Dakar Innovation • 09/2018 — 06/2020 "
                        + "Français (NATIF) Professional Scrum Product Owner I — Scrum.org Obtenue en 06/2022 "
                        + "Optimisation du paiement marchand Amélioration du taux de réussite des transactions. SQL, Metabase "
                        + "PROFIL EXPÉRIENCES PROFESSIONNELLES FORMATIONS COMPÉTENCES Stratégie produit 5/5 "
                        + "LANGUES CERTIFICATIONS PROJETS");
    }

    @Test
    void nullCvRaisesTypedException() {
        assertThatThrownBy(() -> service.generateCvPdf(null, PdfTemplate.MODERNE))
                .isInstanceOf(PdfGenerationException.class)
                .hasMessageContaining("obligatoire");
    }

    private CvResponse completeCv() {
        return CvResponse.builder()
                .personalInfo(CvResponse.PersonalInfoDto.builder()
                        .prenom("Awa").nom("Kone").titrePoste("Product Manager")
                        .email("awa@example.com").telephone("+225 01 02 03 04")
                        .ville("Abidjan").pays("Côte d'Ivoire")
                        .resumeProfessionnel("Pilote des produits numériques utiles et mesurables.").build())
                .experiences(List.of(CvResponse.ExperienceDto.builder()
                        .poste("Product Manager Senior").entreprise("Fintech Africa").lieu("Abidjan")
                        .dateDebut(LocalDate.of(2023, 1, 1)).actuel(true)
                        .description("Pilotage de la feuille de route produit.").build()))
                .educations(List.of(CvResponse.EducationDto.builder()
                        .diplome("Master Management").etablissement("Université de Dakar")
                        .domaine("Innovation").dateDebut(LocalDate.of(2018, 9, 1))
                        .dateFin(LocalDate.of(2020, 6, 1)).build()))
                .skills(List.of(CvResponse.SkillDto.builder().nom("Stratégie produit").niveau(5).build()))
                .languages(List.of(CvResponse.LanguageDto.builder().langue("Français")
                        .niveau(com.cvmobile.model.Language.NiveauLangue.NATIF).build()))
                .certifications(List.of(CvResponse.CertificationDto.builder()
                        .nom("Professional Scrum Product Owner I").organisme("Scrum.org")
                        .dateObtention(LocalDate.of(2022, 6, 15)).build()))
                .projects(List.of(CvResponse.ProjectDto.builder()
                        .nom("Optimisation du paiement marchand")
                        .description("Amélioration du taux de réussite des transactions.")
                        .technologies("SQL, Metabase").build()))
                .build();
    }

    private String extractText(byte[] pdf) throws Exception {
        PdfReader reader = new PdfReader(pdf);
        try {
            PdfTextExtractor extractor = new PdfTextExtractor(reader);
            StringBuilder text = new StringBuilder();
            for (int page = 1; page <= reader.getNumberOfPages(); page++) {
                text.append(extractor.getTextFromPage(page)).append(' ');
            }
            return text.toString();
        } finally {
            reader.close();
        }
    }

    private String normalize(String text) {
        return text.replaceAll("\\s+", " ").trim();
    }
}
