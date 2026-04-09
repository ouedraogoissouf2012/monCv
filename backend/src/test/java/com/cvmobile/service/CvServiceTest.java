package com.cvmobile.service;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.Cv;
import com.cvmobile.model.User;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.repository.CvViewRepository;
import com.cvmobile.service.user.IUserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CvServiceTest {

    @Mock private CvRepository cvRepository;
    @Mock private CvViewRepository cvViewRepository;
    @Mock private IUserService userService;
    @Mock private CvMapper cvMapper;

    @InjectMocks
    private CvService cvService;

    private User buildUser() {
        return User.builder().id(1L).email("user@example.com").role(User.Role.USER).build();
    }

    private Cv buildCv(User user) {
        return Cv.builder().id(10L).titre("Mon CV").user(user).build();
    }

    private CvResponse buildCvResponse() {
        return CvResponse.builder().id(10L).titre("Mon CV").build();
    }

    @Test
    void getAllCvsByUserId_devraitRetournerLaListeDesCvs() {
        User user = buildUser();
        Cv cv = buildCv(user);
        CvResponse response = buildCvResponse();

        when(cvRepository.findByUserIdWithDetails(1L)).thenReturn(List.of(cv));
        when(cvMapper.toResponse(cv)).thenReturn(response);

        List<CvResponse> result = cvService.getAllCvsByUserId(1L);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getTitre()).isEqualTo("Mon CV");
    }

    @Test
    void getCvById_avecIdValide_devraitRetournerLeCv() {
        User user = buildUser();
        Cv cv = buildCv(user);
        CvResponse response = buildCvResponse();

        when(cvRepository.findByIdAndUserId(10L, 1L)).thenReturn(Optional.of(cv));
        when(cvMapper.toResponse(cv)).thenReturn(response);

        CvResponse result = cvService.getCvById(10L, 1L);

        assertThat(result.getId()).isEqualTo(10L);
        assertThat(result.getTitre()).isEqualTo("Mon CV");
    }

    @Test
    void getCvById_avecIdInconnu_devraitLeverException() {
        when(cvRepository.findByIdAndUserId(99L, 1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> cvService.getCvById(99L, 1L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("non trouve");
    }

    @Test
    void createCv_devraitSauvegarderEtRetournerLeCv() {
        User user = buildUser();
        CvRequest request = new CvRequest();
        request.setTitre("Nouveau CV");

        Cv saved = buildCv(user);
        saved.setTitre("Nouveau CV");
        CvResponse response = CvResponse.builder().id(10L).titre("Nouveau CV").build();

        when(userService.findById(1L)).thenReturn(user);
        when(cvRepository.save(any(Cv.class))).thenReturn(saved);
        when(cvMapper.toResponse(any(Cv.class))).thenReturn(response);

        CvResponse result = cvService.createCv(request, 1L);

        assertThat(result.getTitre()).isEqualTo("Nouveau CV");
        verify(cvRepository, times(2)).save(any(Cv.class));
    }

    @Test
    void deleteCv_avecIdValide_devraitSupprimerLeCv() {
        when(cvRepository.existsByIdAndUserId(10L, 1L)).thenReturn(true);

        cvService.deleteCv(10L, 1L);

        verify(cvRepository).deleteById(10L);
    }

    @Test
    void deleteCv_avecIdInconnu_devraitLeverException() {
        when(cvRepository.existsByIdAndUserId(99L, 1L)).thenReturn(false);

        assertThatThrownBy(() -> cvService.deleteCv(99L, 1L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("non trouve");

        verify(cvRepository, never()).deleteById(any());
    }

    // ── Tests analytics ─────────────────────────────────────────

    @Test
    void trackView_devraitIncrementerLeCompteur() {
        User user = buildUser();
        Cv cv = buildCv(user);
        cv.setPublicToken("abc123");
        cv.setViewCount(5);

        when(cvRepository.findByPublicToken("abc123")).thenReturn(java.util.Optional.of(cv));
        when(cvViewRepository.existsByCvIdAndIpHashAndViewedAtAfter(
                any(), any(), any())).thenReturn(false);

        cvService.trackView("abc123", "192.168.1.1");

        verify(cvViewRepository).save(any(com.cvmobile.model.CvView.class));
        verify(cvRepository).save(cv);
        assertThat(cv.getViewCount()).isEqualTo(6);
    }

    @Test
    void trackView_devraitIgnorerVueRecenteDuMemeVisiteur() {
        User user = buildUser();
        Cv cv = buildCv(user);
        cv.setPublicToken("abc123");
        cv.setViewCount(5);

        when(cvRepository.findByPublicToken("abc123")).thenReturn(java.util.Optional.of(cv));
        when(cvViewRepository.existsByCvIdAndIpHashAndViewedAtAfter(
                any(), any(), any())).thenReturn(true);

        cvService.trackView("abc123", "192.168.1.1");

        verify(cvViewRepository, never()).save(any());
        verify(cvRepository, never()).save(any());
        assertThat(cv.getViewCount()).isEqualTo(5);
    }
}
