package com.cvmobile.cv.domain.model;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Experience (value object domaine)")
class ExperienceTest {

    @Test
    @DisplayName("cree une experience complete")
    void createsFullExperience() {
        Experience exp = Experience.of(
                3L, "ACME", "Ingenieur", "Paris",
                LocalDate.of(2020, 1, 1), LocalDate.of(2022, 6, 30),
                "A concu le systeme de paiement", false);

        assertThat(exp.id()).isEqualTo(3L);
        assertThat(exp.entreprise()).isEqualTo("ACME");
        assertThat(exp.poste()).isEqualTo("Ingenieur");
        assertThat(exp.lieu()).isEqualTo("Paris");
        assertThat(exp.dateDebut()).isEqualTo(LocalDate.of(2020, 1, 1));
        assertThat(exp.dateFin()).isEqualTo(LocalDate.of(2022, 6, 30));
        assertThat(exp.description()).isEqualTo("A concu le systeme de paiement");
        assertThat(exp.actuel()).isFalse();
    }

    @Test
    @DisplayName("actuel a false par defaut quand la valeur est null")
    void currentDefaultsToFalse() {
        Experience exp = Experience.of(
                null, "ACME", "Dev", null, null, null, null, null);

        assertThat(exp.actuel()).isFalse();
    }

    @Test
    @DisplayName("preserve actuel=true pour un poste en cours")
    void keepsCurrentTrue() {
        Experience exp = Experience.of(
                null, "ACME", "Dev", null,
                LocalDate.of(2023, 1, 1), null, null, true);

        assertThat(exp.actuel()).isTrue();
    }

    @Test
    @DisplayName("normalise les champs texte et convertit les blancs en null")
    void normalisesText() {
        Experience exp = Experience.of(
                null, "  ACME  ", "  ", null, null, null, "  desc  ", false);

        assertThat(exp.entreprise()).isEqualTo("ACME");
        assertThat(exp.poste()).isNull();
        assertThat(exp.description()).isEqualTo("desc");
    }

    @Test
    @DisplayName("egalite par valeur")
    void valueEquality() {
        LocalDate d = LocalDate.of(2020, 1, 1);
        Experience a = Experience.of(1L, "ACME", "Dev", "Paris", d, null, "x", true);
        Experience b = Experience.of(1L, "ACME", "Dev", "Paris", d, null, "x", true);

        assertThat(a).isEqualTo(b).hasSameHashCodeAs(b);
    }
}
