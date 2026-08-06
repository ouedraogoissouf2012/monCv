package com.cvmobile.service;

import com.cvmobile.config.CvQualityProperties;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Experience;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.service.quality.CvReviewAnalyzer;
import com.cvmobile.service.quality.CvTextCleaner;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class CvQualityServiceTest {

    private final CvQualityService service = new CvQualityService(
            new CvTextCleaner(),
            new CvReviewAnalyzer(new CvQualityProperties(100, 20, 10, 5, 5, 100, 80, 10))
    );

    @Test
    void cleanCorrigeLesErreursFiablesSansModifierLesSousChaines() {
        String corrected = service.clean(
                "Developpeur forme au lyce en comminoty management dans un produit worldwide");

        assertThat(corrected)
                .isEqualTo("Développeur forme au lycée en community management dans un produit worldwide");
    }

    @Test
    void cleanProfessionalTermNormaliseLesOutilsEtCompetences() {
        String corrected = service.cleanProfessionalTerm(
                "world, excel, comminoty management, canva et ia");

        assertThat(corrected)
                .isEqualTo("Word, Excel, Community Management, Canva et IA");
    }

    @Test
    void findReviewWarningsSignaleLesSiglesEtDescriptionsGeneriques() {
        Cv cv = Cv.builder()
                .titre("Community manager")
                .personalInfo(PersonalInfo.builder()
                        .titrePoste("Community manager")
                        .resumeProfessionnel("Suivi du PRR et animation des réseaux sociaux")
                        .build())
                .experiences(List.of(Experience.builder()
                        .poste("Manager")
                        .entreprise("Entreprise")
                        .description("Géré plusieurs projets en parallèle dans le respect des délais et des budgets")
                        .build()))
                .build();

        assertThat(service.findReviewWarnings(cv))
                .anyMatch(message -> message.contains("PRR"))
                .anyMatch(message -> message.contains("nombre de projets"))
                .anyMatch(message -> message.contains("Détaillez davantage"));
    }
}
