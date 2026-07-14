package com.cvmobile.repository;

import com.cvmobile.model.JobApplication;
import com.cvmobile.model.JobApplicationStatus;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface JobApplicationRepository extends JpaRepository<JobApplication, Long> {
    @Query("""
        select a from JobApplication a
        left join fetch a.cv
        where a.user.id = :userId
          and (:status is null or a.status = :status)
          and (:fromDate is null or a.sentDate >= :fromDate)
          and (:toDate is null or a.sentDate <= :toDate)
        order by case when a.nextFollowUp is null then 1 else 0 end,
                 a.nextFollowUp asc, a.updatedAt desc
        """)
    List<JobApplication> findForUser(
            @Param("userId") Long userId,
            @Param("status") JobApplicationStatus status,
            @Param("fromDate") LocalDate fromDate,
            @Param("toDate") LocalDate toDate);

    @Query("select a from JobApplication a left join fetch a.cv where a.id = :id and a.user.id = :userId")
    Optional<JobApplication> findOwnedById(@Param("id") Long id, @Param("userId") Long userId);

    List<JobApplication> findByNextFollowUpLessThanEqualAndStatusNotIn(
            LocalDate date, List<JobApplicationStatus> statuses);
}
