package com.cvmobile.repository;

import com.cvmobile.model.CvView;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public interface CvViewRepository extends JpaRepository<CvView, Long> {

    /**
     * Verifie si une vue recente existe pour ce CV + IP hash.
     * Utilise pour le deduplication (meme visiteur dans un delai court).
     */
    boolean existsByCvIdAndIpHashAndViewedAtAfter(Long cvId, String ipHash, LocalDateTime after);
}
