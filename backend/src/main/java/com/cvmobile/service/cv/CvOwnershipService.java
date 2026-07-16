package com.cvmobile.service.cv;

import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.model.Cv;
import com.cvmobile.repository.CvRepository;
import lombok.RequiredArgsConstructor;
import org.hibernate.Hibernate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Loads a private CV with its ownership checked and details materialized. */
@Service
@RequiredArgsConstructor
public class CvOwnershipService {

    private final CvRepository cvRepository;

    @Transactional(readOnly = true)
    public Cv requireOwnedCv(Long cvId, Long userId) {
        Cv cv = cvRepository.findByIdAndUserId(cvId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("CV", "id", cvId));
        Hibernate.initialize(cv.getUser());
        Hibernate.initialize(cv.getEducations());
        Hibernate.initialize(cv.getExperiences());
        Hibernate.initialize(cv.getSkills());
        Hibernate.initialize(cv.getLanguages());
        Hibernate.initialize(cv.getCertifications());
        Hibernate.initialize(cv.getProjects());
        return cv;
    }
}
