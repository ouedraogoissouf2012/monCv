package com.cvmobile.service.ai;

import com.cvmobile.config.AiEnhancementProperties;
import com.cvmobile.config.CvQualityProperties;
import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.model.Certification;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Education;
import com.cvmobile.model.Experience;
import com.cvmobile.model.Language;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.Project;
import com.cvmobile.model.Skill;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.CvQualityService;
import com.cvmobile.service.ai.client.IAiClient;
import com.cvmobile.service.notification.NotificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EnhancementServiceImplTest {

    @Mock
    private IAiClient aiClient;

    @Mock
    private CvRepository cvRepository;

    private EnhancementServiceImpl service;

    @BeforeEach
    void setUp() {
        CvQualityProperties qualityProperties = new CvQualityProperties(
                100, 20, 10, 5, 5, 100, 80, 10
        );
        service = new EnhancementServiceImpl(
                aiClient,
                cvRepository,
                new CvQualityService(qualityProperties),
                mock(NotificationService.class),
                new AiEnhancementProperties(3000),
                qualityProperties
        );
    }

    @Test
    void enhanceCvLiteSansIaCorrigeToutLeCvEtPreserveLesNiveaux() {
        Cv cv = Cv.builder()
                .id(42L)
                .titre("CV Community manager")
                .personalInfo(PersonalInfo.builder()
                        .titrePoste("Comminoty manager")
                        .resumeProfessionnel("Developpeur de contenus, gestion des reseaux et suivi du PRR")
                        .build())
                .experiences(List.of(Experience.builder()
                        .id(1L)
                        .poste("Comminoty manager")
                        .entreprise("Agence")
                        .description("Gere plusieurs projets en parallele")
                        .build()))
                .educations(List.of(Education.builder()
                        .id(2L)
                        .etablissement("lyce municipal")
                        .diplome("Baccalaureat")
                        .domaine("communication")
                        .description("Etude en communication")
                        .build()))
                .skills(List.of(
                        Skill.builder().id(3L).nom("world").niveau(1).build(),
                        Skill.builder().id(4L).nom("comminoty management").niveau(5).build()))
                .languages(List.of(Language.builder()
                        .id(5L).langue("Francais").niveau(Language.NiveauLangue.NATIF).build()))
                .certifications(List.of(Certification.builder()
                        .id(6L).nom("Certificat community managment").organisme("Universite").build()))
                .projects(List.of(Project.builder()
                        .id(7L).nom("Creation de contenus")
                        .technologies("excel, canva")
                        .description("Projet realise en equipe")
                        .build()))
                .build();
        when(cvRepository.findById(42L)).thenReturn(Optional.of(cv));
        when(aiClient.complete(org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn("""
                        TITRE_POSTE:
                        Community manager

                        RESUME:
                        Développeur de contenus, gestion des réseaux et suivi du PRR

                        EXP_1:
                        Gère plusieurs projets en parallèle

                        EDU_2:
                        Étude en communication

                        COMPETENCES:
                        Word, Community Management

                        PROJ_7:
                        Projet réalisé en équipe
                        """);

        EnhanceCvResponse response = service.enhanceCv(42L, "LITE");

        assertThat(response.isAiGenerated()).isTrue();
        assertThat(response.getTitrePoste()).isEqualTo("Community manager");
        assertThat(response.getResumeProfessionnel())
                .contains("Développeur", "réseaux");
        assertThat(response.getExperiences().get(0).getPoste()).isEqualTo("Community manager");
        assertThat(response.getEducations().get(0).getEtablissement()).isEqualTo("lycée municipal");
        assertThat(response.getSkills())
                .extracting(EnhanceCvResponse.SkillEnhancement::getNom)
                .containsExactly("Word", "Community Management");
        assertThat(response.getSkills())
                .extracting(EnhanceCvResponse.SkillEnhancement::getNiveau)
                .containsExactly(1, 5);
        assertThat(response.getLanguages().get(0).getLangue()).isEqualTo("Français");
        assertThat(response.getProjects().get(0).getTechnologies()).isEqualTo("Excel, Canva");
        assertThat(response.getWarnings()).anyMatch(message -> message.contains("PRR"));
        assertThat(response.getCorrectionCount()).isGreaterThanOrEqualTo(8);
    }
}
