package com.cvmobile.cv.domain.model;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Project (value object domaine)")
class ProjectTest {

    @Test
    @DisplayName("cree un projet complet")
    void createsFullProject() {
        Project project = Project.of(
                11L, "MonCV", "Generateur de CV", "Java, Flutter",
                "https://moncv.app",
                LocalDate.of(2024, 1, 1), LocalDate.of(2024, 12, 31));

        assertThat(project.id()).isEqualTo(11L);
        assertThat(project.nom()).isEqualTo("MonCV");
        assertThat(project.description()).isEqualTo("Generateur de CV");
        assertThat(project.technologies()).isEqualTo("Java, Flutter");
        assertThat(project.lien()).isEqualTo("https://moncv.app");
        assertThat(project.dateDebut()).isEqualTo(LocalDate.of(2024, 1, 1));
        assertThat(project.dateFin()).isEqualTo(LocalDate.of(2024, 12, 31));
    }

    @Test
    @DisplayName("accepte les champs optionnels a null")
    void allowsOptionalNull() {
        Project project = Project.of(null, "MonCV", null, null, null, null, null);

        assertThat(project.description()).isNull();
        assertThat(project.technologies()).isNull();
        assertThat(project.lien()).isNull();
    }

    @Test
    @DisplayName("normalise et convertit les blancs en null")
    void normalisesText() {
        Project project = Project.of(
                null, "  MonCV  ", "  ", "  Java  ", null, null, null);

        assertThat(project.nom()).isEqualTo("MonCV");
        assertThat(project.description()).isNull();
        assertThat(project.technologies()).isEqualTo("Java");
    }

    @Test
    @DisplayName("egalite par valeur")
    void valueEquality() {
        Project a = Project.of(1L, "P", "d", "t", "l", null, null);
        Project b = Project.of(1L, "P", "d", "t", "l", null, null);

        assertThat(a).isEqualTo(b).hasSameHashCodeAs(b);
    }
}
