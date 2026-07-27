package com.cvmobile.cv.domain.model;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Derivations {@code withDescription} des sections : elles permettent
 * l'adaptation IA d'une variante sans muter l'original (immutabilite).
 */
@DisplayName("Derivations de description des sections")
class ChildDerivationTest {

    @Test
    @DisplayName("Experience.withDescription remplace la description sans muter l'original")
    void experienceWithDescription() {
        Experience original = Experience.of(
                1L, "ACME", "Dev", "Paris",
                LocalDate.of(2020, 1, 1), null, "ancienne", true);

        Experience derived = original.withDescription("  nouvelle  ");

        assertThat(derived.description()).isEqualTo("nouvelle");
        assertThat(derived.entreprise()).isEqualTo("ACME");
        assertThat(derived.actuel()).isTrue();
        assertThat(derived.id()).isEqualTo(1L);
        assertThat(original.description()).isEqualTo("ancienne");
    }

    @Test
    @DisplayName("Education.withDescription remplace la description sans muter l'original")
    void educationWithDescription() {
        Education original = Education.of(
                2L, "U", "Master", "Info", null, null, "ancienne");

        Education derived = original.withDescription("nouvelle");

        assertThat(derived.description()).isEqualTo("nouvelle");
        assertThat(derived.diplome()).isEqualTo("Master");
        assertThat(original.description()).isEqualTo("ancienne");
    }

    @Test
    @DisplayName("Project.withDescription remplace la description sans muter l'original")
    void projectWithDescription() {
        Project original = Project.of(
                3L, "MonCV", "ancienne", "Java", "url", null, null);

        Project derived = original.withDescription("nouvelle");

        assertThat(derived.description()).isEqualTo("nouvelle");
        assertThat(derived.technologies()).isEqualTo("Java");
        assertThat(original.description()).isEqualTo("ancienne");
    }
}
