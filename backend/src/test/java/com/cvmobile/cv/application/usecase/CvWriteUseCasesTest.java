package com.cvmobile.cv.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.cvmobile.cv.application.CvNotFoundException;
import com.cvmobile.cv.application.InMemoryCvRepository;
import com.cvmobile.cv.domain.model.Cv;
import com.cvmobile.cv.domain.model.CvStyle;
import com.cvmobile.cv.domain.model.Experience;
import com.cvmobile.cv.domain.model.PersonalInfo;
import com.cvmobile.cv.domain.model.Skill;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * Use cases d'ecriture du CV (Create / Update / Delete / Duplicate), testes en
 * isolation avec un double en memoire du port.
 */
@DisplayName("Use cases d'ecriture (Create / Update / Delete / Duplicate)")
class CvWriteUseCasesTest {

    private static final long OWNER = 7L;
    private static final long OTHER = 99L;

    private InMemoryCvRepository repo;
    private CreateCvUseCase createCv;
    private UpdateCvUseCase updateCv;
    private DeleteCvUseCase deleteCv;
    private DuplicateCvUseCase duplicateCv;

    @BeforeEach
    void setUp() {
        repo = new InMemoryCvRepository();
        createCv = new CreateCvUseCase(repo);
        updateCv = new UpdateCvUseCase(repo);
        deleteCv = new DeleteCvUseCase(repo);
        duplicateCv = new DuplicateCvUseCase(repo);
    }

    private Cv richDraft() {
        Cv cv = Cv.create("Mon CV", OWNER);
        cv.changePersonalInfo(PersonalInfo.builder().nom("Traore").build());
        cv.addExperience(Experience.of(null, "ACME", "Dev", null, null, null, "x", true));
        cv.addEducation(com.cvmobile.cv.domain.model.Education.of(
                null, "U", "Master", "Info", null, null, "desc"));
        cv.addSkill(Skill.of(null, "Java", 5, null));
        cv.addLanguage(com.cvmobile.cv.domain.model.Language.of(
                null, "Anglais", com.cvmobile.cv.domain.model.LanguageLevel.C1));
        cv.addCertification(com.cvmobile.cv.domain.model.Certification.of(
                null, "AWS", "Amazon", null, null, "url"));
        cv.addProject(com.cvmobile.cv.domain.model.Project.of(
                null, "MonCV", "desc", "Java", "lien", null, null));
        return cv;
    }

    @Nested
    @DisplayName("Create")
    class Create {

        @Test
        @DisplayName("persiste un nouveau CV et lui attribue un identifiant")
        void createsAndAssignsId() {
            Cv created = createCv.create(richDraft());

            assertThat(created.getId()).isNotNull();
            assertThat(repo.findByIdAndOwnerId(created.getId(), OWNER)).isPresent();
            assertThat(created.getSkills()).hasSize(1);
        }
    }

    @Nested
    @DisplayName("Delete")
    class Delete {

        @Test
        @DisplayName("supprime un CV possede")
        void deletesOwned() {
            Cv created = createCv.create(richDraft());

            deleteCv.delete(created.getId(), OWNER);

            assertThat(repo.findByIdAndOwnerId(created.getId(), OWNER)).isEmpty();
        }

        @Test
        @DisplayName("echoue si le CV n'existe pas ou n'est pas possede")
        void failsWhenAbsentOrUnowned() {
            Cv created = createCv.create(richDraft());

            assertThatThrownBy(() -> deleteCv.delete(created.getId(), OTHER))
                    .isInstanceOf(CvNotFoundException.class);
            assertThatThrownBy(() -> deleteCv.delete(404L, OWNER))
                    .isInstanceOf(CvNotFoundException.class);
        }
    }

    @Nested
    @DisplayName("Update")
    class Update {

