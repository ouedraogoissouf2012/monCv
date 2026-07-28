package com.cvmobile.cv.adapter.out.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.cvmobile.cv.domain.model.Cv;
import com.cvmobile.cv.domain.model.CvStyle;
import com.cvmobile.cv.domain.model.Experience;
import com.cvmobile.cv.domain.model.LanguageLevel;
import com.cvmobile.cv.domain.model.Skill;
import com.cvmobile.model.User;
import java.time.LocalDate;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * Contrat de conversion bidirectionnelle entre l'entite JPA {@code model.Cv} et
 * l'agregat de domaine {@link Cv}. Tests purs (sans base) : le mapper est
 * exerce sur des objets construits en memoire.
 */
@DisplayName("CvPersistenceMapper (domaine <-> JPA)")
class CvPersistenceMapperTest {

    private final CvPersistenceMapper mapper = new CvPersistenceMapper();

    private com.cvmobile.model.Cv fullEntity() {
        User owner = User.builder().id(7L).email("o@x.io").build();
        com.cvmobile.model.PersonalInfo info = com.cvmobile.model.PersonalInfo.builder()
                .nom("Ouedraogo").prenom("Issouf").email("i@x.io")
                .titrePoste("Dev Backend").resumeProfessionnel("Concu des systemes")
                .build();
        com.cvmobile.model.Cv cv = com.cvmobile.model.Cv.builder()
                .id(42L).titre("Mon CV").user(owner).personalInfo(info)
                .viewCount(3).downloadCount(4).shareCount(5)
                .styleTemplateId("classique").stylePrimaryColor(99L).styleFontFamily("Lato")
                .build();
        cv.addExperience(com.cvmobile.model.Experience.builder()
                .id(1L).entreprise("ACME").poste("Dev").lieu("Paris")
                .dateDebut(LocalDate.of(2020, 1, 1)).dateFin(LocalDate.of(2022, 6, 1))
                .description("A concu X").actuel(false).build());
        cv.addSkill(com.cvmobile.model.Skill.builder()
                .id(2L).nom("Java").niveau(5).categorie("Backend").build());
        cv.addLanguage(com.cvmobile.model.Language.builder()
                .id(3L).langue("Anglais")
                .niveau(com.cvmobile.model.Language.NiveauLangue.C1).build());
        cv.addEducation(com.cvmobile.model.Education.builder()
                .id(4L).etablissement("U").diplome("Master").build());
        cv.addCertification(com.cvmobile.model.Certification.builder()
                .id(5L).nom("AWS").organisme("Amazon").build());
        cv.addProject(com.cvmobile.model.Project.builder()
                .id(6L).nom("MonCV").technologies("Java").build());
        return cv;
    }

    @Nested
    @DisplayName("JPA -> domaine")
    class ToDomain {

        @Test
        @DisplayName("mappe tous les champs scalaires et le proprietaire")
        void mapsScalars() {
            Cv domain = mapper.toDomain(fullEntity());

            assertThat(domain.getId()).isEqualTo(42L);
            assertThat(domain.getTitre()).isEqualTo("Mon CV");
            assertThat(domain.getOwnerId()).isEqualTo(7L);
            assertThat(domain.getViewCount()).isEqualTo(3);
            assertThat(domain.getDownloadCount()).isEqualTo(4);
            assertThat(domain.getShareCount()).isEqualTo(5);
            assertThat(domain.getStyle())
                    .isEqualTo(CvStyle.of("classique", 99L, "Lato"));
        }

        @Test
        @DisplayName("mappe les informations personnelles")
        void mapsPersonalInfo() {
            Cv domain = mapper.toDomain(fullEntity());

            assertThat(domain.getPersonalInfo()).isNotNull();
            assertThat(domain.getPersonalInfo().nom()).isEqualTo("Ouedraogo");
            assertThat(domain.getPersonalInfo().titrePoste()).isEqualTo("Dev Backend");
        }

        @Test
        @DisplayName("mappe chaque collection avec ses identifiants")
        void mapsCollections() {
            Cv domain = mapper.toDomain(fullEntity());

            assertThat(domain.getExperiences())
                    .singleElement()
                    .satisfies(e -> {
                        assertThat(e.id()).isEqualTo(1L);
                        assertThat(e.entreprise()).isEqualTo("ACME");
                    });
            assertThat(domain.getSkills()).singleElement()
                    .isEqualTo(Skill.of(2L, "Java", 5, "Backend"));
            assertThat(domain.getLanguages()).singleElement()
                    .satisfies(l -> assertThat(l.niveau()).isEqualTo(LanguageLevel.C1));
            assertThat(domain.getEducations()).hasSize(1);
            assertThat(domain.getCertifications()).hasSize(1);
            assertThat(domain.getProjects()).hasSize(1);
        }

        @Test
        @DisplayName("mappe une variante avec son parent et son label")
        void mapsVariant() {
            com.cvmobile.model.Cv parent = com.cvmobile.model.Cv.builder().id(100L).build();
            com.cvmobile.model.Cv entity = fullEntity();
            entity.setParent(parent);
            entity.setVarianteLabel("Backend Java");

            Cv domain = mapper.toDomain(entity);

            assertThat(domain.isVariante()).isTrue();
            assertThat(domain.getParentId()).isEqualTo(100L);
            assertThat(domain.getVarianteLabel()).isEqualTo("Backend Java");
        }

        @Test
        @DisplayName("refuse une entite sans proprietaire (etat persistant corrompu)")
        void rejectsEntityWithoutOwner() {
            com.cvmobile.model.Cv orphan = com.cvmobile.model.Cv.builder()
                    .id(1L).titre("Orphelin").build();

            org.assertj.core.api.Assertions.assertThatThrownBy(() -> mapper.toDomain(orphan))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("proprietaire");
        }

