package com.cvmobile.service.quality;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class CvTextCleanerTest {

    private final CvTextCleaner cleaner = new CvTextCleaner();

    @Test
    void cleanRetireLeMarkdownGrasEtSingulariseLesParticipes() {
        String result = cleaner.clean("**Conçus** et Optimisés");

        assertThat(result).isEqualTo("Conçu et Optimisé");
    }

    @Test
    void cleanRetireLesTitresMarkdownEnDebutDeLigne() {
        String result = cleaner.clean("### Titre\n- Conçu une API");

        assertThat(result).isEqualTo("Titre\n- Conçu une API");
    }

    @Test
    void removeRepeatedTitleSupprimeLaPremiereLigneQuiRepeteLePoste() {
        String description = "Développeur Full Stack - DIGIT AFRICAN\n- Conçu une API";

        String result = cleaner.removeRepeatedTitle(
                description, "Développeur Full Stack", "DIGIT AFRICAN");

        assertThat(result).isEqualTo("- Conçu une API");
    }

    @Test
    void removeRepeatedTitleConserveUneDescriptionQuiNeRepeteRien() {
        String description = "- Conçu une API\n- Déployé sur Kubernetes";

        String result = cleaner.removeRepeatedTitle(description, "Data Analyst", "ACME");

        assertThat(result).isEqualTo(description);
    }

    @Test
    void removeRepeatedTitleRenvoieLaDescriptionInchangeeSiVideOuNulle() {
        assertThat(cleaner.removeRepeatedTitle(null, "p", "e")).isNull();
        assertThat(cleaner.removeRepeatedTitle("  ", "p", "e")).isEqualTo("  ");
    }
}
