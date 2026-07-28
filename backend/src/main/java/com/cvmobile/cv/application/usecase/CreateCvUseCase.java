package com.cvmobile.cv.application.usecase;

import com.cvmobile.cv.application.port.out.CvRepositoryPort;
import com.cvmobile.cv.domain.model.Cv;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Persiste un nouveau CV (issue #255).
 *
 * <p>Recoit un agregat de domaine deja construit et valide (invariants portes
 * par {@link Cv}); l'assemblage depuis une requete entrante releve de
 * l'adaptateur web.
 */
@Service
public class CreateCvUseCase {

    private final CvRepositoryPort repository;

    public CreateCvUseCase(CvRepositoryPort repository) {
        this.repository = repository;
    }

    @Transactional
    public Cv create(Cv draft) {
        return repository.save(draft);
    }
}
