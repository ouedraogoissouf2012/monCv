package com.cvmobile.service;

import com.cvmobile.model.Cv;
import com.cvmobile.model.Language;
import com.cvmobile.model.PdfTemplate;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.Project;
import com.cvmobile.model.Skill;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

import java.io.ByteArrayInputStream;
import java.math.BigInteger;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class DocxGenerationServiceTest {

    private final DocxGenerationService service = new DocxGenerationService();

    @ParameterizedTest(name = "structure DOCX valide pour le style {0}")
    @EnumSource(PdfTemplate.class)
    void generatesValidWordStructureForEveryTemplate(PdfTemplate template) throws Exception {
        Cv cv = Cv.builder()
                .titre("CV " + template.name())
                .styleTemplateId(template.name().toLowerCase())
                .personalInfo(PersonalInfo.builder()
                        .prenom("Awa")
                        .nom("Kone")
                        .titrePoste("Product Manager")
                        .email("awa@example.com")
                        .build())
                .build();

        byte[] bytes = service.generate(cv);

        assertThat(bytes).hasSizeGreaterThan(1_000);
        try (XWPFDocument document = new XWPFDocument(new ByteArrayInputStream(bytes))) {
            assertThat(document.getParagraphs())
                    .isNotEmpty()
                    .extracting(paragraph -> paragraph.getText())
                    .contains("Awa Kone", "Product Manager", "awa@example.com");
        }
    }

    @Test
    void preservesLevelsProjectsAndA4PageDefinition() throws Exception {
        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder().prenom("Awa").nom("Kone").build())
                .skills(List.of(
                        Skill.builder().nom("Java").niveau(5).build(),
                        Skill.builder().nom("Gestion de projet").niveau(3).build()))
                .languages(List.of(
                        Language.builder().langue("Anglais").niveau(Language.NiveauLangue.C1).build(),
                        Language.builder().langue("Français").niveau(Language.NiveauLangue.NATIF).build()))
                .projects(List.of(Project.builder()
                        .nom("Plateforme de paiement")
                        .technologies("Java, PostgreSQL")
                        .description("Déploiement dans trois pays.")
                        .build()))
                .build();

        byte[] bytes = service.generate(cv);

        try (XWPFDocument document = new XWPFDocument(new ByteArrayInputStream(bytes))) {
            String text = document.getParagraphs().stream()
                    .map(paragraph -> paragraph.getText())
                    .reduce("", (left, right) -> left + "\n" + right);
            assertThat(text)
                    .contains("Java (Expert)")
                    .contains("Gestion de projet (Avancé)")
                    .contains("Anglais (C1 - Courant)")
                    .contains("Français (Natif)")
                    .contains("PROJETS", "Plateforme de paiement", "Java, PostgreSQL");

            assertThat(document.getDocument().getBody().isSetSectPr()).isTrue();
            var pageSize = document.getDocument().getBody().getSectPr().getPgSz();
            assertThat(pageSize.getW()).isEqualTo(BigInteger.valueOf(11_906));
            assertThat(pageSize.getH()).isEqualTo(BigInteger.valueOf(16_838));
        }
    }
}
