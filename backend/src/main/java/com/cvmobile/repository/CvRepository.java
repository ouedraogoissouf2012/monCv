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

    List<Cv> findByUserId(Long userId);

    @Query("SELECT c FROM Cv c WHERE c.id = :cvId AND c.user.id = :userId")
    Optional<Cv> findByIdAndUserId(@Param("cvId") Long cvId, @Param("userId") Long userId);

    @Query("SELECT c FROM Cv c LEFT JOIN FETCH c.educations LEFT JOIN FETCH c.experiences LEFT JOIN FETCH c.skills LEFT JOIN FETCH c.languages WHERE c.id = :id")
    Optional<Cv> findByIdWithDetails(@Param("id") Long id);

    boolean existsByIdAndUserId(Long id, Long userId);

    Optional<Cv> findByPublicToken(String publicToken);
}
