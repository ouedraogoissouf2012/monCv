package com.cvmobile.repository;

import com.cvmobile.model.Cv;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.time.LocalDateTime;

@Repository
public interface CvRepository extends JpaRepository<Cv, Long> {

    // Query simple — les collections sont chargees via @BatchSize sur l'entite Cv
    @Query("SELECT c FROM Cv c WHERE c.user.id = :userId AND c.deletedAt IS NULL ORDER BY c.updatedAt DESC")
    List<Cv> findByUserIdWithDetails(@Param("userId") Long userId);

    @Query("SELECT c FROM Cv c WHERE c.user.id = :userId AND c.deletedAt IS NULL")
    List<Cv> findByUserId(@Param("userId") Long userId);

    @Query("SELECT c FROM Cv c WHERE c.id = :cvId AND c.user.id = :userId AND c.deletedAt IS NULL")
    Optional<Cv> findByIdAndUserId(@Param("cvId") Long cvId, @Param("userId") Long userId);

    @Query("SELECT CASE WHEN COUNT(c) > 0 THEN true ELSE false END FROM Cv c "
            + "WHERE c.id = :id AND c.user.id = :userId AND c.deletedAt IS NULL")
    boolean existsByIdAndUserId(@Param("id") Long id, @Param("userId") Long userId);

    @Query("SELECT c FROM Cv c WHERE c.publicToken = :publicToken AND c.deletedAt IS NULL")
    Optional<Cv> findByPublicToken(@Param("publicToken") String publicToken);

    @Query("SELECT c FROM Cv c WHERE c.publicTokenHash = :publicTokenHash AND c.deletedAt IS NULL")
    Optional<Cv> findByPublicTokenHash(@Param("publicTokenHash") String publicTokenHash);

    @Query("SELECT c FROM Cv c WHERE c.publicToken IS NOT NULL "
            + "AND c.publicTokenHash IS NULL ORDER BY c.id")
    List<Cv> findLegacyPublicTokens(Pageable pageable);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Cv c SET c.viewCount = c.viewCount + 1 WHERE c.id = :cvId")
    int incrementViewCount(@Param("cvId") Long cvId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Cv c SET c.downloadCount = c.downloadCount + 1 "
            + "WHERE c.id = :cvId AND c.publicDownloadsEnabled = true")
    int incrementDownloadCount(@Param("cvId") Long cvId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Cv c SET c.shareCount = c.shareCount + 1 WHERE c.id = :cvId")
    int incrementShareCount(@Param("cvId") Long cvId);

    // ── Variantes ───────────────────────────────────────────────
    @Query("SELECT c FROM Cv c WHERE c.parent.id = :parentId AND c.user.id = :userId AND c.deletedAt IS NULL")
    List<Cv> findByParentIdAndUserId(@Param("parentId") Long parentId, @Param("userId") Long userId);

    @Query("SELECT c.parent.id, COUNT(c) FROM Cv c WHERE c.parent.id IN :parentIds AND c.deletedAt IS NULL GROUP BY c.parent.id")
    List<Object[]> countVariantsByParentIds(@Param("parentIds") List<Long> parentIds);

    /**
     * CV inactifs (updated_at anterieur au seuil), utilisateur charge en une
     * seule requete (evite le N+1) et pagines pour borner la memoire du cron de
     * rappels (M-5). L'index idx_cvs_updated_at (V16) sert ce filtre.
     */
    @Query("SELECT c FROM Cv c JOIN FETCH c.user WHERE c.updatedAt < :cutoff AND c.deletedAt IS NULL ORDER BY c.id")
    List<Cv> findStaleWithUser(@Param("cutoff") LocalDateTime cutoff, Pageable pageable);

    @Query("SELECT c FROM Cv c WHERE c.user.id = :userId AND c.deletedAt IS NOT NULL ORDER BY c.deletedAt DESC")
    List<Cv> findDeletedByUserId(@Param("userId") Long userId);

    @Query("SELECT c FROM Cv c WHERE c.id = :cvId AND c.user.id = :userId AND c.deletedAt IS NOT NULL")
    Optional<Cv> findDeletedByIdAndUserId(@Param("cvId") Long cvId, @Param("userId") Long userId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Cv c SET c.deletedAt = :now WHERE c.id = :cvId AND c.user.id = :userId AND c.deletedAt IS NULL")
    int softDelete(@Param("cvId") Long cvId, @Param("userId") Long userId, @Param("now") LocalDateTime now);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Cv c SET c.deletedAt = null WHERE c.id = :cvId AND c.user.id = :userId AND c.deletedAt IS NOT NULL")
    int restore(@Param("cvId") Long cvId, @Param("userId") Long userId);
}
