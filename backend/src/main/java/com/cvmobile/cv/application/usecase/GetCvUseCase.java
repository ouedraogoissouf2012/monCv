package com.cvmobile.cv.application.usecase;

import com.cvmobile.cv.application.CvNotFoundException;
import com.cvmobile.cv.application.port.out.CvRepositoryPort;
import com.cvmobile.cv.domain.model.Cv;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Recupere un CV appartenant a un proprietaire donne (issue #255).
 *
 * <p>La frontiere transactionnelle est portee ici, en lecture seule, et non
 * dans un adaptateur web (ADR 003).
 */
@Service
public class GetCvUseCase {

    private final CvRepositoryPort repository;

    public GetCvUseCase(CvRepositoryPort repository) {
        this.repository = repository;
    }

    /**
     * @throws CvNotFoundException si aucun CV ne correspond pour ce proprietaire
     */
    @Transactional(readOnly = true)
    public Cv get(long cvId, long ownerId) {
        return repository.findByIdAndOwnerId(cvId, ownerId)
                .orElseThrow(() -> new CvNotFoundException(cvId));
    }
}
