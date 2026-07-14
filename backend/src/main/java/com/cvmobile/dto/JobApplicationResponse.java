package com.cvmobile.dto;

import com.cvmobile.model.JobApplicationStatus;
import lombok.Builder;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Builder
public record JobApplicationResponse(
        Long id,
        Long cvId,
        String cvTitle,
        boolean cvVariant,
        String company,
        String position,
        String offerUrl,
        JobApplicationStatus status,
        LocalDate sentDate,
        LocalDate nextFollowUp,
        String notes,
        LocalDateTime createdAt,
        LocalDateTime updatedAt) {
}
