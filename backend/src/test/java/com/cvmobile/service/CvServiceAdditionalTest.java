package com.cvmobile.service;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.PublicShareSettingsRequest;
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
 * Complement de {@link CvServiceTest} (issue #231) : duplication, delegations
 * de partage/variantes restantes et branches vraies de collections/style,
 * separe pour respecter la limite de 300 lignes.
 */
@ExtendWith(MockitoExtension.class)
class CvServiceAdditionalTest {

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

    // ── Delegations restantes ─────────────────────────────────────

    @Test
    void regenerateShareToken_devraitDeleguerAuServiceDePartage() {
        CvResponse response = CvResponse.builder().id(10L).publicToken("nouveau-tok").build();
        when(shareService.regenerateShareToken(10L, 1L)).thenReturn(response);

        CvResponse result = cvService.regenerateShareToken(10L, 1L);

        assertThat(result.getPublicToken()).isEqualTo("nouveau-tok");
        verify(shareService).regenerateShareToken(10L, 1L);
    }

    @Test
    void deactivateShare_devraitDeleguerAuServiceDePartage() {
        CvResponse response = CvResponse.builder().id(10L).publicToken(null).build();
        when(shareService.deactivateShare(10L, 1L)).thenReturn(response);

        CvResponse result = cvService.deactivateShare(10L, 1L);

        assertThat(result.getPublicToken()).isNull();
        verify(shareService).deactivateShare(10L, 1L);
    }

    @Test
    void updateShareSettings_devraitDeleguerAuServiceDePartage() {
        PublicShareSettingsRequest request = new PublicShareSettingsRequest();
        CvResponse response = CvResponse.builder().id(10L).build();
        when(shareService.updateShareSettings(10L, request, 1L)).thenReturn(response);

        CvResponse result = cvService.updateShareSettings(10L, request, 1L);

        assertThat(result).isSameAs(response);
        verify(shareService).updateShareSettings(10L, request, 1L);
    }

    @Test
    void getVariantsByParentId_devraitDeleguerAuServiceDeVariantes() {
        List<CvResponse> variants = List.of(CvResponse.builder().id(20L).build());
        when(variantService.getVariantsByParentId(10L, 1L)).thenReturn(variants);

        List<CvResponse> result = cvService.getVariantsByParentId(10L, 1L);

        assertThat(result).isSameAs(variants);
        verify(variantService).getVariantsByParentId(10L, 1L);
    }

    // ── Duplication ─────────────────────────────────────────────

    @Test
    void duplicateCv_devraitCloneToutesLesCollectionsEtLePersonalInfo() {
        User user = buildUser();
        Cv original = buildCv(user);
        original.setStyleTemplateId("moderne");
        original.setStylePrimaryColor(123456L);
        original.setStyleFontFamily("Roboto");
        original.setPersonalInfo(PersonalInfo.builder().titrePoste("Dev").build());
        original.addEducation(Education.builder().etablissement("U").build());
        original.addExperience(Experience.builder().poste("Dev").build());
        original.addSkill(Skill.builder().nom("Java").build());
        original.addLanguage(Language.builder().langue("Francais").build());
        original.addCertification(Certification.builder().nom("Cert").build());
        original.addProject(Project.builder().nom("Projet").build());

        PersonalInfo clonedInfo = PersonalInfo.builder().titrePoste("Dev").build();
        Cv savedCopy = Cv.builder().id(11L).titre("Copie de Mon CV").user(user).build();
        CvResponse response = CvResponse.builder().id(11L).titre("Copie de Mon CV").build();

        when(cvFinder.findByIdAndUserId(10L, 1L)).thenReturn(original);
        when(userService.findById(1L)).thenReturn(user);
        when(cvMapper.clonePersonalInfo(original.getPersonalInfo())).thenReturn(clonedInfo);
        when(cvMapper.cloneEducation(any())).thenReturn(Education.builder().etablissement("U").build());
        when(cvMapper.cloneExperience(any())).thenReturn(Experience.builder().poste("Dev").build());
        when(cvMapper.cloneSkill(any())).thenReturn(Skill.builder().nom("Java").build());
        when(cvMapper.cloneLanguage(any())).thenReturn(Language.builder().langue("Francais").build());
        when(cvMapper.cloneCertification(any())).thenReturn(Certification.builder().nom("Cert").build());
        when(cvMapper.cloneProject(any())).thenReturn(Project.builder().nom("Projet").build());
        when(cvRepository.save(any(Cv.class))).thenReturn(savedCopy);
        when(cvMapper.toResponse(savedCopy)).thenReturn(response);

        CvResponse result = cvService.duplicateCv(10L, 1L);

        assertThat(result.getTitre()).isEqualTo("Copie de Mon CV");
        verify(cvRepository, times(2)).save(any(Cv.class));
        verify(cvMapper).cloneEducation(any());
        verify(cvMapper).cloneExperience(any());
        verify(cvMapper).cloneSkill(any());
        verify(cvMapper).cloneLanguage(any());
        verify(cvMapper).cloneCertification(any());
        verify(cvMapper).cloneProject(any());
    }

    @Test
    void duplicateCv_sansPersonalInfo_neCloneRienDeCePersonalInfo() {
        User user = buildUser();
        Cv original = buildCv(user); // personalInfo null par defaut
        Cv savedCopy = Cv.builder().id(11L).titre("Copie de Mon CV").user(user).build();
        CvResponse response = CvResponse.builder().id(11L).build();

        when(cvFinder.findByIdAndUserId(10L, 1L)).thenReturn(original);
        when(userService.findById(1L)).thenReturn(user);
        when(cvRepository.save(any(Cv.class))).thenReturn(savedCopy);
        when(cvMapper.toResponse(savedCopy)).thenReturn(response);

        cvService.duplicateCv(10L, 1L);

        verify(cvMapper, never()).clonePersonalInfo(any());
    }

    @Test
    void duplicateCv_avecIdInconnu_devraitPropagerException() {
        when(cvFinder.findByIdAndUserId(99L, 1L))
                .thenThrow(new ResourceNotFoundException("CV", "id", 99L));

        assertThatThrownBy(() -> cvService.duplicateCv(99L, 1L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ── Creation : collections et style (branches vraies) ────────

    @Test
    void createCv_avecCollectionsEtStyle_devraitToutAppliquer() {
        User user = buildUser();
        CvRequest request = new CvRequest();
        request.setTitre("CV complet");
        request.setPersonalInfo(new CvRequest.PersonalInfoDto());
        request.setEducations(List.of(new CvRequest.EducationDto()));
        request.setExperiences(List.of(new CvRequest.ExperienceDto()));
        request.setSkills(List.of(new CvRequest.SkillDto()));
        request.setLanguages(List.of(new CvRequest.LanguageDto()));
        request.setCertifications(List.of(new CvRequest.CertificationDto()));
        request.setProjects(List.of(new CvRequest.ProjectDto()));
        request.setStyle(CvRequest.StyleDto.builder()
                .templateId("moderne").primaryColor(123L).fontFamily("Roboto").build());

        Cv saved = buildCv(user);
        CvResponse response = CvResponse.builder().id(10L).titre("CV complet").build();

        when(userService.findById(1L)).thenReturn(user);
        when(cvMapper.toPersonalInfo(any())).thenReturn(PersonalInfo.builder().build());
        when(cvMapper.toEducation(any())).thenReturn(Education.builder().build());
        when(cvMapper.toExperience(any())).thenReturn(Experience.builder().build());
        when(cvMapper.toSkill(any())).thenReturn(Skill.builder().build());
        when(cvMapper.toLanguage(any())).thenReturn(Language.builder().build());
        when(cvMapper.toCertification(any())).thenReturn(Certification.builder().build());
        when(cvMapper.toProject(any())).thenReturn(Project.builder().build());
        when(cvRepository.save(any(Cv.class))).thenReturn(saved);
        when(cvMapper.toResponse(any(Cv.class))).thenReturn(response);

        cvService.createCv(request, 1L);

        verify(cvMapper).toEducation(any());
        verify(cvMapper).toExperience(any());
        verify(cvMapper).toSkill(any());
        verify(cvMapper).toLanguage(any());
        verify(cvMapper).toCertification(any());
        verify(cvMapper).toProject(any());
        // Style applique : template non-defaut remonte dans la metrique.
        verify(businessMetrics).recordCvCreated("moderne");
    }
}
