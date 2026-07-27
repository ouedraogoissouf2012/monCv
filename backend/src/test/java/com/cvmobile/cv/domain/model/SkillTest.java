package com.cvmobile.cv.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

@DisplayName("Skill (value object domaine)")
class SkillTest {

    @Nested
    @DisplayName("Invariants de creation")
    class Creation {

        @Test
        @DisplayName("cree un skill valide avec tous ses champs")
        void createsValidSkill() {
            Skill skill = Skill.of(42L, "Java", 4, "Backend");

            assertThat(skill.id()).isEqualTo(42L);
            assertThat(skill.nom()).isEqualTo("Java");
            assertThat(skill.niveau()).isEqualTo(4);
            assertThat(skill.categorie()).isEqualTo("Backend");
        }

        @Test
        @DisplayName("accepte un id null (skill pas encore persiste)")
        void allowsNullId() {
            Skill skill = Skill.of(null, "Kotlin", 3, null);

            assertThat(skill.id()).isNull();
            assertThat(skill.categorie()).isNull();
        }

        @Test
        @DisplayName("rejette un nom vide ou blanc")
        void rejectsBlankName() {
            assertThatThrownBy(() -> Skill.of(null, "   ", 3, null))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("nom");
        }

        @Test
        @DisplayName("rejette un nom null")
        void rejectsNullName() {
            assertThatThrownBy(() -> Skill.of(null, null, 3, null))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("nom");
        }

        @Test
        @DisplayName("rejette un niveau en dessous de 1")
        void rejectsLevelBelowRange() {
            assertThatThrownBy(() -> Skill.of(null, "Java", 0, null))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("niveau");
        }

        @Test
        @DisplayName("rejette un niveau au dessus de 5")
        void rejectsLevelAboveRange() {
            assertThatThrownBy(() -> Skill.of(null, "Java", 6, null))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("niveau");
        }

        @Test
        @DisplayName("accepte un niveau null (non renseigne)")
        void allowsNullLevel() {
            Skill skill = Skill.of(null, "Docker", null, "Ops");

            assertThat(skill.niveau()).isNull();
        }

        @Test
        @DisplayName("normalise les espaces superflus du nom et de la categorie")
        void trimsWhitespace() {
            Skill skill = Skill.of(null, "  Java  ", 5, "  Backend  ");

            assertThat(skill.nom()).isEqualTo("Java");
            assertThat(skill.categorie()).isEqualTo("Backend");
        }

        @Test
        @DisplayName("convertit une categorie blanche en null")
        void blankCategoryBecomesNull() {
            Skill skill = Skill.of(null, "Java", 5, "   ");

            assertThat(skill.categorie()).isNull();
        }
    }

    @Nested
    @DisplayName("Immutabilite et egalite")
    class Immutability {

        @Test
        @DisplayName("deux skills identiques sont egaux")
        void valueEquality() {
            Skill a = Skill.of(1L, "Java", 4, "Backend");
            Skill b = Skill.of(1L, "Java", 4, "Backend");

            assertThat(a).isEqualTo(b);
            assertThat(a).hasSameHashCodeAs(b);
        }
    }
}
