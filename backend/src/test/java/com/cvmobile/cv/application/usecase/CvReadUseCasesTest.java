package com.cvmobile.cv.application.usecase;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.cvmobile.cv.application.CvNotFoundException;
import com.cvmobile.cv.application.InMemoryCvRepository;
import com.cvmobile.cv.domain.model.Cv;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Use case de lecture d'un CV (Get), teste en isolation avec un double en
 * memoire du port (sans Spring ni base).
 */
@DisplayName("Use case de lecture (Get)")
class CvReadUseCasesTest {

    private static final long OWNER = 7L;
    private static final long OTHER = 99L;

    private InMemoryCvRepository repo;
    private GetCvUseCase getCv;

    @BeforeEach
    void setUp() {
        repo = new InMemoryCvRepository();
        getCv = new GetCvUseCase(repo);
    }

    @Test
    @DisplayName("Get retourne le CV possede")
    void getReturnsOwnedCv() {
        Cv saved = repo.save(Cv.create("Mon CV", OWNER));

        Cv found = getCv.get(saved.getId(), OWNER);

        assertThat(found.getId()).isEqualTo(saved.getId());
        assertThat(found.getTitre()).isEqualTo("Mon CV");
    }

    @Test
    @DisplayName("Get echoue si le CV n'existe pas, en portant l'identifiant demande")
    void getFailsWhenAbsent() {
        assertThatThrownBy(() -> getCv.get(404L, OWNER))
                .isInstanceOf(CvNotFoundException.class)
                .asInstanceOf(org.assertj.core.api.InstanceOfAssertFactories.type(
                        CvNotFoundException.class))
                .satisfies(ex -> assertThat(ex.cvId()).isEqualTo(404L));
    }

    @Test
    @DisplayName("Get echoue si le CV appartient a un autre proprietaire")
    void getFailsForOtherOwner() {
        Cv saved = repo.save(Cv.create("Mon CV", OWNER));

        assertThatThrownBy(() -> getCv.get(saved.getId(), OTHER))
                .isInstanceOf(CvNotFoundException.class);
    }
}
