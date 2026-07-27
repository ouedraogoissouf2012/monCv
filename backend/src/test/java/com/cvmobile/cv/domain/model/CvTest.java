package com.cvmobile.cv.domain.model;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * Cycle de vie de l'agregat {@link Cv} : creation, invariants, renommage,
 * style, variantes, compteurs et informations personnelles. La gestion fine
 * des collections et la rehydratation sont couvertes par
 * {@link CvCollectionsTest}.
 */
@DisplayName("Cv (agregat de domaine)")
class CvTest {

    private static final long OWNER = 7L;

    private Cv newCv() {
        return Cv.create("Mon CV", OWNER);
    }

    @Nested
    @DisplayName("Creation et invariants")
    class Creation {

        @Test
        @DisplayName("cree un CV avec titre, proprietaire et style par defaut")
        void createsWithDefaults() {
            Cv cv = newCv();

            assertThat(cv.getId()).isNull();
            assertThat(cv.getTitre()).isEqualTo("Mon CV");
            assertThat(cv.getOwnerId()).isEqualTo(OWNER);
            assertThat(cv.getStyle()).isEqualTo(CvStyle.defaults());
            assertThat(cv.isVariante()).isFalse();
            assertThat(cv.getViewCount()).isZero();
            assertThat(cv.getExperiences()).isEmpty();
        }

        @Test
        @DisplayName("normalise et exige un titre non vide")
        void requiresTitle() {
            assertThatThrownBy(() -> Cv.create("   ", OWNER))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("titre");
        }

        @Test
        @DisplayName("exige un proprietaire strictement positif")
        void requiresOwner() {
            assertThatThrownBy(() -> Cv.create("Mon CV", 0L))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("ownerId");
        }
    }

    @Nested
    @DisplayName("Renommage et style")
    class RenameAndStyle {

        @Test
        @DisplayName("renomme le CV en normalisant le titre")
        void renames() {
            Cv cv = newCv();
            cv.rename("  Nouveau titre  ");

            assertThat(cv.getTitre()).isEqualTo("Nouveau titre");
        }

        @Test
        @DisplayName("refuse de renommer avec un titre vide")
        void rejectsBlankRename() {
            Cv cv = newCv();

            assertThatThrownBy(() -> cv.rename("  "))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("titre");
        }

        @Test
        @DisplayName("remplace le style")
        void changesStyle() {
            Cv cv = newCv();
            CvStyle custom = CvStyle.of("minimaliste", 42L, "Lato");
            cv.changeStyle(custom);

            assertThat(cv.getStyle()).isEqualTo(custom);
        }

        @Test
        @DisplayName("refuse un style null")
        void rejectsNullStyle() {
            Cv cv = newCv();

            assertThatThrownBy(() -> cv.changeStyle(null))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("style");
        }
    }

    @Nested
    @DisplayName("Variantes")
    class Variants {

        @Test
        @DisplayName("un CV marque comme variante est reconnu comme tel")
        void detectsVariant() {
            Cv variant = Cv.createVariant(
                    "Mon CV — Backend", OWNER, 100L, "Backend Java");

            assertThat(variant.isVariante()).isTrue();
            assertThat(variant.getParentId()).isEqualTo(100L);
            assertThat(variant.getVarianteLabel()).isEqualTo("Backend Java");
        }

        @Test
        @DisplayName("une variante exige un label non vide")
        void variantRequiresLabel() {
            assertThatThrownBy(() -> Cv.createVariant("t", OWNER, 100L, "  "))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("label");
        }

        @Test
        @DisplayName("une variante exige un parent")
        void variantRequiresParent() {
            assertThatThrownBy(() -> Cv.createVariant("t", OWNER, null, "Backend"))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("parent");
        }
    }

    @Nested
    @DisplayName("Compteurs (calcules cote serveur)")
    class Counters {

        @Test
        @DisplayName("incremente les vues")
        void incrementsViews() {
            Cv cv = newCv();
            cv.registerView();
            cv.registerView();

            assertThat(cv.getViewCount()).isEqualTo(2);
        }

        @Test
        @DisplayName("incremente les partages")
        void incrementsShares() {
            Cv cv = newCv();
            cv.registerShare();

            assertThat(cv.getShareCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("incremente les telechargements")
        void incrementsDownloads() {
            Cv cv = newCv();
            cv.registerDownload();
            cv.registerDownload();

            assertThat(cv.getDownloadCount()).isEqualTo(2);
        }
    }

    @Nested
    @DisplayName("Informations personnelles")
    class PersonalInfoManagement {

        @Test
        @DisplayName("met a jour puis efface les informations personnelles")
        void changesPersonalInfo() {
            Cv cv = newCv();
            PersonalInfo info = PersonalInfo.builder().nom("Ouedraogo").build();

            cv.changePersonalInfo(info);
            assertThat(cv.getPersonalInfo()).isEqualTo(info);

            cv.changePersonalInfo(null);
            assertThat(cv.getPersonalInfo()).isNull();
        }
    }
}
