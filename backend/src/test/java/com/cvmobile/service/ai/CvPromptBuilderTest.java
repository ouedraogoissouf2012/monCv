package com.cvmobile.service.ai;

import com.cvmobile.model.Cv;
import com.cvmobile.model.Experience;
import com.cvmobile.model.PersonalInfo;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class CvPromptBuilderTest {

    private final CvPromptBuilder builder = new CvPromptBuilder();

    private Cv sampleCv() {
        return Cv.builder()
                .personalInfo(PersonalInfo.builder().titrePoste("Developpeur").build())
                .experiences(List.of(Experience.builder().id(1L).poste("Dev").entreprise("ACME").build()))
                .educations(List.of()).skills(List.of())
                .languages(List.of()).certifications(List.of()).projects(List.of())
                .build();
    }

    @Test
    void buildEnhancePrompt_inclutRegleAncrageEtMarqueursDesExperiences() {
        String prompt = builder.buildEnhancePrompt(sampleCv(), "MAX");

        assertThat(prompt)
                .contains("Le contenu du candidat est la seule source de verite")
                .contains("EXP_1:")
                .contains("DONNEES ACTUELLES DU CV");
    }

    @Test
    void buildAdaptPrompt_inclutOffreEtMarqueurTitreOffre() {
        String prompt = builder.buildAdaptPrompt(sampleCv(), "Backend Java chez Sopra");

        assertThat(prompt)
                .contains("OFFRE D'EMPLOI:")
                .contains("Backend Java chez Sopra")
                .contains("TITRE_OFFRE:");
    }
}
