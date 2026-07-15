package com.cvmobile.service.pdf.template;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.service.pdf.PdfTestFixtures;
import com.lowagie.text.pdf.PdfReader;
import com.lowagie.text.pdf.parser.PdfTextExtractor;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;

import static org.assertj.core.api.Assertions.assertThat;

abstract class AbstractPdfTemplateContractTest {

    protected abstract PdfTemplate template();
    protected abstract String goldenDigest();

    @Test
    void generatesEmptyCv() throws Exception {
        byte[] pdf = template().render(CvResponse.builder().build());

        assertThat(pdf).hasSizeGreaterThan(500);
        assertThat(new PdfReader(pdf).getNumberOfPages()).isOne();
    }

    @Test
    void generatesMinimalCv() throws Exception {
        CvResponse cv = CvResponse.builder()
                .personalInfo(CvResponse.PersonalInfoDto.builder()
                        .prenom("Awa").nom("Kone").build())
                .build();

        assertThat(extractText(template().render(cv))).contains("Awa Kone");
    }

    @Test
    void generatesCompleteCv() throws Exception {
        String text = extractText(template().render(PdfTestFixtures.completeCv()));

        assertThat(text)
                .contains("Product Manager Senior")
                .contains("Master Management")
                .contains("Professional Scrum Product Owner I")
                .contains("Optimisation du paiement marchand");
    }

    @Test
    void matchesGoldenTextSnapshot() throws Exception {
        String normalized = extractText(template().render(PdfTestFixtures.completeCv()))
                .replaceAll("\\s+", " ").trim();

        assertThat(sha256(normalized)).isEqualTo(goldenDigest());
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

    private String sha256(String value) throws Exception {
        return HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256")
                        .digest(value.getBytes(StandardCharsets.UTF_8)));
    }
}
