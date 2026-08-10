package com.cvmobile.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.cvmobile.cv.adapter.in.web.CvResponseAssembler;
import com.cvmobile.cv.adapter.in.web.CvWebMapper;
import com.cvmobile.cv.application.usecase.CreateCvUseCase;
import com.cvmobile.cv.application.usecase.DeleteCvUseCase;
import com.cvmobile.cv.application.usecase.DuplicateCvUseCase;
import com.cvmobile.cv.application.usecase.UpdateCvUseCase;
import com.cvmobile.dto.CreateVariantRequest;
import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.PublicShareSettingsRequest;
import com.cvmobile.model.PdfTemplate;
import com.cvmobile.model.User;
import java.io.IOException;
import java.util.List;
import java.util.concurrent.Callable;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;

/**
 * Contrat HTTP des endpoints partage/PDF/DOCX/variantes/import de
 * {@link CvController} (issue #258). Complement de {@link CvControllerTest}
 * (CRUD, issue #255) : separe pour respecter la limite de 300 lignes.
 * Collaborateurs mockes : les services historiques encore portes par le
 * controleur ; les use cases CRUD sont mockes uniquement pour satisfaire le
 * constructeur, non exerces ici.
 */
@ExtendWith(MockitoExtension.class)
class CvControllerAdditionalOperationsTest {

    @Mock private CreateCvUseCase createCvUseCase;
    @Mock private UpdateCvUseCase updateCvUseCase;
    @Mock private DeleteCvUseCase deleteCvUseCase;
    @Mock private DuplicateCvUseCase duplicateCvUseCase;
    @Mock private CvWebMapper cvWebMapper;
    @Mock private CvResponseAssembler cvResponseAssembler;

    @Mock private com.cvmobile.service.cv.ICvService cvService;
    @Mock private com.cvmobile.service.pdf.PdfGenerationService pdfGenerationService;
    @Mock private com.cvmobile.service.DocxGenerationService docxGenerationService;
    @Mock private com.cvmobile.service.cv.CvOwnershipService cvOwnershipService;
    @Mock private com.cvmobile.service.import_.ICvImportService cvImportService;
    @Mock private com.cvmobile.observability.BusinessMetrics businessMetrics;

    private CvController cvController;

    @BeforeEach
    void setUp() {
        cvController = new CvController(
                createCvUseCase, updateCvUseCase, deleteCvUseCase,
                duplicateCvUseCase, cvWebMapper, cvResponseAssembler,
                cvService, pdfGenerationService, docxGenerationService,
                cvOwnershipService, cvImportService, businessMetrics);
    }

    private User buildUser() {
        return User.builder().id(1L).email("user@example.com")
                .password("encoded").role(User.Role.USER).build();
    }

    private CvResponse buildCvResponse() {
        return CvResponse.builder().id(10L).titre("Mon CV Pro")
                .educations(List.of()).experiences(List.of())
                .skills(List.of()).languages(List.of()).build();
    }

    private void stubBusinessMetricsToInvokeCallable() {
        when(businessMetrics.recordPdfGeneration(anyString(), any())).thenAnswer(
                invocation -> ((Callable<?>) invocation.getArgument(1)).call());
    }