        @Test
        @DisplayName("tolere un personalInfo et des collections vides")
        void mapsEmpty() {
            com.cvmobile.model.Cv entity = com.cvmobile.model.Cv.builder()
                    .id(1L).titre("Vide")
                    .user(User.builder().id(9L).build())
                    .build();

            Cv domain = mapper.toDomain(entity);

            assertThat(domain.getPersonalInfo()).isNull();
            assertThat(domain.getExperiences()).isEmpty();
            assertThat(domain.getStyle()).isEqualTo(CvStyle.defaults());
        }
    }

    @Nested
    @DisplayName("domaine -> JPA (round-trip)")
    class ToEntity {

        @Test
        @DisplayName("un aller-retour JPA -> domaine -> JPA preserve les donnees")
        void roundTrip() {
            com.cvmobile.model.Cv origin = fullEntity();

            Cv domain = mapper.toDomain(origin);
            com.cvmobile.model.Cv target = new com.cvmobile.model.Cv();
            target.setUser(origin.getUser());
            mapper.applyToEntity(domain, target);

            assertThat(target.getTitre()).isEqualTo("Mon CV");
            assertThat(target.getViewCount()).isEqualTo(3);
            assertThat(target.getStyleTemplateId()).isEqualTo("classique");
            assertThat(target.getStylePrimaryColor()).isEqualTo(99L);
            assertThat(target.getPersonalInfo().getNom()).isEqualTo("Ouedraogo");
            assertThat(target.getExperiences()).singleElement()
                    .satisfies(e -> assertThat(e.getEntreprise()).isEqualTo("ACME"));
            assertThat(target.getSkills()).singleElement()
                    .satisfies(s -> assertThat(s.getNiveau()).isEqualTo(5));
            assertThat(target.getLanguages()).singleElement()
                    .satisfies(l -> assertThat(l.getNiveau())
                            .isEqualTo(com.cvmobile.model.Language.NiveauLangue.C1));
        }

        @Test
        @DisplayName("applyToEntity relie chaque enfant a son CV parent (back-reference)")
        void wiresBackReferences() {
            Cv domain = Cv.create("CV", 7L);
            domain.addExperience(Experience.of(
                    null, "ACME", "Dev", null, null, null, null, true));
            com.cvmobile.model.Cv target = new com.cvmobile.model.Cv();

            mapper.applyToEntity(domain, target);

            assertThat(target.getExperiences()).singleElement()
                    .satisfies(e -> assertThat(e.getCv()).isSameAs(target));
        }

        @Test
        @DisplayName("applyToEntity NE touche PAS aux champs de partage non modelises")
        void preservesUnmodelledShareState() {
            com.cvmobile.model.Cv target = new com.cvmobile.model.Cv();
            target.setPublicToken("secret-token");
            target.setPublicTokenHash("hash");
            target.setPublicContactEnabled(true);
            target.setPublicDownloadsEnabled(true);

            Cv domain = Cv.create("Renomme", 7L);
            mapper.applyToEntity(domain, target);

            assertThat(target.getTitre()).isEqualTo("Renomme");
            assertThat(target.getPublicToken()).isEqualTo("secret-token");
            assertThat(target.getPublicTokenHash()).isEqualTo("hash");
            assertThat(target.isPublicContactEnabled()).isTrue();
            assertThat(target.isPublicDownloadsEnabled()).isTrue();
        }

        @Test
        @DisplayName("applyToEntity remplace integralement les collections existantes")
        void replacesExistingCollections() {
            com.cvmobile.model.Cv target = new com.cvmobile.model.Cv();
            target.addSkill(com.cvmobile.model.Skill.builder().nom("Ancien").niveau(1).build());

            Cv domain = Cv.create("CV", 7L);
            domain.addSkill(Skill.of(null, "Nouveau", 5, null));
            mapper.applyToEntity(domain, target);

            assertThat(target.getSkills()).singleElement()
                    .satisfies(s -> assertThat(s.getNom()).isEqualTo("Nouveau"));
        }

        @Test
        @DisplayName("conserve l'identifiant d'une section deja possedee (mise a jour)")
        void keepsOwnedSectionId() {
            com.cvmobile.model.Cv target = new com.cvmobile.model.Cv();
            target.addSkill(com.cvmobile.model.Skill.builder()
                    .id(50L).nom("Ancien").niveau(1).build());

            Cv domain = Cv.create("CV", 7L);
            domain.addSkill(Skill.of(50L, "Maj", 3, null));
            mapper.applyToEntity(domain, target);

            assertThat(target.getSkills()).singleElement().satisfies(s -> {
                assertThat(s.getId()).isEqualTo(50L);
                assertThat(s.getNom()).isEqualTo("Maj");
            });
        }

        @Test
        @DisplayName("neutralise un identifiant de section NON possede (protection IDOR)")
        void stripsForeignSectionId() {
            // target ne possede aucune competence : l'id 999 est etranger.
            com.cvmobile.model.Cv target = new com.cvmobile.model.Cv();

            Cv domain = Cv.create("CV", 7L);
            domain.addSkill(Skill.of(999L, "Injecte", 5, null));
            mapper.applyToEntity(domain, target);

            assertThat(target.getSkills()).singleElement().satisfies(s -> {
                assertThat(s.getId())
                        .as("un id de section etranger doit etre neutralise (insertion)")
                        .isNull();
                assertThat(s.getNom()).isEqualTo("Injecte");
            });
        }
    }
}
