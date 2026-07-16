package com.cvmobile.service.import_;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.exception.BusinessException;
import com.cvmobile.service.ai.client.IAiClient;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CvImportServiceImplTest {

    private static final String AI_RESPONSE = """
            NOM: Kone
            PRENOM: Awa
            EMAIL: awa.kone@example.com
            TELEPHONE: +2250700000000
            VILLE: Abidjan
            PAYS: Cote d'Ivoire
            TITRE_POSTE: Product Manager
            RESUME: Product Manager orientee resultats.

            EXPERIENCES:
            - POSTE: Product Manager | ENTREPRISE: Fintech Africa | LIEU: Abidjan | DESCRIPTION: Pilotage produit

            FORMATIONS:
            - DIPLOME: Master | ETABLISSEMENT: Universite Felix Houphouet-Boigny | DOMAINE: Management

            COMPETENCES:
            - Strategie produit
            - Analyse de donnees

            LANGUES:
            - Francais: natif
            - Anglais
            ---
            """;

    @Mock
    private IAiClient aiClient;

    private CvImportServiceImpl service;

    @BeforeEach
    void setUp() {
        service = new CvImportServiceImpl(aiClient);
    }

    @Test
    void importsValidPdfAndMapsStructuredResponse() throws IOException {
        when(aiClient.complete(anyString(), eq(3000))).thenReturn(AI_RESPONSE);

        CvRequest result = service.importCv(file("cv.pdf", "application/pdf", pdfWithText("CV Awa Kone")));

        assertImportedCv(result);
        verify(aiClient).complete(anyString(), eq(3000));
    }

    @Test
    void importsValidDocxAndMapsStructuredResponse() throws IOException {
        when(aiClient.complete(anyString(), eq(3000))).thenReturn(AI_RESPONSE);

        CvRequest result = service.importCv(file(
                "cv.docx",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                docxWithText("CV Awa Kone")));

        assertImportedCv(result);
        verify(aiClient).complete(anyString(), eq(3000));
    }

    @Test
    void rejectsScannedPdfWithoutExtractableText() throws IOException {
        assertImportError(file("scan.pdf", "application/pdf", blankPdf()), "PDF scanne");
    }

    @Test
    void rejectsMalformedPdf() {
        assertImportError(file("cv.pdf", "application/pdf", new byte[]{1, 2, 3}), "Impossible de lire");
    }

    @Test
    void rejectsUnsupportedFormat() {
        assertImportError(file("cv.txt", "text/plain", "CV".getBytes()), "Format non supporte");
    }

    @Test
    void rejectsMimeAndExtensionMismatch() {
        assertImportError(file("cv.pdf", "text/html", "%PDF-faux".getBytes()),
                "ne correspond pas");
    }

    @Test
    void rejectsPdfWithTooManyPages() throws IOException {
        assertImportError(file("cv.pdf", "application/pdf", pdfWithPages(31)),
                "depasse 30 pages");
    }

    @Test
    void rejectsEmptyFile() {
        assertImportError(file("cv.pdf", "application/pdf", new byte[0]), "vide");
    }

    @Test
    void rejectsFileLargerThanFiveMegabytes() {
        byte[] content = new byte[5 * 1024 * 1024 + 1];

        assertThatThrownBy(() -> service.importCv(file("cv.pdf", "application/pdf", content)))
                .isInstanceOf(MaxUploadSizeExceededException.class);
    }

    private void assertImportedCv(CvRequest result) {
        assertThat(result.getTitre()).isEqualTo("Product Manager");
        assertThat(result.getPersonalInfo().getNom()).isEqualTo("Kone");
        assertThat(result.getExperiences()).singleElement()
                .satisfies(experience -> assertThat(experience.getEntreprise()).isEqualTo("Fintech Africa"));
        assertThat(result.getEducations()).singleElement()
                .satisfies(education -> assertThat(education.getDiplome()).isEqualTo("Master"));
        assertThat(result.getSkills()).hasSize(2).allSatisfy(skill -> assertThat(skill.getNiveau()).isEqualTo(3));
        assertThat(result.getLanguages()).hasSize(2);
        assertThat(result.getLanguages().get(0).getNiveau().name()).isEqualTo("NATIF");
        assertThat(result.getLanguages().get(1).getNiveau().name()).isEqualTo("B1");
    }

    private void assertImportError(MockMultipartFile file, String expectedMessage) {
        assertThatThrownBy(() -> service.importCv(file))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining(expectedMessage)
                .extracting(error -> ((BusinessException) error).getCode())
                .isEqualTo("IMPORT_ERROR");
    }

    private MockMultipartFile file(String filename, String contentType, byte[] content) {
        return new MockMultipartFile("file", filename, contentType, content);
    }

    private byte[] pdfWithText(String text) throws IOException {
        try (PDDocument document = new PDDocument(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            PDPage page = new PDPage();
            document.addPage(page);
            try (PDPageContentStream stream = new PDPageContentStream(document, page)) {
                stream.beginText();
                stream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 12);
                stream.newLineAtOffset(72, 720);
                stream.showText(text);
                stream.endText();
            }
            document.save(output);
            return output.toByteArray();
        }
    }

    private byte[] blankPdf() throws IOException {
        try (PDDocument document = new PDDocument(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            document.addPage(new PDPage());
            document.save(output);
            return output.toByteArray();
        }
    }

    private byte[] pdfWithPages(int count) throws IOException {
        try (PDDocument document = new PDDocument(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            for (int i = 0; i < count; i++) document.addPage(new PDPage());
            document.save(output);
            return output.toByteArray();
        }
    }

    private byte[] docxWithText(String text) throws IOException {
        try (XWPFDocument document = new XWPFDocument(); ByteArrayOutputStream output = new ByteArrayOutputStream()) {
            document.createParagraph().createRun().setText(text);
            document.write(output);
            return output.toByteArray();
        }
    }
}
