package com.cvmobile.service;

import com.cvmobile.dto.*;
import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.model.*;
import com.cvmobile.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class JobApplicationService {
    private final JobApplicationRepository applications;
    private final CvRepository cvs;

    @Transactional(readOnly = true)
    public List<JobApplicationResponse> list(
            Long userId, JobApplicationStatus status, LocalDate fromDate, LocalDate toDate) {
        return applications.findForUser(userId, status, fromDate, toDate).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public JobApplicationResponse create(JobApplicationRequest request, User user) {
        JobApplication value = new JobApplication();
        value.setUser(user);
        apply(value, request, user.getId());
        return toResponse(applications.save(value));
    }

    @Transactional
    public JobApplicationResponse update(Long id, JobApplicationRequest request, Long userId) {
        JobApplication value = findOwned(id, userId);
        apply(value, request, userId);
        return toResponse(applications.save(value));
    }

    @Transactional
    public void delete(Long id, Long userId) {
        applications.delete(findOwned(id, userId));
    }

    private JobApplication findOwned(Long id, Long userId) {
        return applications.findOwnedById(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Candidature", "id", id));
    }

    private void apply(JobApplication value, JobApplicationRequest request, Long userId) {
        value.setCv(resolveCv(request.getCvId(), userId));
        value.setCompany(request.getCompany().trim());
        value.setPosition(request.getPosition().trim());
        value.setOfferUrl(trimToNull(request.getOfferUrl()));
        value.setStatus(request.getStatus());
        value.setSentDate(request.getSentDate());
        value.setNextFollowUp(request.getNextFollowUp());
        value.setNotes(trimToNull(request.getNotes()));
    }

    private Cv resolveCv(Long cvId, Long userId) {
        if (cvId == null) return null;
        return cvs.findByIdAndUserId(cvId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("CV", "id", cvId));
    }

    private String trimToNull(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }

    private JobApplicationResponse toResponse(JobApplication value) {
        Cv cv = value.getCv();
        return JobApplicationResponse.builder()
                .id(value.getId())
                .cvId(cv == null ? null : cv.getId())
                .cvTitle(cv == null ? null : cv.getTitre())
                .cvVariant(cv != null && cv.isVariante())
                .company(value.getCompany())
                .position(value.getPosition())
                .offerUrl(value.getOfferUrl())
                .status(value.getStatus())
                .sentDate(value.getSentDate())
                .nextFollowUp(value.getNextFollowUp())
                .notes(value.getNotes())
                .createdAt(value.getCreatedAt())
                .updatedAt(value.getUpdatedAt())
                .build();
    }
}
