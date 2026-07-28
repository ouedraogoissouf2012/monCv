package com.cvmobile.cv.application.usecase;

import com.cvmobile.cv.application.port.out.CvRepositoryPort;
import com.cvmobile.cv.domain.model.Cv;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Liste les CV d'un proprietaire (issue #255).
 */
@Service
public class ListCvsUseCase {

    private final CvRepositoryPort repository;

    public ListCvsUseCase(CvRepositoryPort repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public List<Cv> list(long ownerId) {
        return repository.findAllByOwnerId(ownerId);
    }
}
