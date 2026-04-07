package com.cvmobile.controller;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.model.User;
import com.cvmobile.service.CvService;
import com.cvmobile.service.PdfGenerationService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CvControllerTest {

    @Mock private CvService cvService;
    @Mock private PdfGenerationService pdfGenerationService;

    @InjectMocks private CvController cvController;

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
        when(cvService.getAllCvsByUserId(1L)).thenReturn(List.of(buildCvResponse()));

        ResponseEntity<List<CvResponse>> response = cvController.getAllCvs(user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).hasSize(1);
        assertThat(response.getBody().get(0).getTitre()).isEqualTo("Mon CV Pro");
    }

    @Test
    void getCvById_avecIdValide_devraitRetourner200() {
        User user = buildUser();
        when(cvService.getCvById(10L, 1L)).thenReturn(buildCvResponse());

        ResponseEntity<CvResponse> response = cvController.getCvById(10L, user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody().getId()).isEqualTo(10L);
    }

    @Test
    void createCv_devraitRetourner201() {
        User user = buildUser();
        CvRequest request = new CvRequest();
        request.setTitre("Nouveau CV");

        when(cvService.createCv(any(CvRequest.class), anyLong())).thenReturn(buildCvResponse());

        ResponseEntity<CvResponse> response = cvController.createCv(request, user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody()).isNotNull();
    }

    @Test
    void deleteCv_avecIdValide_devraitRetourner204() {
        User user = buildUser();

        ResponseEntity<Void> response = cvController.deleteCv(10L, user);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);
        verify(cvService).deleteCv(10L, 1L);
    }

    @Test
    void getCvById_quandCvInexistant_devraitPropagerException() {
        User user = buildUser();
        when(cvService.getCvById(99L, 1L)).thenThrow(new ResourceNotFoundException("CV", "id", 99L));

        assertThatThrownBy(() -> cvController.getCvById(99L, user))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("non trouve");
    }
}