    @Test
    void downloadCvPdf_avecTemplateValide_genereEtNommeLeFichier() {
        User user = buildUser();
        CvResponse cv = buildCvResponse();
        when(cvService.getCvById(10L, 1L)).thenReturn(cv);
        stubBusinessMetricsToInvokeCallable();
        when(pdfGenerationService.generateCvPdf(cv, PdfTemplate.CLASSIQUE))
                .thenReturn("pdf-bytes".getBytes());

        ResponseEntity<byte[]> response =
                cvController.downloadCvPdf(10L, "classique", user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isEqualTo("pdf-bytes".getBytes());
        assertThat(response.getHeaders().getContentDisposition().getFilename())
                .isEqualTo("cv-10-classique.pdf");
    }

    @Test
    void downloadCvPdf_avecTemplateInconnu_replieVersModerne() {
        User user = buildUser();
        CvResponse cv = buildCvResponse();
        when(cvService.getCvById(10L, 1L)).thenReturn(cv);
        stubBusinessMetricsToInvokeCallable();
        when(pdfGenerationService.generateCvPdf(cv, PdfTemplate.MODERNE))
                .thenReturn("pdf-bytes".getBytes());

        ResponseEntity<byte[]> response =
                cvController.downloadCvPdf(10L, "inexistant", user);

        assertThat(response.getBody()).isEqualTo("pdf-bytes".getBytes());
        verify(pdfGenerationService).generateCvPdf(cv, PdfTemplate.MODERNE);
    }

    @Test
    void downloadCvDocx_chargeLEntiteCompleteEtRetourneLeDocument() throws IOException {
        User user = buildUser();
        // CvOwnershipService charge l'entite JPA legacy (com.cvmobile.model.Cv),
        // distincte du modele de domaine (com.cvmobile.cv.domain.model.Cv) utilise
        // par les use cases CRUD (CvControllerTest).
        com.cvmobile.model.Cv owned =
                com.cvmobile.model.Cv.builder().id(10L).titre("Mon CV Pro").build();
        when(cvOwnershipService.requireOwnedCv(10L, 1L)).thenReturn(owned);
        when(docxGenerationService.generate(owned)).thenReturn("docx-bytes".getBytes());

        ResponseEntity<byte[]> response = cvController.downloadCvDocx(10L, user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isEqualTo("docx-bytes".getBytes());
        assertThat(response.getHeaders().getContentDisposition().getFilename())
                .isEqualTo("cv-10.docx");
    }

    @Test
    void generateShareToken_delegueEtRetourneLeCvMisAJour() {
        User user = buildUser();
        CvResponse shared = buildCvResponse();
        when(cvService.generateShareToken(10L, 1L)).thenReturn(shared);

        assertThat(cvController.generateShareToken(10L, user).getBody()).isSameAs(shared);
    }

    @Test
    void regenerateShareToken_delegueEtRetourneLeCvMisAJour() {
        User user = buildUser();
        CvResponse shared = buildCvResponse();
        when(cvService.regenerateShareToken(10L, 1L)).thenReturn(shared);

        assertThat(cvController.regenerateShareToken(10L, user).getBody()).isSameAs(shared);
    }

    @Test
    void deactivateShare_delegueEtRetourneLeCvMisAJour() {
        User user = buildUser();
        CvResponse deactivated = buildCvResponse();
        when(cvService.deactivateShare(10L, 1L)).thenReturn(deactivated);

        assertThat(cvController.deactivateShare(10L, user).getBody()).isSameAs(deactivated);
    }

    @Test
    void updateShareSettings_delegueLaRequeteAuService() {
        User user = buildUser();
        PublicShareSettingsRequest request = new PublicShareSettingsRequest();
        CvResponse updated = buildCvResponse();
        when(cvService.updateShareSettings(10L, request, 1L)).thenReturn(updated);

        assertThat(cvController.updateShareSettings(10L, request, user).getBody())
                .isSameAs(updated);
    }

    @Test
    void createVariant_retourne201AvecLaVarianteCreee() {
        User user = buildUser();
        CreateVariantRequest request = new CreateVariantRequest();
        request.setJobDescription("Offre X");
        request.setLabel("Variante X");
        CvResponse variant = buildCvResponse();
        when(cvService.createVariant(10L, "Offre X", "Variante X", 1L)).thenReturn(variant);

        ResponseEntity<CvResponse> response = cvController.createVariant(10L, request, user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isSameAs(variant);
    }

    @Test
    void getVariants_retourneLaListeDuService() {
        User user = buildUser();
        List<CvResponse> variants = List.of(buildCvResponse());
        when(cvService.getVariantsByParentId(10L, 1L)).thenReturn(variants);

        assertThat(cvController.getVariants(10L, user).getBody()).isSameAs(variants);
    }

    @Test
    void importCv_succes_enregistreLaMetriqueEtRetourne201() {
        User user = buildUser();
        MultipartFile file = new MockMultipartFile(
                "file", "cv.pdf", "application/pdf", "contenu".getBytes());
        CvRequest parsed = new CvRequest();
        CvResponse created = buildCvResponse();
        when(cvImportService.importCv(file)).thenReturn(parsed);
        when(cvService.createCv(parsed, 1L)).thenReturn(created);

        ResponseEntity<CvResponse> response = cvController.importCv(file, user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isSameAs(created);
        verify(businessMetrics).recordImport(eq("pdf"), eq(true));
    }

    @Test
    void importCv_echecDuParsing_enregistreLechecEtPropageLException() {
        User user = buildUser();
        MultipartFile file = new MockMultipartFile(
                "file", "cv.docx", "application/octet-stream", "contenu".getBytes());
        RuntimeException failure = new IllegalStateException("format illisible");
        when(cvImportService.importCv(file)).thenThrow(failure);

        assertThatThrownBy(() -> cvController.importCv(file, user)).isSameAs(failure);

        verify(businessMetrics).recordImport(eq("docx"), eq(false));
    }
}
