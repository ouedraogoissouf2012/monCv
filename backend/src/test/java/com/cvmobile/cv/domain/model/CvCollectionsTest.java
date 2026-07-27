package com.cvmobile.cv.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * Comportement des collections de l'agregat {@link Cv} (encapsulation,
 * remplacement, copie defensive) et rehydratation depuis la persistance.
 */
@DisplayName("Cv (collections et rehydratation)")
class CvCollectionsTest {

    private static final long OWNER = 7L;

    private Cv newCv() {
        return Cv.create("Mon CV", OWNER);
    }

    @Nested
    @DisplayName("Mutations controlees et encapsulation")
    class Mutations {

        @Test
        @DisplayName("ajoute des elements a chaque collection")
        void addsToEachCollection() {
            Cv cv = newCv();
            cv.addExperience(Experience.of(null, "ACME", "Dev", null, null, null, null, true));
            cv.addEducation(Education.of(null, "U", "M", null, null, null, null));
            cv.addSkill(Skill.of(null, "Java", 5, null));
            cv.addLanguage(Language.of(null, "Anglais", LanguageLevel.C1));
            cv.addCertification(Certification.of(null, "AWS", null, null, null, null));
            cv.addProject(Project.of(null, "MonCV", null, null, null, null, null));

            assertThat(cv.getExperiences()).hasSize(1);
            assertThat(cv.getEducations()).hasSize(1);
            assertThat(cv.getSkills()).hasSize(1);
            assertThat(cv.getLanguages()).hasSize(1);
            assertThat(cv.getCertifications()).hasSize(1);
            assertThat(cv.getProjects()).hasSize(1);
        }

        @Test
        @DisplayName("expose des vues non modifiables des collections")
        void exposesUnmodifiableViews() {
            Cv cv = newCv();
            List<Skill> skills = cv.getSkills();

            assertThatThrownBy(() -> skills.add(Skill.of(null, "X", 1, null)))
                    .isInstanceOf(UnsupportedOperationException.class);
        }

        @Test
        @DisplayName("rejette l'ajout d'un element null")
        void rejectsNullElement() {
            Cv cv = newCv();

            assertThatThrownBy(() -> cv.addSkill(null))
                    .isInstanceOf(IllegalArgumentException.class);
        }

        @Test
        @DisplayName("remplace integralement une collection")
        void replacesCollection() {
            Cv cv = newCv();
            cv.addSkill(Skill.of(null, "Java", 5, null));

            cv.replaceSkills(List.of(
                    Skill.of(null, "Kotlin", 4, null),
                    Skill.of(null, "Go", 3, null)));

            assertThat(cv.getSkills())
                    .extracting(Skill::nom)
                    .containsExactly("Kotlin", "Go");
        }

        @Test
        @DisplayName("remplacer par null vide la collection")
        void replaceWithNullClears() {
            Cv cv = newCv();
            cv.addSkill(Skill.of(null, "Java", 5, null));

            cv.replaceSkills(null);

            assertThat(cv.getSkills()).isEmpty();
        }

        @Test
        @DisplayName("une collection remplacee est defensivement copiee")
        void replacementIsDefensivelyCopied() {
            Cv cv = newCv();
            var source = new ArrayList<>(List.of(Skill.of(null, "Java", 5, null)));
            cv.replaceSkills(source);

            source.clear();

            assertThat(cv.getSkills()).hasSize(1);
        }
    }

    @Nested
    @DisplayName("Toutes les collections : remplacement et vues immuables")
    class AllCollections {

        @Test
        @DisplayName("remplace chaque type de collection")
        void replacesEach() {
            Cv cv = newCv();
            cv.replaceExperiences(List.of(
                    Experience.of(null, "A", "Dev", null, null, null, null, false)));
            cv.replaceEducations(List.of(
                    Education.of(null, "U", "M", null, null, null, null)));
            cv.replaceLanguages(List.of(Language.of(null, "FR", LanguageLevel.NATIF)));
            cv.replaceCertifications(List.of(
                    Certification.of(null, "AWS", null, null, null, null)));
            cv.replaceProjects(List.of(
                    Project.of(null, "P", null, null, null, null, null)));

            assertThat(cv.getExperiences()).hasSize(1);
            assertThat(cv.getEducations()).hasSize(1);
            assertThat(cv.getLanguages()).hasSize(1);
            assertThat(cv.getCertifications()).hasSize(1);
            assertThat(cv.getProjects()).hasSize(1);
        }

