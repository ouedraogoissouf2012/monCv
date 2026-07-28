package com.cvmobile.cv.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("Language (value object domaine)")
class LanguageTest {

    @Test
    @DisplayName("cree une langue valide")
    void createsValidLanguage() {
        Language language = Language.of(7L, "Anglais", LanguageLevel.C1);

        assertThat(language.id()).isEqualTo(7L);
        assertThat(language.langue()).isEqualTo("Anglais");
        assertThat(language.niveau()).isEqualTo(LanguageLevel.C1);
    }

    @Test
    @DisplayName("accepte un id null (non persiste)")
    void allowsNullId() {
        Language language = Language.of(null, "Espagnol", LanguageLevel.B2);

        assertThat(language.id()).isNull();
    }

    @Test
    @DisplayName("accepte un niveau null (non renseigne)")
    void allowsNullLevel() {
        Language language = Language.of(null, "Italien", null);

        assertThat(language.niveau()).isNull();
    }

    @Test
    @DisplayName("rejette une langue vide ou blanche")
    void rejectsBlankLanguage() {
        assertThatThrownBy(() -> Language.of(null, "  ", LanguageLevel.A1))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("langue");
    }

    @Test
    @DisplayName("rejette une langue null")
    void rejectsNullLanguage() {
        assertThatThrownBy(() -> Language.of(null, null, LanguageLevel.A1))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("langue");
    }

    @Test
    @DisplayName("normalise les espaces superflus")
    void trimsWhitespace() {
        Language language = Language.of(null, "  Francais  ", LanguageLevel.NATIF);

        assertThat(language.langue()).isEqualTo("Francais");
    }

    @Test
    @DisplayName("expose les 7 niveaux CECRL attendus")
    void exposesAllLevels() {
        assertThat(LanguageLevel.values())
                .containsExactly(
                        LanguageLevel.A1, LanguageLevel.A2,
                        LanguageLevel.B1, LanguageLevel.B2,
                        LanguageLevel.C1, LanguageLevel.C2,
                        LanguageLevel.NATIF);
    }
}
