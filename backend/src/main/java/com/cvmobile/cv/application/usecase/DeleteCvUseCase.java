package com.cvmobile.cv.application.usecase;

import com.cvmobile.cv.application.CvNotFoundException;
import com.cvmobile.cv.application.port.out.CvRepositoryPort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Supprime un CV appartenant a un proprietaire donne (issue #255).
 */
@Service
public class DeleteCvUseCase {

    private final CvRepositoryPort repository;

    public DeleteCvUseCase(CvRepositoryPort repository) {
        this.repository = repository;
    }

    /**
     * @throws CvNotFoundException si aucun CV possede ne correspond
     */
    @Transactional
    public void delete(long cvId, long ownerId) {
        if (!repository.deleteByIdAndOwnerId(cvId, ownerId)) {
            throw new CvNotFoundException(cvId);
        }
    }
}
