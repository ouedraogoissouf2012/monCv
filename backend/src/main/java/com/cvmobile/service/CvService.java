package com.cvmobile.service;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.*;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.cv.ICvService;
import com.cvmobile.service.user.IUserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class CvService implements ICvService {

    private final CvRepository cvRepository;
    private final IUserService userService;
    private final CvMapper cvMapper;

    // ── Lecture ───────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<CvResponse> getAllCvsByUserId(Long userId) {
        return cvRepository.findByUserIdWithDetails(userId).stream()
                .map(cvMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public CvResponse getCvById(Long cvId, Long userId) {
        Cv cv = findCvOrThrow(cvId, userId);
        return cvMapper.toResponse(cv);
    }

    @Transactional(readOnly = true)
    public CvResponse getCvWithDetails(Long cvId) {
        Cv cv = cvRepository.findByIdWithDetails(cvId)
                .orElseThrow(() -> new ResourceNotFoundException("CV", "id", cvId));
        return cvMapper.toResponse(cv);
    }

    @Transactional(readOnly = true)
    public CvResponse getCvByPublicToken(String token) {
        Cv cv = cvRepository.findByPublicToken(token)
                .orElseThrow(() -> new ResourceNotFoundException("Lien de partage invalide ou expire"));
        return cvMapper.toResponse(cv);
    }

    // ── Creation ─────────────────────────────────────────────────

    @Transactional
    public CvResponse createCv(CvRequest request, Long userId) {
        User user = userService.findById(userId);

        Cv cv = Cv.builder()
                .titre(request.getTitre())
                .user(user)
                .build();

        if (request.getPersonalInfo() != null) {
            cv.setPersonalInfo(cvMapper.toPersonalInfo(request.getPersonalInfo()));
        }

        cv = cvRepository.save(cv);
        addNewCollections(cv, request);
        cv = cvRepository.save(cv);

        log.info("CV cree: id={}, titre='{}', userId={}", cv.getId(), cv.getTitre(), userId);
        return cvMapper.toResponse(cv);
    }

    // ── Mise a jour ──────────────────────────────────────────────

    @Transactional
    public CvResponse updateCv(Long cvId, CvRequest request, Long userId) {
        Cv cv = findCvOrThrow(cvId, userId);

        cv.setTitre(request.getTitre());

        if (request.getPersonalInfo() != null) {
            cv.setPersonalInfo(cvMapper.toPersonalInfo(request.getPersonalInfo()));
        }

        smartMergeCollections(cv, request);

        cv = cvRepository.save(cv);
        log.info("CV mis a jour: id={}, userId={}", cvId, userId);
        return cvMapper.toResponse(cv);
    }

    // ── Duplication ──────────────────────────────────────────────

    @Transactional
    public CvResponse duplicateCv(Long cvId, Long userId) {
        Cv original = findCvOrThrow(cvId, userId);
        User user = userService.findById(userId);

        Cv copy = Cv.builder()
                .titre("Copie de " + original.getTitre())
                .user(user)
                .build();

        if (original.getPersonalInfo() != null) {
            copy.setPersonalInfo(cvMapper.clonePersonalInfo(original.getPersonalInfo()));
        }

        Cv savedCopy = cvRepository.save(copy);

        original.getEducations().forEach(e -> savedCopy.addEducation(cvMapper.cloneEducation(e)));
        original.getExperiences().forEach(e -> savedCopy.addExperience(cvMapper.cloneExperience(e)));
        original.getSkills().forEach(s -> savedCopy.addSkill(cvMapper.cloneSkill(s)));
        original.getLanguages().forEach(l -> savedCopy.addLanguage(cvMapper.cloneLanguage(l)));
        original.getCertifications().forEach(c -> savedCopy.addCertification(cvMapper.cloneCertification(c)));
        original.getProjects().forEach(p -> savedCopy.addProject(cvMapper.cloneProject(p)));

        Cv saved = cvRepository.save(savedCopy);
        log.info("CV duplique: original={}, copie={}, userId={}", cvId, saved.getId(), userId);
        return cvMapper.toResponse(saved);
    }

    // ── Partage ──────────────────────────────────────────────────

    @Transactional
    public CvResponse generateShareToken(Long cvId, Long userId) {
        Cv cv = findCvOrThrow(cvId, userId);
        if (cv.getPublicToken() == null) {
            cv.setPublicToken(UUID.randomUUID().toString().replace("-", ""));
            cv = cvRepository.save(cv);
            log.info("Token de partage genere pour CV id={}", cvId);
        }
        return cvMapper.toResponse(cv);
    }

    // ── Suppression ──────────────────────────────────────────────

    @Transactional
    public void deleteCv(Long cvId, Long userId) {
        if (!cvRepository.existsByIdAndUserId(cvId, userId)) {
            throw new ResourceNotFoundException("CV", "id", cvId);
        }
        cvRepository.deleteById(cvId);
        log.info("CV supprime: id={}, userId={}", cvId, userId);
    }

    // ── Helpers prives ───────────────────────────────────────────

    private Cv findCvOrThrow(Long cvId, Long userId) {
        return cvRepository.findByIdAndUserId(cvId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("CV", "id", cvId));
    }

    private void addNewCollections(Cv cv, CvRequest request) {
        if (request.getExperiences() != null)
            request.getExperiences().forEach(d -> cv.addExperience(cvMapper.toExperience(d)));
        if (request.getEducations() != null)
            request.getEducations().forEach(d -> cv.addEducation(cvMapper.toEducation(d)));
        if (request.getSkills() != null)
            request.getSkills().forEach(d -> cv.addSkill(cvMapper.toSkill(d)));
        if (request.getLanguages() != null)
            request.getLanguages().forEach(d -> cv.addLanguage(cvMapper.toLanguage(d)));
        if (request.getCertifications() != null)
            request.getCertifications().forEach(d -> cv.addCertification(cvMapper.toCertification(d)));
        if (request.getProjects() != null)
            request.getProjects().forEach(d -> cv.addProject(cvMapper.toProject(d)));
    }

    /**
     * Smart merge : compare les collections existantes avec les nouvelles.
     * - Si l'element a un ID qui existe deja → update in place
     * - Si l'element n'a pas d'ID → insert (nouveau)
     * - Si un element existant n'est plus dans la requete → delete
     */
    private void smartMergeCollections(Cv cv, CvRequest request) {
        mergeExperiences(cv, request.getExperiences());
        mergeEducations(cv, request.getEducations());
        mergeSkills(cv, request.getSkills());
        mergeLanguages(cv, request.getLanguages());
        mergeCertifications(cv, request.getCertifications());
        mergeProjects(cv, request.getProjects());
    }

    private void mergeExperiences(Cv cv, List<CvRequest.ExperienceDto> dtos) {
        if (dtos == null) { cv.getExperiences().clear(); return; }
        var existing = cv.getExperiences();
        var existingById = existing.stream().filter(e -> e.getId() != null)
                .collect(Collectors.toMap(Experience::getId, e -> e));
        var newIds = dtos.stream().map(CvRequest.ExperienceDto::getId)
                .filter(id -> id != null).collect(Collectors.toSet());

        existing.removeIf(e -> e.getId() != null && !newIds.contains(e.getId()));

        for (var dto : dtos) {
            if (dto.getId() != null && existingById.containsKey(dto.getId())) {
                cvMapper.updateExperience(dto, existingById.get(dto.getId()));
            } else {
                cv.addExperience(cvMapper.toExperience(dto));
            }
        }
    }

    private void mergeEducations(Cv cv, List<CvRequest.EducationDto> dtos) {
        if (dtos == null) { cv.getEducations().clear(); return; }
        var existing = cv.getEducations();
        var existingById = existing.stream().filter(e -> e.getId() != null)
                .collect(Collectors.toMap(Education::getId, e -> e));
        var newIds = dtos.stream().map(CvRequest.EducationDto::getId)
                .filter(id -> id != null).collect(Collectors.toSet());

        existing.removeIf(e -> e.getId() != null && !newIds.contains(e.getId()));

        for (var dto : dtos) {
            if (dto.getId() != null && existingById.containsKey(dto.getId())) {
                cvMapper.updateEducation(dto, existingById.get(dto.getId()));
            } else {
                cv.addEducation(cvMapper.toEducation(dto));
            }
        }
    }

    private void mergeSkills(Cv cv, List<CvRequest.SkillDto> dtos) {
        if (dtos == null) { cv.getSkills().clear(); return; }
        var existing = cv.getSkills();
        var existingById = existing.stream().filter(e -> e.getId() != null)
                .collect(Collectors.toMap(Skill::getId, e -> e));
        var newIds = dtos.stream().map(CvRequest.SkillDto::getId)
                .filter(id -> id != null).collect(Collectors.toSet());

        existing.removeIf(e -> e.getId() != null && !newIds.contains(e.getId()));

        for (var dto : dtos) {
            if (dto.getId() != null && existingById.containsKey(dto.getId())) {
                cvMapper.updateSkill(dto, existingById.get(dto.getId()));
            } else {
                cv.addSkill(cvMapper.toSkill(dto));
            }
        }
    }

    private void mergeLanguages(Cv cv, List<CvRequest.LanguageDto> dtos) {
        if (dtos == null) { cv.getLanguages().clear(); return; }
        var existing = cv.getLanguages();
        var existingById = existing.stream().filter(e -> e.getId() != null)
                .collect(Collectors.toMap(Language::getId, e -> e));
        var newIds = dtos.stream().map(CvRequest.LanguageDto::getId)
                .filter(id -> id != null).collect(Collectors.toSet());

        existing.removeIf(e -> e.getId() != null && !newIds.contains(e.getId()));

        for (var dto : dtos) {
            if (dto.getId() != null && existingById.containsKey(dto.getId())) {
                cvMapper.updateLanguage(dto, existingById.get(dto.getId()));
            } else {
                cv.addLanguage(cvMapper.toLanguage(dto));
            }
        }
    }

    private void mergeCertifications(Cv cv, List<CvRequest.CertificationDto> dtos) {
        if (dtos == null) { cv.getCertifications().clear(); return; }
        var existing = cv.getCertifications();
        var existingById = existing.stream().filter(e -> e.getId() != null)
                .collect(Collectors.toMap(Certification::getId, e -> e));
        var newIds = dtos.stream().map(CvRequest.CertificationDto::getId)
                .filter(id -> id != null).collect(Collectors.toSet());

        existing.removeIf(e -> e.getId() != null && !newIds.contains(e.getId()));

        for (var dto : dtos) {
            if (dto.getId() != null && existingById.containsKey(dto.getId())) {
                cvMapper.updateCertification(dto, existingById.get(dto.getId()));
            } else {
                cv.addCertification(cvMapper.toCertification(dto));
            }
        }
    }

    private void mergeProjects(Cv cv, List<CvRequest.ProjectDto> dtos) {
        if (dtos == null) { cv.getProjects().clear(); return; }
        var existing = cv.getProjects();
        var existingById = existing.stream().filter(e -> e.getId() != null)
                .collect(Collectors.toMap(Project::getId, e -> e));
        var newIds = dtos.stream().map(CvRequest.ProjectDto::getId)
                .filter(id -> id != null).collect(Collectors.toSet());

        existing.removeIf(e -> e.getId() != null && !newIds.contains(e.getId()));

        for (var dto : dtos) {
            if (dto.getId() != null && existingById.containsKey(dto.getId())) {
                cvMapper.updateProject(dto, existingById.get(dto.getId()));
            } else {
                cv.addProject(cvMapper.toProject(dto));
            }
        }
    }
}
