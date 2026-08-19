package com.cvmobile.cv.application.usecase;

import com.cvmobile.cv.application.CvNotFoundException;
import com.cvmobile.cv.application.InMemoryCvRepository;
import com.cvmobile.cv.domain.model.Cv;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CvTrashUseCaseTest {

    private static final long OWNER = 7L;
    private InMemoryCvRepository repo;
    private CreateCvUseCase createCv;
    private DeleteCvUseCase deleteCv;
    private CvTrashUseCase trash;

    @BeforeEach
    void setUp() {
        repo = new InMemoryCvRepository();
        createCv = new CreateCvUseCase(repo);
        deleteCv = new DeleteCvUseCase(repo);
        trash = new CvTrashUseCase(repo);
    }

    @Test
    void restoreRemetLeCvDansLaListeActive() {
        Cv created = createCv.create(Cv.create("Mon CV", OWNER));
        deleteCv.delete(created.getId(), OWNER);

        assertThat(repo.findByIdAndOwnerId(created.getId(), OWNER)).isEmpty();
        trash.restore(created.getId(), OWNER);
        assertThat(repo.findByIdAndOwnerId(created.getId(), OWNER)).isPresent();
    }

    @Test
    void purgeSupprimeDefinitivement() {
        Cv created = createCv.create(Cv.create("Mon CV", OWNER));
        deleteCv.delete(created.getId(), OWNER);

        trash.purge(created.getId(), OWNER);

        assertThat(repo.findDeletedByOwnerId(OWNER)).isEmpty();
        assertThatThrownBy(() -> trash.restore(created.getId(), OWNER))
                .isInstanceOf(CvNotFoundException.class);
    }
}
