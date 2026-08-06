package com.cvmobile.service.cv;

import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.model.Cv;
import com.cvmobile.repository.CvRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * Recherche d'un CV appartenant a un utilisateur (issue #254).
 *
 * Centralise le lookup + controle de propriete partage par le CRUD, le partage
 * et les variantes, evitant la duplication du {@code findCvOrThrow} dans chaque
 * service.
 */
@Component
@RequiredArgsConstructor
public class CvFinder {

    private final CvRepository cvRepository;

    /**
     * Retourne le CV {@code cvId} appartenant a {@code userId}, ou leve une
     * {@link ResourceNotFoundException} s'il n'existe pas / n'appartient pas a
     * l'utilisateur.
     */
    public Cv findByIdAndUserId(Long cvId, Long userId) {
        return cvRepository.findByIdAndUserId(cvId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("CV", "id", cvId));
    }
}
