package com.cvmobile.cv.domain.model;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Education (value object domaine)")
class EducationTest {

    @Test
    @DisplayName("cree une formation complete")
    void createsFullEducation() {
        Education edu = Education.of(
                5L, "Universite X", "Master", "Informatique",
                LocalDate.of(2016, 9, 1), LocalDate.of(2018, 6, 30),
                "Specialite systemes distribues");

        assertThat(edu.id()).isEqualTo(5L);
        assertThat(edu.etablissement()).isEqualTo("Universite X");
        assertThat(edu.diplome()).isEqualTo("Master");
        assertThat(edu.domaine()).isEqualTo("Informatique");
        assertThat(edu.dateDebut()).isEqualTo(LocalDate.of(2016, 9, 1));
        assertThat(edu.dateFin()).isEqualTo(LocalDate.of(2018, 6, 30));
        assertThat(edu.description()).isEqualTo("Specialite systemes distribues");
    }

    @Test
    @DisplayName("accepte tous les champs optionnels a null")
    void allowsAllOptionalNull() {
        Education edu = Education.of(null, null, null, null, null, null, null);

        assertThat(edu.id()).isNull();
        assertThat(edu.etablissement()).isNull();
    }

    @Test
    @DisplayName("normalise et convertit les blancs en null")
    void normalisesText() {
        Education edu = Education.of(
                null, "  Universite X  ", "  ", null, null, null, "  desc  ");

        assertThat(edu.etablissement()).isEqualTo("Universite X");
        assertThat(edu.diplome()).isNull();
        assertThat(edu.description()).isEqualTo("desc");
    }

    @Test
    @DisplayName("egalite par valeur")
    void valueEquality() {
        Education a = Education.of(1L, "U", "M", "Info", null, null, "x");
        Education b = Education.of(1L, "U", "M", "Info", null, null, "x");

        assertThat(a).isEqualTo(b).hasSameHashCodeAs(b);
    }
}
