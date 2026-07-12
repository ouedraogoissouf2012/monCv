package com.cvmobile.service;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.*;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.ai.IEnhancementService;
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
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CvServiceTest {

    @Mock private CvRepository cvRepository;
    @Mock private IUserService userService;
    @Mock private CvMapper cvMapper;
    @Mock private IEnhancementService enhancementService;

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

    // ── Tests existants ─────────────────────────────────────────

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

    // ── Tests variantes ─────────────────────────────────────────

    private EnhanceCvResponse buildAdaptedResponse() {
        return EnhanceCvResponse.builder()
                .titrePoste("Developpeur Backend Senior")
                .resumeProfessionnel("Resume adapte pour l'offre")
                .titreOffre("Developpeur Backend Java — Sopra Steria")
                .experiences(List.of())
                .educations(List.of())
                .skills(List.of(EnhanceCvResponse.SkillEnhancement.builder().nom("Java").niveau(5).build()))
                .projects(List.of())
                .aiGenerated(true)
                .level("MAX")
                .build();
    }

    @Test
    void createVariant_devraitDupliquerEtAppliquerContenuIA() {
        User user = buildUser();
        Cv original = buildCv(user);
        original.setPersonalInfo(PersonalInfo.builder().titrePoste("Dev").resumeProfessionnel("Resume original").build());
        EnhanceCvResponse adapted = buildAdaptedResponse();
        CvResponse expectedResponse = CvResponse.builder()
                .id(20L).titre("Mon CV — Developpeur Backend Java — Sopra Steria")
                .varianteLabel("Developpeur Backend Java — Sopra Steria").parentCvId(10L).build();

        when(cvRepository.findByIdAndUserId(10L, 1L)).thenReturn(Optional.of(original));
        when(userService.findById(1L)).thenReturn(user);
        when(enhancementService.adaptCvToJob(10L, "Offre d'emploi")).thenReturn(adapted);
        when(cvMapper.clonePersonalInfo(any())).thenReturn(
                PersonalInfo.builder().titrePoste("Dev").resumeProfessionnel("Resume original").build());
        when(cvRepository.save(any(Cv.class))).thenAnswer(inv -> {
            Cv cv = inv.getArgument(0);
            cv.setId(20L);
            return cv;
        });
        when(cvMapper.toResponse(any(Cv.class))).thenReturn(expectedResponse);

        CvResponse result = cvService.createVariant(10L, "Offre d'emploi", null, 1L);

        assertThat(result.getVarianteLabel()).isEqualTo("Developpeur Backend Java — Sopra Steria");
        assertThat(result.getParentCvId()).isEqualTo(10L);
        verify(enhancementService).adaptCvToJob(10L, "Offre d'emploi");
        verify(cvRepository, times(2)).save(any(Cv.class));
    }

    @Test
    void createVariant_avecLabelCustom_devraitUtiliserLabelFourni() {
        User user = buildUser();
        Cv original = buildCv(user);
        EnhanceCvResponse adapted = buildAdaptedResponse();
        CvResponse expectedResponse = CvResponse.builder()
                .id(20L).titre("Mon CV — Mon label custom").varianteLabel("Mon label custom").build();

        when(cvRepository.findByIdAndUserId(10L, 1L)).thenReturn(Optional.of(original));
        when(userService.findById(1L)).thenReturn(user);
        when(enhancementService.adaptCvToJob(10L, "Offre")).thenReturn(adapted);
        when(cvRepository.save(any(Cv.class))).thenAnswer(inv -> inv.getArgument(0));
        when(cvMapper.toResponse(any(Cv.class))).thenReturn(expectedResponse);

        CvResponse result = cvService.createVariant(10L, "Offre", "Mon label custom", 1L);

        assertThat(result.getVarianteLabel()).isEqualTo("Mon label custom");
    }

    @Test
    void createVariant_cvInexistant_devraitLeverException() {
        when(cvRepository.findByIdAndUserId(99L, 1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> cvService.createVariant(99L, "Offre", null, 1L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("non trouve");
    }

    @Test
    void createVariant_mauvaisUser_devraitLeverException() {
        when(cvRepository.findByIdAndUserId(10L, 2L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> cvService.createVariant(10L, "Offre", null, 2L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void getVariantsByParentId_devraitRetournerUniquementVariantes() {
        Cv variant1 = Cv.builder().id(20L).titre("Variante 1").build();
        Cv variant2 = Cv.builder().id(21L).titre("Variante 2").build();
        CvResponse r1 = CvResponse.builder().id(20L).titre("Variante 1").build();
        CvResponse r2 = CvResponse.builder().id(21L).titre("Variante 2").build();

        when(cvRepository.findByParentIdAndUserId(10L, 1L)).thenReturn(List.of(variant1, variant2));
        when(cvMapper.toResponse(variant1)).thenReturn(r1);
        when(cvMapper.toResponse(variant2)).thenReturn(r2);

        List<CvResponse> result = cvService.getVariantsByParentId(10L, 1L);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).getTitre()).isEqualTo("Variante 1");
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
}
