package com.cvmobile.cv.application.usecase;

import com.cvmobile.cv.application.CvNotFoundException;
import com.cvmobile.cv.application.port.out.CvRepositoryPort;
import com.cvmobile.cv.domain.model.Cv;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Corbeille des CV : lister, restaurer, purger (issue #509). */
@Service
public class CvTrashUseCase {

    private final CvRepositoryPort repository;

    public CvTrashUseCase(CvRepositoryPort repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public List<Cv> list(long ownerId) {
        return repository.findDeletedByOwnerId(ownerId);
    }

    @Transactional
    public void restore(long cvId, long ownerId) {
        if (!repository.restoreByIdAndOwnerId(cvId, ownerId)) {
            throw new CvNotFoundException(cvId);
        }
    }

    @Transactional
    public void purge(long cvId, long ownerId) {
        if (!repository.purgeByIdAndOwnerId(cvId, ownerId)) {
            throw new CvNotFoundException(cvId);
        }
    }
}
