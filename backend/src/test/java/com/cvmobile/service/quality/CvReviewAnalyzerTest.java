package com.cvmobile.service.quality;

import com.cvmobile.config.CvQualityProperties;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Experience;
import com.cvmobile.model.PersonalInfo;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class CvReviewAnalyzerTest {

    private final CvReviewAnalyzer analyzer = new CvReviewAnalyzer(
            new CvQualityProperties(100, 20, 10, 5, 5, 100, 80, 10));

    @Test
    void signaleUneExperienceSansDescription() {
        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder()
                        .titrePoste("Développeur")
                        .resumeProfessionnel("Résumé professionnel complet")
                        .build())
                .experiences(List.of(Experience.builder()
                        .poste("Développeur")
                        .entreprise("ACME")
                        .description("")
                        .build()))
                .build();

        assertThat(analyzer.findReviewWarnings(cv))
                .anyMatch(message -> message.contains("Ajoutez une description"));
    }

    @Test
    void signaleLaPhraseGeneriqueSurLEquipePluridisciplinaire() {
        Cv cv = Cv.builder()
                .personalInfo(PersonalInfo.builder()
                        .titrePoste("Chef de projet")
                        .resumeProfessionnel("Dirigé une équipe pluridisciplinaire de cinq personnes")
                        .build())
                .experiences(List.of(Experience.builder()
                        .poste("Chef de projet")
                        .entreprise("ACME")
                        .description("Description suffisamment detaillee avec missions concretes, "
                                + "outils employes et resultats mesurables verifiables sur le terrain")
                        .build()))
                .build();

        assertThat(analyzer.findReviewWarnings(cv))
                .anyMatch(message -> message.contains("taille de l'équipe"));
    }
}
