package com.cvmobile.service;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.model.PdfTemplate;
import com.lowagie.text.pdf.PdfReader;
import com.lowagie.text.pdf.parser.PdfTextExtractor;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class PdfGenerationServiceTest {

    private final PdfGenerationService service = new PdfGenerationService();

    @Test
    void modernTemplateIncludesCertificationsAndProjects() throws Exception {
        CvResponse cv = CvResponse.builder()
                .titre("Product Manager")
                .personalInfo(CvResponse.PersonalInfoDto.builder()
                        .prenom("Awa")
                        .nom("Kone")
                        .titrePoste("Product Manager")
                        .build())
                .certifications(List.of(CvResponse.CertificationDto.builder()
                        .nom("Professional Scrum Product Owner I")
                        .organisme("Scrum.org")
                        .dateObtention(LocalDate.of(2022, 6, 15))
                        .build()))
                .projects(List.of(CvResponse.ProjectDto.builder()
                        .nom("Optimisation du paiement marchand")
                        .description("Amelioration du taux de reussite des transactions.")
                        .technologies("SQL, Metabase")
                        .build()))
                .build();

        byte[] pdf = service.generateCvPdf(cv, PdfTemplate.MODERNE);

        PdfReader reader = new PdfReader(pdf);
        StringBuilder text = new StringBuilder();
        PdfTextExtractor extractor = new PdfTextExtractor(reader);
        for (int page = 1; page <= reader.getNumberOfPages(); page++) {
            text.append(extractor.getTextFromPage(page));
        }
        reader.close();

        assertThat(text)
                .contains("CERTIFICATIONS")
                .contains("Professional Scrum Product Owner I")
                .contains("Obtenue en 06/2022")
                .contains("PROJETS")
                .contains("Optimisation du paiement marchand")
                .doesNotContain("06/2022 — ...");
    }
}
