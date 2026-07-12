package com.cvmobile.service.ai;

import com.cvmobile.dto.JobMatchResponse;
import com.cvmobile.model.Certification;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Experience;
import com.cvmobile.model.Language;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.Project;
import com.cvmobile.model.Skill;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.ai.client.IAiClient;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class JobMatchServiceImplTest {

    @Mock
    private IAiClient aiClient;

    @Mock
    private CvRepository cvRepository;

    @InjectMocks
    private JobMatchServiceImpl service;

    private Cv cv;

    @BeforeEach
    void setUp() {
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

        when(cvRepository.findById(22L)).thenReturn(Optional.of(cv));
    }

    @Test
    void matchJob_sansCleIa_retourneLeFallbackSansException() {
        when(aiClient.isAvailable()).thenReturn(false);

        JobMatchResponse response = service.matchJob(
                22L,
                "Pilotage de projet digital, gestion des budgets, communication et analyse de donnees");

        assertThat(response.isAiGenerated()).isFalse();
        assertThat(response.getScore()).isBetween(0, 100);
        assertThat(response.getMatchedKeywords()).isNotEmpty();
        assertThat(response.getMissingKeywords()).contains("analyse", "donnees");
        assertThat(response.getSuggestions()).hasSize(3);
    }

    @Test
    void matchJob_avecSeulementDesStopWords_retourneUnScoreNul() {
        when(aiClient.isAvailable()).thenReturn(false);

        JobMatchResponse response = service.matchJob(
                22L,
                "avec pour dans cette votre notre entre faire avoir");

        assertThat(response.getScore()).isZero();
        assertThat(response.getMatchedKeywords()).isEmpty();
        assertThat(response.getMissingKeywords()).isEmpty();
    }

    @Test
    void matchJob_siLeClientIaEchoue_retombeSurLeFallback() {
        when(aiClient.isAvailable()).thenReturn(true);
        when(aiClient.complete(org.mockito.ArgumentMatchers.anyString(),
                org.mockito.ArgumentMatchers.anyInt()))
                .thenThrow(new IllegalStateException("IA indisponible"));

        JobMatchResponse response = service.matchJob(
                22L,
                "Chef de projet digital avec gestion de budgets et planification");

        assertThat(response.isAiGenerated()).isFalse();
        assertThat(response.getScore()).isPositive();
    }

    @Test
    void matchJob_fallbackConserveLesMotsAccentesEtAnalyseToutesLesSections() {
        when(aiClient.isAvailable()).thenReturn(false);
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
                22L,
                "Équipe, délais, stratégie, Scrum, Figma et français.");

        assertThat(response.getMatchedKeywords())
                .contains("équipe", "délais", "stratégie", "scrum", "figma", "français")
                .doesNotContain("quipe", "lais", "strat", "gique");
        assertThat(response.getMissingKeywords()).isEmpty();
        assertThat(response.getScore()).isEqualTo(100);
    }
}
