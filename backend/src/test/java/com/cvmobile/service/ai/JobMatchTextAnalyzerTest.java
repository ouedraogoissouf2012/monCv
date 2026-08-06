package com.cvmobile.service.ai;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class JobMatchTextAnalyzerTest {

    private final JobMatchTextAnalyzer text = new JobMatchTextAnalyzer();

    @Test
    void normalize_retireAccentsPonctuationEtMinusculise() {
        assertThat(text.normalize("Développé & Réseaux !")).isEqualTo("developpe reseaux");
        assertThat(text.normalize(null)).isEmpty();
    }

    @Test
    void extractKeywords_ignoreStopWordsEtMotsCourts() {
        var keywords = text.extractKeywords("Gestion projet avec budgets et docker");

        // "projet" et "avec" sont des stop-words ; les tokens < 4 sont ecartes.
        assertThat(keywords).contains("gestion", "budgets", "docker")
                .doesNotContain("projet", "avec", "et");
    }

    @Test
    void isTechnicalKeyword_reconnaitStackEtTokensSpeciaux() {
        assertThat(text.isTechnicalKeyword("java")).isTrue();
        assertThat(text.isTechnicalKeyword("python3")).isTrue();  // contient un chiffre
        assertThat(text.isTechnicalKeyword("c++")).isTrue();      // contient +
        assertThat(text.isTechnicalKeyword("communication")).isFalse();
    }

    @Test
    void containsTerm_respecteLesFrontieresDeMot() {
        assertThat(text.containsTerm("java developpeur backend", "java")).isTrue();
        assertThat(text.containsTerm("javascript uniquement", "java")).isFalse();
    }
}
