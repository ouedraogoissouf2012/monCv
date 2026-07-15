package com.cvmobile.service;

import com.cvmobile.model.Cv;
import com.cvmobile.model.PdfTemplate;
import com.cvmobile.model.PersonalInfo;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;

import java.io.ByteArrayInputStream;

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
}
