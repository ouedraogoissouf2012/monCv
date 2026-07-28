package com.cvmobile.cv.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

@DisplayName("CvStyle (value object domaine)")
class CvStyleTest {

    @Test
    @DisplayName("fournit un style par defaut coherent avec l'existant")
    void providesDefault() {
        CvStyle style = CvStyle.defaults();

        assertThat(style.templateId()).isEqualTo("moderne");
        assertThat(style.primaryColor()).isEqualTo(4280648683L);
        assertThat(style.fontFamily()).isEqualTo("Roboto");
    }

    @Test
    @DisplayName("cree un style personnalise valide")
    void createsCustom() {
        CvStyle style = CvStyle.of("classique", 4278190080L, "Lato");

        assertThat(style.templateId()).isEqualTo("classique");
        assertThat(style.primaryColor()).isEqualTo(4278190080L);
        assertThat(style.fontFamily()).isEqualTo("Lato");
    }

    @Test
    @DisplayName("rejette un templateId vide")
    void rejectsBlankTemplate() {
        assertThatThrownBy(() -> CvStyle.of("  ", 1L, "Roboto"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("templateId");
    }

    @Test
    @DisplayName("rejette une police vide")
    void rejectsBlankFont() {
        assertThatThrownBy(() -> CvStyle.of("moderne", 1L, "  "))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("fontFamily");
    }

    @Test
    @DisplayName("rejette une couleur nulle")
    void rejectsNullColor() {
        assertThatThrownBy(() -> CvStyle.of("moderne", null, "Roboto"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("primaryColor");
    }

    @Test
    @DisplayName("ne modifie que le champ fourni via les derivations partielles")
    void partialOverride() {
        CvStyle base = CvStyle.defaults();

        assertThat(base.withTemplateId("minimaliste").templateId())
                .isEqualTo("minimaliste");
        assertThat(base.withTemplateId("minimaliste").fontFamily())
                .isEqualTo("Roboto");
        assertThat(base.withPrimaryColor(42L).primaryColor()).isEqualTo(42L);
        assertThat(base.withFontFamily("Lato").fontFamily()).isEqualTo("Lato");
    }

    @Test
    @DisplayName("normalise le templateId et la police")
    void normalises() {
        CvStyle style = CvStyle.of("  moderne  ", 1L, "  Roboto  ");

        assertThat(style.templateId()).isEqualTo("moderne");
        assertThat(style.fontFamily()).isEqualTo("Roboto");
    }
}
