package com.cvmobile.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.cvmobile.cv.adapter.in.web.CvResponseAssembler;
import com.cvmobile.cv.adapter.in.web.CvWebMapper;
import com.cvmobile.cv.application.CvNotFoundException;
import com.cvmobile.cv.application.usecase.CreateCvUseCase;
import com.cvmobile.cv.application.usecase.DeleteCvUseCase;
import com.cvmobile.cv.application.usecase.DuplicateCvUseCase;
import com.cvmobile.cv.application.usecase.UpdateCvUseCase;
import com.cvmobile.cv.domain.model.Cv;
import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.model.User;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

/**
 * Contrat HTTP des endpoints CRUD de {@link CvController} apres bascule sur les
 * use cases du module CV (issue #255). Collaborateurs mockes : les use cases,
 * le mapper d'entree et l'assembleur de reponse. Les endpoints
 * partage/PDF/DOCX/variantes/import sont testes dans
 * {@link CvControllerAdditionalOperationsTest} (issue #258, fichier separe pour
 * respecter la limite de 300 lignes).
 */
@ExtendWith(MockitoExtension.class)
class CvControllerTest {

    @Mock private CreateCvUseCase createCvUseCase;
    @Mock private UpdateCvUseCase updateCvUseCase;
    @Mock private DeleteCvUseCase deleteCvUseCase;
    @Mock private DuplicateCvUseCase duplicateCvUseCase;
    @Mock private CvWebMapper cvWebMapper;
    @Mock private CvResponseAssembler cvResponseAssembler;

    // Collaborateurs pour partage/PDF/variantes/import : requis par le
    // constructeur mais non exerces ici (cf. CvControllerAdditionalOperationsTest).
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

    @Test
    void getAllCvs_devraitRetourner200AvecListe() {
        User user = buildUser();
        when(cvResponseAssembler.assembleAll(1L)).thenReturn(List.of(buildCvResponse()));

        ResponseEntity<List<CvResponse>> response = cvController.getAllCvs(user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).hasSize(1);
        assertThat(response.getBody().get(0).getTitre()).isEqualTo("Mon CV Pro");
    }

    @Test
    void getCvById_avecIdValide_devraitRetourner200() {
        User user = buildUser();
        when(cvResponseAssembler.assemble(10L, 1L)).thenReturn(buildCvResponse());

        ResponseEntity<CvResponse> response = cvController.getCvById(10L, user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getId()).isEqualTo(10L);
    }

    @Test
    void createCv_devraitRetourner201() {
        User user = buildUser();
        CvRequest request = new CvRequest();
        request.setTitre("Nouveau CV");
        Cv domain = Cv.create("Nouveau CV", 1L);
        domain.assignId(10L);

        when(cvWebMapper.toDomain(any(CvRequest.class), anyLong())).thenReturn(domain);
        when(createCvUseCase.create(any(Cv.class))).thenReturn(domain);
        when(cvResponseAssembler.assemble(10L, 1L)).thenReturn(buildCvResponse());

        ResponseEntity<CvResponse> response = cvController.createCv(request, user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isNotNull();
        verify(createCvUseCase).create(domain);
    }

    @Test
    void updateCv_devraitRetourner200EtReassemblerLaReponse() {
        User user = buildUser();
        CvRequest request = new CvRequest();
        request.setTitre("CV modifie");
        Cv changes = Cv.create("CV modifie", 1L);

        when(cvWebMapper.toDomain(any(CvRequest.class), anyLong())).thenReturn(changes);
        when(cvResponseAssembler.assemble(10L, 1L)).thenReturn(buildCvResponse());

        ResponseEntity<CvResponse> response = cvController.updateCv(10L, request, user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        verify(updateCvUseCase).update(10L, 1L, changes);
    }

    @Test
    void duplicateCv_devraitRetourner201() {
        User user = buildUser();
        Cv copy = Cv.create("Copie de Mon CV", 1L);
        copy.assignId(11L);
        when(duplicateCvUseCase.duplicate(10L, 1L)).thenReturn(copy);
        when(cvResponseAssembler.assemble(11L, 1L)).thenReturn(buildCvResponse());

        ResponseEntity<CvResponse> response = cvController.duplicateCv(10L, user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isNotNull();
    }

    @Test
    void deleteCv_avecIdValide_devraitRetourner204() {
        User user = buildUser();

        ResponseEntity<Void> response = cvController.deleteCv(10L, user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        verify(deleteCvUseCase).delete(10L, 1L);
    }

    @Test
    void getCvById_quandCvInexistant_devraitPropagerException() {
        User user = buildUser();
        when(cvResponseAssembler.assemble(99L, 1L)).thenThrow(new CvNotFoundException(99L));

        assertThatThrownBy(() -> cvController.getCvById(99L, user))
                .isInstanceOf(CvNotFoundException.class)
                .hasMessageContaining("non trouve");
    }
}
