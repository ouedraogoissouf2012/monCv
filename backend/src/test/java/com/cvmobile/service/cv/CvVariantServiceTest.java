package com.cvmobile.service.cv;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.Cv;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.User;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.ai.IEnhancementService;
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
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CvVariantServiceTest {

    @Mock private CvRepository cvRepository;
    @Mock private IUserService userService;
    @Mock private CvMapper cvMapper;
    @Mock private IEnhancementService enhancementService;
    @Mock private CvFinder cvFinder;

    @InjectMocks
    private CvVariantService variantService;

    private User buildUser() {
        return User.builder().id(1L).email("user@example.com").role(User.Role.USER).build();
    }

    private Cv buildCv(User user) {
        return Cv.builder().id(10L).titre("Mon CV").user(user).build();
    }

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

        when(cvFinder.findByIdAndUserId(10L, 1L)).thenReturn(original);
        when(userService.findById(1L)).thenReturn(user);
        when(enhancementService.adaptCvToJob(10L, 1L, "Offre d'emploi")).thenReturn(adapted);
        when(cvMapper.clonePersonalInfo(any())).thenReturn(
                PersonalInfo.builder().titrePoste("Dev").resumeProfessionnel("Resume original").build());
        when(cvRepository.save(any(Cv.class))).thenAnswer(inv -> {
            Cv cv = inv.getArgument(0);
            cv.setId(20L);
            return cv;
        });
        when(cvMapper.toResponse(any(Cv.class))).thenReturn(expectedResponse);

        CvResponse result = variantService.createVariant(10L, "Offre d'emploi", null, 1L);

        assertThat(result.getVarianteLabel()).isEqualTo("Developpeur Backend Java — Sopra Steria");
        assertThat(result.getParentCvId()).isEqualTo(10L);
        verify(enhancementService).adaptCvToJob(10L, 1L, "Offre d'emploi");
        verify(cvRepository, times(2)).save(any(Cv.class));
    }

    @Test
    void createVariant_avecLabelCustom_devraitUtiliserLabelFourni() {
        User user = buildUser();
        Cv original = buildCv(user);
        EnhanceCvResponse adapted = buildAdaptedResponse();
        CvResponse expectedResponse = CvResponse.builder()
                .id(20L).titre("Mon CV — Mon label custom").varianteLabel("Mon label custom").build();

        when(cvFinder.findByIdAndUserId(10L, 1L)).thenReturn(original);
        when(userService.findById(1L)).thenReturn(user);
        when(enhancementService.adaptCvToJob(10L, 1L, "Offre")).thenReturn(adapted);
        when(cvRepository.save(any(Cv.class))).thenAnswer(inv -> inv.getArgument(0));
        when(cvMapper.toResponse(any(Cv.class))).thenReturn(expectedResponse);

        CvResponse result = variantService.createVariant(10L, "Offre", "Mon label custom", 1L);

        assertThat(result.getVarianteLabel()).isEqualTo("Mon label custom");
    }

    @Test
    void createVariant_cvInexistant_devraitLeverException() {
        when(cvFinder.findByIdAndUserId(99L, 1L))
                .thenThrow(new ResourceNotFoundException("CV", "id", 99L));

        assertThatThrownBy(() -> variantService.createVariant(99L, "Offre", null, 1L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("non trouve");
    }

    @Test
    void createVariant_mauvaisUser_devraitLeverException() {
        when(cvFinder.findByIdAndUserId(10L, 2L))
                .thenThrow(new ResourceNotFoundException("CV", "id", 10L));

        assertThatThrownBy(() -> variantService.createVariant(10L, "Offre", null, 2L))
                .isInstanceOf(ResourceNotFoundException.class);
        verifyNoInteractions(enhancementService);
    }

    @Test
    void getVariantsByParentId_devraitRetournerLesVariantes() {
        Cv variant1 = Cv.builder().id(20L).titre("Variante 1").build();
        Cv variant2 = Cv.builder().id(21L).titre("Variante 2").build();
        CvResponse r1 = CvResponse.builder().id(20L).titre("Variante 1").build();
        CvResponse r2 = CvResponse.builder().id(21L).titre("Variante 2").build();

        when(cvRepository.findByParentIdAndUserId(10L, 1L)).thenReturn(List.of(variant1, variant2));
        when(cvMapper.toResponse(variant1)).thenReturn(r1);
        when(cvMapper.toResponse(variant2)).thenReturn(r2);

        List<CvResponse> result = variantService.getVariantsByParentId(10L, 1L);

        assertThat(result).hasSize(2);
        assertThat(result.get(0).getTitre()).isEqualTo("Variante 1");
    }
}
