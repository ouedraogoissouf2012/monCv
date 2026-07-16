package com.cvmobile.repository;

import com.cvmobile.model.Cv;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.time.LocalDateTime;

@Repository
public interface CvRepository extends JpaRepository<Cv, Long> {

    // Query simple — les collections sont chargees via @BatchSize sur l'entite Cv
    @Query("SELECT c FROM Cv c WHERE c.user.id = :userId ORDER BY c.updatedAt DESC")
    List<Cv> findByUserIdWithDetails(@Param("userId") Long userId);

    List<Cv> findByUserId(Long userId);

    @Query("SELECT c FROM Cv c WHERE c.id = :cvId AND c.user.id = :userId")
    Optional<Cv> findByIdAndUserId(@Param("cvId") Long cvId, @Param("userId") Long userId);

    boolean existsByIdAndUserId(Long id, Long userId);

    Optional<Cv> findByPublicToken(String publicToken);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Cv c SET c.viewCount = c.viewCount + 1 WHERE c.id = :cvId")
    int incrementViewCount(@Param("cvId") Long cvId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Cv c SET c.downloadCount = c.downloadCount + 1 WHERE c.id = :cvId")
    int incrementDownloadCount(@Param("cvId") Long cvId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Cv c SET c.shareCount = c.shareCount + 1 WHERE c.id = :cvId")
    int incrementShareCount(@Param("cvId") Long cvId);

    // ── Variantes ───────────────────────────────────────────────
    List<Cv> findByParentIdAndUserId(Long parentId, Long userId);

    @Query("SELECT c.parent.id, COUNT(c) FROM Cv c WHERE c.parent.id IN :parentIds GROUP BY c.parent.id")
    List<Object[]> countVariantsByParentIds(@Param("parentIds") List<Long> parentIds);
    List<Cv> findByUpdatedAtBefore(LocalDateTime cutoff);
}
