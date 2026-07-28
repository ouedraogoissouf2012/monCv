package com.cvmobile.cv.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.cvmobile.cv.domain.model.Cv;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Conformite du double en memoire au contrat de {@code CvRepositoryPort}.
 * Un fake qui ne respecte pas le contrat rendrait les tests de use cases
 * trompeurs : on le verifie donc explicitement.
 */
@DisplayName("InMemoryCvRepository (conformite au contrat du port)")
class InMemoryCvRepositoryTest {

    private static final long OWNER = 7L;
    private static final long OTHER = 99L;

    private InMemoryCvRepository repo;

    @BeforeEach
    void setUp() {
        repo = new InMemoryCvRepository();
    }

    @Test
    @DisplayName("save d'un CV neuf attribue un identifiant et le rend relisible")
    void savesNewAssignsId() {
        Cv saved = repo.save(Cv.create("CV", OWNER));

        assertThat(saved.getId()).isNotNull();
        assertThat(repo.findByIdAndOwnerId(saved.getId(), OWNER)).contains(saved);
    }

    @Test
    @DisplayName("save de deux CV neufs attribue des identifiants distincts")
    void savesDistinctIds() {
        Cv a = repo.save(Cv.create("A", OWNER));
        Cv b = repo.save(Cv.create("B", OWNER));

        assertThat(a.getId()).isNotEqualTo(b.getId());
        assertThat(repo.count()).isEqualTo(2);
    }

    @Test
    @DisplayName("un CV n'est jamais visible d'un autre proprietaire")
    void isolatesByOwner() {
        Cv saved = repo.save(Cv.create("CV", OWNER));

        assertThat(repo.findByIdAndOwnerId(saved.getId(), OTHER)).isEmpty();
        assertThat(repo.existsByIdAndOwnerId(saved.getId(), OTHER)).isFalse();
        assertThat(repo.findAllByOwnerId(OTHER)).isEmpty();
    }

    @Test
    @DisplayName("delete restreint au proprietaire")
    void deleteRestrictedToOwner() {
        Cv saved = repo.save(Cv.create("CV", OWNER));

        assertThat(repo.deleteByIdAndOwnerId(saved.getId(), OTHER)).isFalse();
        assertThat(repo.deleteByIdAndOwnerId(saved.getId(), OWNER)).isTrue();
        assertThat(repo.findByIdAndOwnerId(saved.getId(), OWNER)).isEmpty();
    }

    @Test
    @DisplayName("les variantes sont retrouvees par parent et proprietaire")
    void findsVariants() {
        Cv parent = repo.save(Cv.create("Parent", OWNER));
        repo.save(Cv.createVariant("V", OWNER, parent.getId(), "Backend"));

        assertThat(repo.findVariantsByParentIdAndOwnerId(parent.getId(), OWNER)).hasSize(1);
        assertThat(repo.findVariantsByParentIdAndOwnerId(parent.getId(), OTHER)).isEmpty();
    }
}