        @Test
        @DisplayName("chaque vue de collection est non modifiable")
        void everyViewIsUnmodifiable() {
            Cv cv = newCv();

            assertThatThrownBy(() -> cv.getExperiences().clear())
                    .isInstanceOf(UnsupportedOperationException.class);
            assertThatThrownBy(() -> cv.getEducations().clear())
                    .isInstanceOf(UnsupportedOperationException.class);
            assertThatThrownBy(() -> cv.getLanguages().clear())
                    .isInstanceOf(UnsupportedOperationException.class);
            assertThatThrownBy(() -> cv.getCertifications().clear())
                    .isInstanceOf(UnsupportedOperationException.class);
            assertThatThrownBy(() -> cv.getProjects().clear())
                    .isInstanceOf(UnsupportedOperationException.class);
        }

        @Test
        @DisplayName("rejette l'ajout null sur toute collection")
        void rejectsNullOnEach() {
            Cv cv = newCv();

            assertThatThrownBy(() -> cv.addExperience(null))
                    .isInstanceOf(IllegalArgumentException.class);
            assertThatThrownBy(() -> cv.addEducation(null))
                    .isInstanceOf(IllegalArgumentException.class);
            assertThatThrownBy(() -> cv.addLanguage(null))
                    .isInstanceOf(IllegalArgumentException.class);
            assertThatThrownBy(() -> cv.addCertification(null))
                    .isInstanceOf(IllegalArgumentException.class);
            assertThatThrownBy(() -> cv.addProject(null))
                    .isInstanceOf(IllegalArgumentException.class);
        }
    }

    @Nested
    @DisplayName("Rehydratation (reservee aux adaptateurs de persistance)")
    class Rehydration {

        @Test
        @DisplayName("reconstitue un agregat existant avec ses compteurs")
        void rehydratesExisting() {
            CvStyle style = CvStyle.of("classique", 42L, "Lato");
            Cv cv = Cv.rehydrate(
                    55L, "CV persiste", OWNER, style, 10L, "Backend", 3, 4, 5);

            assertThat(cv.getId()).isEqualTo(55L);
            assertThat(cv.getTitre()).isEqualTo("CV persiste");
            assertThat(cv.getStyle()).isEqualTo(style);
            assertThat(cv.getParentId()).isEqualTo(10L);
            assertThat(cv.isVariante()).isTrue();
            assertThat(cv.getViewCount()).isEqualTo(3);
            assertThat(cv.getDownloadCount()).isEqualTo(4);
            assertThat(cv.getShareCount()).isEqualTo(5);
        }

        @Test
        @DisplayName("refuse un compteur negatif a la rehydratation")
        void rejectsNegativeCounter() {
            CvStyle style = CvStyle.defaults();

            assertThatThrownBy(() -> Cv.rehydrate(
                    1L, "t", OWNER, style, null, null, -1, 0, 0))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("viewCount");
        }

        @Test
        @DisplayName("affecte l'identifiant a un CV neuf")
        void assignsId() {
            Cv cv = newCv();
            cv.assignId(99L);

            assertThat(cv.getId()).isEqualTo(99L);
        }

        @Test
        @DisplayName("refuse de reaffecter un identifiant deja pose")
        void refusesReassign() {
            Cv cv = Cv.rehydrate(
                    1L, "t", OWNER, CvStyle.defaults(), null, null, 0, 0, 0);

            assertThatThrownBy(() -> cv.assignId(2L))
                    .isInstanceOf(IllegalStateException.class);
        }

        @Test
        @DisplayName("refuse un identifiant null")
        void refusesNullId() {
            Cv cv = newCv();

            assertThatThrownBy(() -> cv.assignId(null))
                    .isInstanceOf(IllegalArgumentException.class);
        }
    }
}
