package com.cvmobile.service.cv;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.Certification;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Education;
import com.cvmobile.model.Experience;
import com.cvmobile.model.Language;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.Project;
import com.cvmobile.model.Skill;
import com.cvmobile.model.User;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.ai.IEnhancementService;
import com.cvmobile.service.user.IUserService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
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

    // ── adaptToJob : appel IA, hors transaction, sans persistance (M-4) ──

    @Test
    void adaptToJob_delegueAuServiceDAmelioration_sansToucherLaDb() {
        EnhanceCvResponse adapted = buildAdaptedResponse();
        when(enhancementService.adaptCvToJob(10L, 1L, "Offre")).thenReturn(adapted);

        EnhanceCvResponse result = variantService.adaptToJob(10L, 1L, "Offre");

        assertThat(result).isSameAs(adapted);
        verify(enhancementService).adaptCvToJob(10L, 1L, "Offre");
        // La phase IA ne persiste rien : aucune ecriture DB avant l'adaptation.
        verifyNoInteractions(cvRepository);
    }

    @Test
    void adaptToJob_cvNonDetenu_propageLException_avantToutePersistance() {
        // L'ownership est verifie dans adaptCvToJob (requireOwnedCv) : un CV tiers
        // leve avant meme l'appel IA reel ; la persistance n'est jamais atteinte.
        when(enhancementService.adaptCvToJob(10L, 2L, "Offre"))
                .thenThrow(new ResourceNotFoundException("CV", "id", 10L));

        assertThatThrownBy(() -> variantService.adaptToJob(10L, 2L, "Offre"))
                .isInstanceOf(ResourceNotFoundException.class);
        verifyNoInteractions(cvRepository);
    }

    // ── persistVariant : ecriture transactionnelle, SANS appel IA (M-4) ──

    @Test
    void persistVariant_dupliqueEtAppliqueContenuIA() {
        User user = buildUser();
        Cv original = buildCv(user);
        original.setPersonalInfo(PersonalInfo.builder().titrePoste("Dev").resumeProfessionnel("Resume original").build());
        EnhanceCvResponse adapted = buildAdaptedResponse();
        CvResponse expectedResponse = CvResponse.builder()
                .id(20L).titre("Mon CV — Developpeur Backend Java — Sopra Steria")
                .varianteLabel("Developpeur Backend Java — Sopra Steria").parentCvId(10L).build();

        when(cvFinder.findByIdAndUserId(10L, 1L)).thenReturn(original);
        when(userService.findById(1L)).thenReturn(user);
        when(cvMapper.clonePersonalInfo(any())).thenReturn(
                PersonalInfo.builder().titrePoste("Dev").resumeProfessionnel("Resume original").build());
        when(cvRepository.save(any(Cv.class))).thenAnswer(inv -> {
            Cv cv = inv.getArgument(0);
            cv.setId(20L);
            return cv;
        });
        when(cvMapper.toResponse(any(Cv.class))).thenReturn(expectedResponse);

        CvResponse result = variantService.persistVariant(10L, "Offre d'emploi", null, 1L, adapted);

        assertThat(result.getVarianteLabel()).isEqualTo("Developpeur Backend Java — Sopra Steria");
        assertThat(result.getParentCvId()).isEqualTo(10L);
        verify(cvRepository, times(2)).save(any(Cv.class));
        // La persistance ne rappelle jamais l'IA : le round-trip est deja fait.
        verifyNoInteractions(enhancementService);
    }

    @Test
    void persistVariant_avecLabelCustom_utiliseLabelFourni() {
        User user = buildUser();
        Cv original = buildCv(user);
        EnhanceCvResponse adapted = buildAdaptedResponse();
        CvResponse expectedResponse = CvResponse.builder()
                .id(20L).titre("Mon CV — Mon label custom").varianteLabel("Mon label custom").build();

        when(cvFinder.findByIdAndUserId(10L, 1L)).thenReturn(original);
        when(userService.findById(1L)).thenReturn(user);
        when(cvRepository.save(any(Cv.class))).thenAnswer(inv -> inv.getArgument(0));
        when(cvMapper.toResponse(any(Cv.class))).thenReturn(expectedResponse);

        CvResponse result = variantService.persistVariant(10L, "Offre", "Mon label custom", 1L, adapted);

        assertThat(result.getVarianteLabel()).isEqualTo("Mon label custom");
    }

    @Test
    void persistVariant_cvInexistant_devraitLeverException() {
        when(cvFinder.findByIdAndUserId(99L, 1L))
                .thenThrow(new ResourceNotFoundException("CV", "id", 99L));

        assertThatThrownBy(() ->
                variantService.persistVariant(99L, "Offre", null, 1L, buildAdaptedResponse()))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("non trouve");
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

    @Test
    void persistVariant_copieToutesLesSectionsEtDeduitLeLabelDeLOffre() {
        // Sans label utilisateur ni titre d'offre IA, le label retombe sur la
        // premiere ligne de l'offre ; sans competences adaptees, les originales
        // sont copiees ; chaque section originale est dupliquee.
        User user = buildUser();
        Cv original = Cv.builder().id(10L).titre("Mon CV").user(user)
                .experiences(List.of(Experience.builder().poste("Dev").entreprise("A").description("orig").build()))
                .educations(List.of(Education.builder().etablissement("U").diplome("M").build()))
                .projects(List.of(Project.builder().nom("P").build()))
                .skills(List.of(Skill.builder().nom("Java").niveau(4).build()))
                .languages(List.of(Language.builder().langue("Francais").niveau(Language.NiveauLangue.NATIF).build()))
                .certifications(List.of(Certification.builder().nom("C").organisme("O").build()))
                .build();
        EnhanceCvResponse adapted = EnhanceCvResponse.builder()
                .experiences(List.of()).educations(List.of()).projects(List.of())
                .skills(List.of()).build();

        when(cvFinder.findByIdAndUserId(10L, 1L)).thenReturn(original);
        when(userService.findById(1L)).thenReturn(user);
        when(cvMapper.cloneExperience(any())).thenReturn(Experience.builder().poste("Dev").build());
        when(cvMapper.cloneEducation(any())).thenReturn(Education.builder().etablissement("U").build());
        when(cvMapper.cloneProject(any())).thenReturn(Project.builder().nom("P").build());
        when(cvMapper.cloneSkill(any())).thenReturn(Skill.builder().nom("Java").niveau(4).build());
        when(cvMapper.cloneLanguage(any())).thenReturn(
                Language.builder().langue("Francais").niveau(Language.NiveauLangue.NATIF).build());
        when(cvMapper.cloneCertification(any())).thenReturn(Certification.builder().nom("C").build());
        when(cvRepository.save(any(Cv.class))).thenAnswer(inv -> inv.getArgument(0));
        when(cvMapper.toResponse(any(Cv.class))).thenReturn(CvResponse.builder().id(20L).build());

        variantService.persistVariant(10L, "Ingenieur logiciel\nParis", null, 1L, adapted);

        ArgumentCaptor<Cv> saved = ArgumentCaptor.forClass(Cv.class);
        verify(cvRepository, times(2)).save(saved.capture());
        Cv variant = saved.getAllValues().get(0);
        assertThat(variant.getVarianteLabel()).isEqualTo("Ingenieur logiciel");
        assertThat(variant.getExperiences()).hasSize(1);
        assertThat(variant.getEducations()).hasSize(1);
        assertThat(variant.getProjects()).hasSize(1);
        assertThat(variant.getSkills()).hasSize(1);
        assertThat(variant.getLanguages()).hasSize(1);
        assertThat(variant.getCertifications()).hasSize(1);
    }

    @Test
    void persistVariant_appliqueLesDescriptionsAdapteesParLIa() {
        User user = buildUser();
        Cv original = Cv.builder().id(10L).titre("Mon CV").user(user)
                .experiences(List.of(Experience.builder().poste("Dev").description("orig").build()))
                .educations(List.of(Education.builder().etablissement("U").description("orig").build()))
                .projects(List.of(Project.builder().nom("P").description("orig").build()))
                .build();
        EnhanceCvResponse adapted = EnhanceCvResponse.builder()
                .titreOffre("Backend Java")
                .experiences(List.of(EnhanceCvResponse.ExperienceEnhancement.builder()
                        .description("exp adaptee").build()))
                .educations(List.of(EnhanceCvResponse.EducationEnhancement.builder()
                        .description("edu adaptee").build()))
                .projects(List.of(EnhanceCvResponse.ProjectEnhancement.builder()
                        .description("proj adaptee").build()))
                .skills(List.of(EnhanceCvResponse.SkillEnhancement.builder().nom("Java").niveau(5).build()))
                .build();

        Experience expClone = Experience.builder().poste("Dev").build();
        Education eduClone = Education.builder().etablissement("U").build();
        Project projClone = Project.builder().nom("P").build();
        when(cvFinder.findByIdAndUserId(10L, 1L)).thenReturn(original);
        when(userService.findById(1L)).thenReturn(user);
        when(cvMapper.cloneExperience(any())).thenReturn(expClone);
        when(cvMapper.cloneEducation(any())).thenReturn(eduClone);
        when(cvMapper.cloneProject(any())).thenReturn(projClone);
        when(cvRepository.save(any(Cv.class))).thenAnswer(inv -> inv.getArgument(0));
        when(cvMapper.toResponse(any(Cv.class))).thenReturn(CvResponse.builder().id(20L).build());

        variantService.persistVariant(10L, "Offre", null, 1L, adapted);

        // Les descriptions IA remplacent celles des clones.
        assertThat(expClone.getDescription()).isEqualTo("exp adaptee");
        assertThat(eduClone.getDescription()).isEqualTo("edu adaptee");
        assertThat(projClone.getDescription()).isEqualTo("proj adaptee");
    }
}
