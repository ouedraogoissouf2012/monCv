package com.cvmobile.service;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.Cv;
import com.cvmobile.model.User;
import com.cvmobile.observability.BusinessMetrics;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.cv.CvCollectionMerger;
import com.cvmobile.service.cv.CvFinder;
import com.cvmobile.service.cv.CvShareService;
import com.cvmobile.service.cv.CvVariantService;
import com.cvmobile.service.user.IUserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Teste la facade CRUD {@link CvService} : operations propres (lecture,
 * creation, mise a jour, suppression) et delegation aux collaborateurs
 * (variantes, partage). Les logiques deleguees sont testees dans leurs propres
 * classes de test.
 */
@ExtendWith(MockitoExtension.class)
class CvServiceTest {

    @Mock private CvRepository cvRepository;
    @Mock private IUserService userService;
    @Mock private CvMapper cvMapper;
    @Mock private BusinessMetrics businessMetrics;
    @Mock private CvFinder cvFinder;
    @Mock private CvCollectionMerger collectionMerger;
    @Mock private CvShareService shareService;
    @Mock private CvVariantService variantService;

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

    // ── Lecture ─────────────────────────────────────────────────

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
    void getAllCvsByUserId_devraitInclureVariantCount() {
        User user = buildUser();
        Cv parent = buildCv(user);
        CvResponse parentResponse = CvResponse.builder().id(10L).titre("Mon CV").build();

        when(cvRepository.findByUserIdWithDetails(1L)).thenReturn(List.of(parent));
        when(cvMapper.toResponse(parent)).thenReturn(parentResponse);
        List<Object[]> counts = new java.util.ArrayList<>();
        counts.add(new Object[]{10L, 3L});
        when(cvRepository.countVariantsByParentIds(List.of(10L))).thenReturn(counts);

        List<CvResponse> result = cvService.getAllCvsByUserId(1L);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getVariantCount()).isEqualTo(3);
    }

    @Test
    void getCvById_avecIdValide_devraitRetournerLeCv() {
        User user = buildUser();
        Cv cv = buildCv(user);
        CvResponse response = buildCvResponse();

        when(cvFinder.findByIdAndUserId(10L, 1L)).thenReturn(cv);
        when(cvMapper.toResponse(cv)).thenReturn(response);

        CvResponse result = cvService.getCvById(10L, 1L);

        assertThat(result.getId()).isEqualTo(10L);
        assertThat(result.getTitre()).isEqualTo("Mon CV");
    }

    @Test
    void getCvById_avecIdInconnu_devraitPropagerException() {
        when(cvFinder.findByIdAndUserId(99L, 1L))
                .thenThrow(new ResourceNotFoundException("CV", "id", 99L));

        assertThatThrownBy(() -> cvService.getCvById(99L, 1L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("non trouve");
    }

    // ── Creation / mise a jour / suppression ────────────────────

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
        verify(businessMetrics).recordCvCreated("default");
    }

    @Test
    void updateCv_devraitFusionnerLesCollectionsEtSauvegarder() {
        User user = buildUser();
        Cv cv = buildCv(user);
        CvRequest request = new CvRequest();
        request.setTitre("CV mis a jour");
        CvResponse response = CvResponse.builder().id(10L).titre("CV mis a jour").build();

        when(cvFinder.findByIdAndUserId(10L, 1L)).thenReturn(cv);
        when(cvRepository.save(cv)).thenReturn(cv);
        when(cvMapper.toResponse(cv)).thenReturn(response);

        CvResponse result = cvService.updateCv(10L, request, 1L);

        assertThat(result.getTitre()).isEqualTo("CV mis a jour");
        assertThat(cv.getTitre()).isEqualTo("CV mis a jour");
        verify(collectionMerger).mergeCollections(cv, request);
        verify(cvRepository).save(cv);
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

    // ── Delegation ──────────────────────────────────────────────

    @Test
    void createVariant_devraitDeleguerAuServiceDeVariantes() {
        CvResponse response = CvResponse.builder().id(20L).titre("Variante").build();
        when(variantService.createVariant(10L, "Offre", "Label", 1L)).thenReturn(response);

        CvResponse result = cvService.createVariant(10L, "Offre", "Label", 1L);

        assertThat(result).isSameAs(response);
        verify(variantService).createVariant(10L, "Offre", "Label", 1L);
    }

    @Test
    void generateShareToken_devraitDeleguerAuServiceDePartage() {
        CvResponse response = CvResponse.builder().id(10L).publicToken("tok").build();
        when(shareService.generateShareToken(10L, 1L)).thenReturn(response);

        CvResponse result = cvService.generateShareToken(10L, 1L);

        assertThat(result.getPublicToken()).isEqualTo("tok");
        verify(shareService).generateShareToken(10L, 1L);
    }
}
