package com.cvmobile.repository;

import com.cvmobile.model.Cv;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CvRepository extends JpaRepository<Cv, Long> {

    // Query simple — les collections sont chargees via @BatchSize sur l'entite Cv
    @Query("SELECT c FROM Cv c WHERE c.user.id = :userId ORDER BY c.updatedAt DESC")
    List<Cv> findByUserIdWithDetails(@Param("userId") Long userId);

    List<Cv> findByUserId(Long userId);

    @Query("SELECT c FROM Cv c WHERE c.id = :cvId AND c.user.id = :userId")
    Optional<Cv> findByIdAndUserId(@Param("cvId") Long cvId, @Param("userId") Long userId);

    @Query("SELECT c FROM Cv c WHERE c.id = :id")
    Optional<Cv> findByIdWithDetails(@Param("id") Long id);

    boolean existsByIdAndUserId(Long id, Long userId);

    Optional<Cv> findByPublicToken(String publicToken);
}