        @Test
        @DisplayName("met a jour titre, style, personalInfo et sections")
        void updatesFields() {
            Cv created = createCv.create(richDraft());

            Cv changes = Cv.create("Titre modifie", OWNER);
            changes.changeStyle(CvStyle.of("classique", 42L, "Lato"));
            changes.changePersonalInfo(PersonalInfo.builder().nom("Nouveau").build());
            changes.replaceSkills(List.of(Skill.of(null, "Kotlin", 4, null)));

            Cv updated = updateCv.update(created.getId(), OWNER, changes);

            assertThat(updated.getId()).isEqualTo(created.getId());
            assertThat(updated.getTitre()).isEqualTo("Titre modifie");
            assertThat(updated.getStyle()).isEqualTo(CvStyle.of("classique", 42L, "Lato"));
            assertThat(updated.getPersonalInfo().nom()).isEqualTo("Nouveau");
            assertThat(updated.getSkills()).singleElement()
                    .satisfies(s -> assertThat(s.nom()).isEqualTo("Kotlin"));
        }

        @Test
        @DisplayName("preserve l'identite, le proprietaire et les compteurs du CV")
        void preservesIdentityAndCounters() {
            Cv created = createCv.create(richDraft());
            created.registerView();
            repo.save(created);

            Cv updated = updateCv.update(
                    created.getId(), OWNER, Cv.create("Autre titre", OWNER));

            assertThat(updated.getOwnerId()).isEqualTo(OWNER);
            assertThat(updated.getViewCount()).isEqualTo(1);
        }

        @Test
        @DisplayName("echoue si le CV n'existe pas ou n'est pas possede")
        void failsWhenAbsentOrUnowned() {
            Cv created = createCv.create(richDraft());

            assertThatThrownBy(() -> updateCv.update(
                    created.getId(), OTHER, Cv.create("x", OTHER)))
                    .isInstanceOf(CvNotFoundException.class);
        }
    }

    @Nested
    @DisplayName("Duplicate")
    class Duplicate {

        @Test
        @DisplayName("cree une copie independante avec un nouvel identifiant")
        void duplicates() {
            Cv created = createCv.create(richDraft());

            Cv copy = duplicateCv.duplicate(created.getId(), OWNER);

            assertThat(copy.getId()).isNotNull().isNotEqualTo(created.getId());
            assertThat(copy.getTitre()).isEqualTo("Copie de Mon CV");
            assertThat(copy.getOwnerId()).isEqualTo(OWNER);
        }

        @Test
        @DisplayName("copie toutes les sections sans reprendre leurs identifiants")
        void copiesSectionsAsNew() {
            Cv created = createCv.create(richDraft());

            Cv copy = duplicateCv.duplicate(created.getId(), OWNER);

            assertThat(copy.getSkills()).singleElement()
                    .satisfies(s -> {
                        assertThat(s.nom()).isEqualTo("Java");
                        assertThat(s.id()).isNull();
                    });
            assertThat(copy.getExperiences()).singleElement()
                    .satisfies(e -> assertThat(e.id()).isNull());
            assertThat(copy.getEducations()).singleElement()
                    .satisfies(e -> {
                        assertThat(e.diplome()).isEqualTo("Master");
                        assertThat(e.id()).isNull();
                    });
            assertThat(copy.getLanguages()).singleElement()
                    .satisfies(l -> {
                        assertThat(l.langue()).isEqualTo("Anglais");
                        assertThat(l.id()).isNull();
                    });
            assertThat(copy.getCertifications()).singleElement()
                    .satisfies(c -> {
                        assertThat(c.nom()).isEqualTo("AWS");
                        assertThat(c.id()).isNull();
                    });
            assertThat(copy.getProjects()).singleElement()
                    .satisfies(p -> {
                        assertThat(p.nom()).isEqualTo("MonCV");
                        assertThat(p.id()).isNull();
                    });
        }

        @Test
        @DisplayName("copie le style et les informations personnelles")
        void copiesStyleAndPersonalInfo() {
            Cv draft = richDraft();
            draft.changeStyle(CvStyle.of("minimaliste", 7L, "Lato"));
            Cv created = createCv.create(draft);

            Cv copy = duplicateCv.duplicate(created.getId(), OWNER);

            assertThat(copy.getStyle()).isEqualTo(CvStyle.of("minimaliste", 7L, "Lato"));
            assertThat(copy.getPersonalInfo().nom()).isEqualTo("Traore");
        }

        @Test
        @DisplayName("echoue si le CV source n'est pas possede")
        void failsWhenUnowned() {
            Cv created = createCv.create(richDraft());

            assertThatThrownBy(() -> duplicateCv.duplicate(created.getId(), OTHER))
                    .isInstanceOf(CvNotFoundException.class);
        }
    }
}
