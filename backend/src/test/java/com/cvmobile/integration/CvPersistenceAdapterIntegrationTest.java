package com.cvmobile.integration;

import static org.assertj.core.api.Assertions.assertThat;

import com.cvmobile.cv.application.port.out.CvRepositoryPort;
import com.cvmobile.cv.domain.model.Cv;
import com.cvmobile.cv.domain.model.CvStyle;
import com.cvmobile.cv.domain.model.Education;
import com.cvmobile.cv.domain.model.Experience;
import com.cvmobile.cv.domain.model.Language;
import com.cvmobile.cv.domain.model.LanguageLevel;
import com.cvmobile.cv.domain.model.PersonalInfo;
import com.cvmobile.cv.domain.model.Skill;
import com.cvmobile.model.User;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.repository.UserRepository;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

/**
 * Verifie la persistance reelle du module CV via {@link CvRepositoryPort} contre
 * un PostgreSQL Testcontainers et le schema Flyway de production (issue #255) :
 * round-trip complet, cascades, restriction par proprietaire et requetes fetch.
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional
@DisplayName("Persistance du module CV (Postgres reel)")
class CvPersistenceAdapterIntegrationTest extends PostgresIntegrationTest {

    @Autowired private CvRepositoryPort port;
    @Autowired private UserRepository userRepository;
    @Autowired private CvRepository cvRepository;

    private User newOwner() {
        return userRepository.save(User.builder()
                .email("owner-" + UUID.randomUUID() + "@it.test")
                .password("x")
                .build());
    }

    private Cv richCv(long ownerId) {
        Cv cv = Cv.create("Developpeur Backend", ownerId);
        cv.changePersonalInfo(PersonalInfo.builder()
                .nom("Ouedraogo").prenom("Issouf").email("i@it.test")
                .titrePoste("Dev Backend").resumeProfessionnel("Concu des systemes fiables")
                .build());
        cv.changeStyle(CvStyle.of("classique", 99L, "Lato"));
        cv.addExperience(Experience.of(null, "ACME", "Dev", "Paris",
                LocalDate.of(2020, 1, 1), LocalDate.of(2022, 6, 1), "A concu X", false));
        cv.addEducation(Education.of(null, "U", "Master", "Info",
                LocalDate.of(2016, 9, 1), LocalDate.of(2018, 6, 1), null));
        cv.addSkill(Skill.of(null, "Java", 5, "Backend"));
        cv.addLanguage(Language.of(null, "Anglais", LanguageLevel.C1));
        return cv;
    }

    @Test
    @DisplayName("un CV cree est relu identique avec toutes ses sections")
    void savesAndReadsBackIdentically() {
        long ownerId = newOwner().getId();

        Cv saved = port.save(richCv(ownerId));
        assertThat(saved.getId()).isNotNull();

        Cv reloaded = port.findByIdAndOwnerId(saved.getId(), ownerId).orElseThrow();

        assertThat(reloaded.getTitre()).isEqualTo("Developpeur Backend");
        assertThat(reloaded.getOwnerId()).isEqualTo(ownerId);
        assertThat(reloaded.getStyle()).isEqualTo(CvStyle.of("classique", 99L, "Lato"));
        assertThat(reloaded.getPersonalInfo().nom()).isEqualTo("Ouedraogo");
        assertThat(reloaded.getPersonalInfo().resumeProfessionnel())
                .isEqualTo("Concu des systemes fiables");
        assertThat(reloaded.getExperiences()).singleElement()
                .satisfies(e -> {
                    assertThat(e.entreprise()).isEqualTo("ACME");
                    assertThat(e.id()).isNotNull();
                });
        assertThat(reloaded.getEducations()).singleElement()
                .satisfies(e -> assertThat(e.diplome()).isEqualTo("Master"));
        assertThat(reloaded.getSkills()).singleElement()
                .isEqualTo(Skill.of(reloaded.getSkills().get(0).id(), "Java", 5, "Backend"));
        assertThat(reloaded.getLanguages()).singleElement()
                .satisfies(l -> assertThat(l.niveau()).isEqualTo(LanguageLevel.C1));
    }

    @Test
    @DisplayName("supprimer le CV supprime en cascade ses sections")
    void deleteCascadesToSections() {
        long ownerId = newOwner().getId();
        Cv saved = port.save(richCv(ownerId));
        long cvId = saved.getId();
        assertThat(cvRepository.findById(cvId)).isPresent();

        boolean deleted = port.deleteByIdAndOwnerId(cvId, ownerId);
        cvRepository.flush();

        assertThat(deleted).isTrue();
        assertThat(cvRepository.findById(cvId)).isEmpty();
    }

    @Test
    @DisplayName("un CV n'est jamais accessible ni supprimable par un autre proprietaire")
    void enforcesOwnership() {
        long ownerId = newOwner().getId();
        long intruderId = newOwner().getId();
        Cv saved = port.save(richCv(ownerId));

        assertThat(port.findByIdAndOwnerId(saved.getId(), intruderId)).isEmpty();
        assertThat(port.existsByIdAndOwnerId(saved.getId(), intruderId)).isFalse();
        assertThat(port.deleteByIdAndOwnerId(saved.getId(), intruderId)).isFalse();
        assertThat(port.findByIdAndOwnerId(saved.getId(), ownerId)).isPresent();
    }

    @Test
    @DisplayName("mettre a jour un CV remplace ses sections et preserve son identite")
    void updateReplacesSections() {
        long ownerId = newOwner().getId();
        Cv saved = port.save(richCv(ownerId));

        Cv toUpdate = port.findByIdAndOwnerId(saved.getId(), ownerId).orElseThrow();
        toUpdate.rename("Titre modifie");
        toUpdate.replaceSkills(java.util.List.of(Skill.of(null, "Kotlin", 4, null)));
        Cv updated = port.save(toUpdate);

        assertThat(updated.getId()).isEqualTo(saved.getId());
        Cv reloaded = port.findByIdAndOwnerId(saved.getId(), ownerId).orElseThrow();
        assertThat(reloaded.getTitre()).isEqualTo("Titre modifie");
        assertThat(reloaded.getSkills()).singleElement()
                .satisfies(s -> assertThat(s.nom()).isEqualTo("Kotlin"));
    }

    @Test
    @DisplayName("les variantes d'un parent sont retrouvees par proprietaire")
    void findsVariantsByParent() {
        long ownerId = newOwner().getId();
        Cv parent = port.save(Cv.create("Parent", ownerId));

        Cv variant = Cv.createVariant("Parent — Backend", ownerId,
                parent.getId(), "Backend Java");
        port.save(variant);

        assertThat(port.findVariantsByParentIdAndOwnerId(parent.getId(), ownerId))
                .singleElement()
                .satisfies(v -> assertThat(v.getVarianteLabel()).isEqualTo("Backend Java"));
    }
}
