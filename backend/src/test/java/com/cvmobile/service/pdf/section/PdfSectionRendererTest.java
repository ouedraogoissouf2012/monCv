package com.cvmobile.service.pdf.section;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.service.pdf.PdfRenderContext;
import com.cvmobile.service.pdf.PdfTestFixtures;
import com.cvmobile.service.pdf.style.PdfFonts;
import com.cvmobile.service.pdf.style.PdfTheme;
import com.lowagie.text.Document;
import com.lowagie.text.PageSize;
import com.lowagie.text.pdf.PdfReader;
import com.lowagie.text.pdf.PdfWriter;
import com.lowagie.text.pdf.parser.PdfTextExtractor;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

class PdfSectionRendererTest {

    @ParameterizedTest(name = "{1}")
    @MethodSource("sections")
    void sectionRendersItsExpectedContent(PdfSectionRenderer renderer, String expected) throws Exception {
        PdfTheme theme = PdfTheme.moderne();
        byte[] pdf;
        try (ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            Document document = new Document(PageSize.A4);
            PdfWriter.getInstance(document, output);
            document.open();
            renderer.render(new PdfRenderContext(
                    PdfTestFixtures.completeCv(), theme, new PdfFonts(theme), document::add));
            document.close();
            pdf = output.toByteArray();
        }

        assertThat(extractText(pdf)).contains(expected);
    }

    @Test
    void competenceAuDelaDeDixAbsenteEtMarkdownNettoye() throws Exception {
        List<CvResponse.SkillDto> skills = new ArrayList<>();
        for (int index = 1; index <= 12; index++) {
            skills.add(CvResponse.SkillDto.builder().nom("Skill" + index).niveau(3).build());
        }
        skills.set(0, CvResponse.SkillDto.builder().nom("**Java**").niveau(5).build());
        CvResponse cv = CvResponse.builder().skills(skills).build();
        byte[] pdf;
        try (ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            Document document = new Document(PageSize.A4);
            PdfWriter.getInstance(document, output);
            document.open();
            new SkillSectionRenderer().render(new PdfRenderContext(
                    cv, PdfTheme.moderne(), new PdfFonts(PdfTheme.moderne()), document::add));
            document.close();
            pdf = output.toByteArray();
        }
        String text = extractText(pdf);
        assertThat(text).contains("Java").contains("Skill10")
                .doesNotContain("Skill11").doesNotContain("**");
    }

    static Stream<Arguments> sections() {
        return Stream.of(
                Arguments.of(new HeaderSectionRenderer(), "Awa Kone"),
                Arguments.of(new SummarySectionRenderer(), "PROFIL"),
                Arguments.of(new ExperienceSectionRenderer(), "Product Manager Senior"),
                Arguments.of(new EducationSectionRenderer(), "Master Management"),
                Arguments.of(new SkillSectionRenderer(), "Stratégie produit"),
                Arguments.of(new LanguageSectionRenderer(), "Français"),
                Arguments.of(new CertificationSectionRenderer(), "Professional Scrum Product Owner I"),
                Arguments.of(new ProjectSectionRenderer(), "Optimisation du paiement marchand"));
    }

    private String extractText(byte[] pdf) throws Exception {
        PdfReader reader = new PdfReader(pdf);
        try {
            return new PdfTextExtractor(reader).getTextFromPage(1);
        } finally {
            reader.close();
        }
    }
}
