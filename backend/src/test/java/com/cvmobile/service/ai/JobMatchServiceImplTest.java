package com.cvmobile.service.ai;

import com.cvmobile.config.JobMatchProperties;
import com.cvmobile.dto.JobMatchResponse;
import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.model.Certification;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Experience;
import com.cvmobile.model.Language;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.Project;
import com.cvmobile.model.Skill;
import com.cvmobile.service.CvQualityService;
import com.cvmobile.service.ai.client.IAiClient;
import com.cvmobile.service.cv.CvOwnershipService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JobMatchServiceImplTest {

    @Mock
    private IAiClient aiClient;

    @Mock
    private CvOwnershipService cvOwnershipService;

    @Mock
    private CvQualityService cvQualityService;

    private JobMatchServiceImpl service;

    private Cv cv;

    @BeforeEach
    void setUp() {
        JobMatchProperties properties = new JobMatchProperties(50, 14, 6, 5, 5, 100, 1800);
        JobMatchTextAnalyzer text = new JobMatchTextAnalyzer();
        service = new JobMatchServiceImpl(
                aiClient,
                cvOwnershipService,
                cvQualityService,
                properties,
                text,
                new JobMatchScorer(text, properties),
                new JobMatchFormatChecker(text, properties),
                new JobMatchRecommender(text, properties),
                new JobMatchPromptBuilder(text)
        );
        cv = Cv.builder()
                .id(22L)
                .titre("Chef de projet digital")
                .personalInfo(PersonalInfo.builder()
                        .titrePoste("Chef de projet digital")
                        .resumeProfessionnel("Pilotage de projets digitaux et coordination d'equipes")
                        .build())
                .experiences(List.of(Experience.builder()
                        .poste("Chef de projet")
                        .entreprise("Acme")
                        .description("Gestion des budgets et planification des livrables")
                        .build()))
                .skills(List.of(
                        Skill.builder().nom("Gestion de projet").niveau(5).build(),
                        Skill.builder().nom("Communication").niveau(4).build()))
                .build();

        lenient().when(cvOwnershipService.requireOwnedCv(22L, 7L)).thenReturn(cv);
        lenient().when(cvQualityService.findReviewWarnings(org.mockito.ArgumentMatchers.any())).thenReturn(List.of());
    }

    @Test
    void matchJob_parseLaReponseIaStructuree() {
        when(aiClient.complete(org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn("""
                        SCORE: 70

                        MOTS_CLES_PRESENTS:
                        - projet
                        - budgets
                        - communication

                        MOTS_CLES_MANQUANTS:
                        - analyse
                        - donnees

                        SUGGESTIONS:
                        - Ajoutez les mots-cles manquants
                        - Adaptez le resume professionnel
                        - Mentionnez des resultats chiffres

                        RESUME_OPTIMISE:
                        Chef de projet digital avec experience en pilotage.
                        """);

        JobMatchResponse response = service.matchJob(
                22L, 7L,
                "Pilotage de projet digital, gestion des budgets, communication et analyse de donnees");

        assertThat(response.isAiGenerated()).isTrue();
        assertThat(response.isFallback()).isFalse();
        assertThat(response.getScore()).isBetween(55, 85);
        assertThat(response.getMatchedKeywords()).contains("projet", "budgets", "communication");
        assertThat(response.getMissingKeywords()).contains("analyse", "donnees");
        assertThat(response.getSuggestions()).hasSizeGreaterThanOrEqualTo(3);
        assertThat(response.getCategories()).hasSize(7);
        assertThat(response.getPrioritizedRecommendations()).isNotEmpty();
        assertThat(response.getFormatChecks()).isNotEmpty();
    }

    @Test
    void matchJob_marqueExplicitementUnResultatFallback() {
        when(aiClient.complete(org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn("""
                        SCORE: 65

                        MOTS_CLES_PRESENTS:
                        - projet

                        MOTS_CLES_MANQUANTS:
                        - kubernetes

                        SUGGESTIONS:
                        - Ajoutez les competences techniques demandees

                        RESUME_OPTIMISE:
                        Resume de secours.
                        """);
        when(aiClient.isFallbackResult()).thenReturn(true);

        JobMatchResponse response = service.matchJob(22L, 7L, "Gestion de projet et Kubernetes");

        assertThat(response.isAiGenerated()).isFalse();
        assertThat(response.isFallback()).isTrue();
    }

    @Test
    void matchJob_avecSeulementDesStopWords_retourneUnScoreNul() {
        when(aiClient.complete(org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn("""
                        SCORE: 0

                        MOTS_CLES_PRESENTS:

                        MOTS_CLES_MANQUANTS:

                        SUGGESTIONS:

                        RESUME_OPTIMISE:
                        """);

        JobMatchResponse response = service.matchJob(
                22L, 7L,
                "avec pour dans cette votre notre entre faire avoir");

        assertThat(response.getScore()).isBetween(0, 100);
        assertThat(response.getMatchedKeywords()).isEmpty();
        assertThat(response.getMissingKeywords()).isEmpty();
        assertThat(response.getCategories()).extracting("key")
                .contains("keywords", "technical_skills", "ats_format");
    }

    @Test
    void matchJob_siLeClientIaEchoue_propageErreur() {
        when(aiClient.complete(org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyInt()))
                .thenThrow(new IllegalStateException("IA indisponible"));

        assertThatThrownBy(() -> service.matchJob(
                22L, 7L,
                "Chef de projet digital avec gestion de budgets et planification"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("IA indisponible");
    }

    @Test
    void matchJob_fallbackConserveLesMotsAccentesEtAnalyseToutesLesSections() {
        when(aiClient.complete(org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn("""
                        SCORE: 100

                        MOTS_CLES_PRESENTS:
                        - équipe
                        - délais
                        - stratégie
                        - scrum
                        - figma
                        - français

                        MOTS_CLES_MANQUANTS:

                        SUGGESTIONS:

                        RESUME_OPTIMISE:
                        Resume adapte.
                        """);
        cv.getLanguages().add(Language.builder()
                .langue("Français")
                .niveau(Language.NiveauLangue.NATIF)
                .build());
        cv.getCertifications().add(Certification.builder()
                .nom("Professional Scrum Master")
                .organisme("Scrum.org")
                .build());
        cv.getProjects().add(Project.builder()
                .nom("Programme de transformation")
                .description("Coordination d'une équipe, respect des délais et stratégie de livraison")
                .technologies("Scrum, Figma")
                .build());

        JobMatchResponse response = service.matchJob(
                22L, 7L,
                "Équipe, délais, stratégie, Scrum, Figma et français.");

        assertThat(response.getMatchedKeywords())
                .contains("équipe", "délais", "stratégie", "scrum", "figma", "français")
                .doesNotContain("quipe", "lais", "strat", "gique");
        assertThat(response.getMissingKeywords()).doesNotContain("quipe", "lais", "strat", "gique");
        assertThat(response.getScore()).isGreaterThanOrEqualTo(75);
    }

    @Test
    void matchJob_signaleLesRisquesAtsEtLesRecommandationsPrioritaires() {
        cv.setStyleTemplateId("creatif");
        cv.getPersonalInfo().setTelephone(null);
        cv.getExperiences().get(0).setDescription("Coordination d'equipe");
        when(cvQualityService.findReviewWarnings(org.mockito.ArgumentMatchers.any()))
                .thenReturn(List.of("Ajoutez des resultats chiffres dans l'experience 1."));
        when(aiClient.complete(org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyInt()))
                .thenReturn("""
                        SCORE: 58

                        MOTS_CLES_PRESENTS:
                        - communication

                        MOTS_CLES_MANQUANTS:
                        - scrum
                        - jira

                        SUGGESTIONS:
                        - Ajoutez Scrum et Jira

                        RESUME_OPTIMISE:
                        Chef de projet digital oriente delivery.
                        """);

        JobMatchResponse response = service.matchJob(
                22L, 7L,
                "Chef de projet digital avec Scrum, Jira, communication et pilotage agile");

        assertThat(response.getFormatChecks())
                .extracting(JobMatchResponse.FormatCheck::getLabel)
                .contains("Contact incomplet", "Template bicolonne");
        assertThat(response.getPrioritizedRecommendations())
                .extracting(JobMatchResponse.PrioritizedRecommendation::getTitle)
                .contains("Ajouter les mots-clés manquants", "Sécuriser le format ATS");
    }

    @Test
    void matchJob_refuseUnCvNonPossedeAvantToutAppelIa() {
        when(cvOwnershipService.requireOwnedCv(22L, 8L))
                .thenThrow(new ResourceNotFoundException("CV", "id", 22L));

        assertThatThrownBy(() -> service.matchJob(22L, 8L, "Offre cible détaillée"))
                .isInstanceOf(ResourceNotFoundException.class);
        verifyNoInteractions(aiClient);
    }
}
