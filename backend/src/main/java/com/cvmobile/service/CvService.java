package com.cvmobile.service;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.dto.PublicShareSettingsRequest;
import com.cvmobile.exception.ResourceNotFoundException;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.Cv;
import com.cvmobile.model.User;
import com.cvmobile.observability.BusinessMetrics;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.cv.CvCollectionMerger;
import com.cvmobile.service.cv.CvFinder;
import com.cvmobile.service.cv.CvShareService;
import com.cvmobile.service.cv.CvVariantService;
import com.cvmobile.service.cv.ICvService;
import com.cvmobile.service.user.IUserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Service CRUD des CVs et facade du contrat {@link ICvService} (issue #254).
 *
 * Porte les operations CRUD (lecture, creation, mise a jour, duplication,
 * suppression) et delegue les responsabilites specialisees : partage a
 * {@link CvShareService}, variantes IA a {@link CvVariantService}, fusion des
 * collections a {@link CvCollectionMerger}. Les frontieres transactionnelles
 * restent portees ici, sur les methodes publiques.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CvService implements ICvService {

    private final CvRepository cvRepository;
    private final IUserService userService;
    private final CvMapper cvMapper;
    private final BusinessMetrics businessMetrics;
    private final CvFinder cvFinder;
    private final CvCollectionMerger collectionMerger;
    private final CvShareService shareService;
    private final CvVariantService variantService;

    // ── Lecture ───────────────────────────────────────────────────

    @Override
    @Transactional(readOnly = true)
    public List<CvResponse> getAllCvsByUserId(Long userId) {
        List<Cv> cvs = cvRepository.findByUserIdWithDetails(userId);
        List<CvResponse> responses = cvs.stream()
                .map(cvMapper::toResponse)
                .collect(Collectors.toList());

        // Enrichir avec le compteur de variantes pour chaque CV parent
        List<Long> parentIds = cvs.stream()
                .filter(cv -> !cv.isVariante())
                .map(Cv::getId)
                .collect(Collectors.toList());

        if (!parentIds.isEmpty()) {
            Map<Long, Long> countMap = cvRepository.countVariantsByParentIds(parentIds).stream()
                    .collect(Collectors.toMap(
                            row -> (Long) row[0],
                            row -> (Long) row[1]
                    ));
            responses.forEach(r -> {
                Long count = countMap.get(r.getId());
                if (count != null) r.setVariantCount(count.intValue());
            });
        }

        return responses;
    }

    @Override
    @Transactional(readOnly = true)
    public CvResponse getCvById(Long cvId, Long userId) {
        return cvMapper.toResponse(cvFinder.findByIdAndUserId(cvId, userId));
    }

    // ── Creation / mise a jour / duplication / suppression ────────

    @Override
    @Transactional
    public CvResponse createCv(CvRequest request, Long userId) {
        User user = userService.findById(userId);

        Cv cv = Cv.builder()
                .titre(request.getTitre())
                .user(user)
                .build();

        applyStyle(cv, request.getStyle());

        if (request.getPersonalInfo() != null) {
            cv.setPersonalInfo(cvMapper.toPersonalInfo(request.getPersonalInfo()));
        }

        cv = cvRepository.save(cv);
        addNewCollections(cv, request);
        cv = cvRepository.save(cv);

        log.info("CV cree: id={}, titre='{}', userId={}", cv.getId(), cv.getTitre(), userId);
        businessMetrics.recordCvCreated(resolveTemplateTag(request));
        return cvMapper.toResponse(cv);
    }

    @Override
    @Transactional
    public CvResponse updateCv(Long cvId, CvRequest request, Long userId) {
        Cv cv = cvFinder.findByIdAndUserId(cvId, userId);

        cv.setTitre(request.getTitre());
        applyStyle(cv, request.getStyle());

        if (request.getPersonalInfo() != null) {
            cv.setPersonalInfo(cvMapper.toPersonalInfo(request.getPersonalInfo()));
        }

        collectionMerger.mergeCollections(cv, request);

        cv = cvRepository.save(cv);
        log.info("CV mis a jour: id={}, userId={}", cvId, userId);
        return cvMapper.toResponse(cv);
    }

    @Override
    @Transactional
    public CvResponse duplicateCv(Long cvId, Long userId) {
        Cv original = cvFinder.findByIdAndUserId(cvId, userId);
        User user = userService.findById(userId);

        Cv copy = Cv.builder()
                .titre("Copie de " + original.getTitre())
                .user(user)
                .styleTemplateId(original.getStyleTemplateId())
                .stylePrimaryColor(original.getStylePrimaryColor())
                .styleFontFamily(original.getStyleFontFamily())
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

    @Override
    @Transactional
    public void deleteCv(Long cvId, Long userId) {
        if (!cvRepository.existsByIdAndUserId(cvId, userId)) {
            throw new ResourceNotFoundException("CV", "id", cvId);
        }
        cvRepository.deleteById(cvId);
        log.info("CV supprime: id={}, userId={}", cvId, userId);
    }

    // ── Variantes (deleguees) ─────────────────────────────────────

    @Override
    public CvResponse createVariant(Long parentCvId, String jobDescription, String label, Long userId) {
        // Adaptation IA HORS transaction (appel HTTP externe : ne doit pas retenir
        // une connexion DB pendant le round-trip), puis persistance dans une
        // transaction courte portee par CvVariantService.persistVariant (M-4).
        EnhanceCvResponse adapted = variantService.adaptToJob(parentCvId, userId, jobDescription);
        return variantService.persistVariant(parentCvId, jobDescription, label, userId, adapted);
    }

    @Override
    @Transactional(readOnly = true)
    public List<CvResponse> getVariantsByParentId(Long parentCvId, Long userId) {
        return variantService.getVariantsByParentId(parentCvId, userId);
    }

    // ── Partage (delegue) ─────────────────────────────────────────

    @Override
    @Transactional
    public CvResponse generateShareToken(Long cvId, Long userId) {
        return shareService.generateShareToken(cvId, userId);
    }

    @Override
    @Transactional
    public CvResponse regenerateShareToken(Long cvId, Long userId) {
        return shareService.regenerateShareToken(cvId, userId);
    }

    @Override
    @Transactional
    public CvResponse deactivateShare(Long cvId, Long userId) {
        return shareService.deactivateShare(cvId, userId);
    }

    @Override
    @Transactional
    public CvResponse updateShareSettings(
            Long cvId, PublicShareSettingsRequest request, Long userId) {
        return shareService.updateShareSettings(cvId, request, userId);
    }

    // ── Helpers CRUD ──────────────────────────────────────────────

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

    private void applyStyle(Cv cv, CvRequest.StyleDto style) {
        if (style == null) {
            return;
        }
        if (style.getTemplateId() != null) {
            cv.setStyleTemplateId(style.getTemplateId());
        }
        if (style.getPrimaryColor() != null) {
            cv.setStylePrimaryColor(style.getPrimaryColor());
        }
        if (style.getFontFamily() != null) {
            cv.setStyleFontFamily(style.getFontFamily());
        }
    }

    private String resolveTemplateTag(CvRequest request) {
        if (request == null || request.getStyle() == null || request.getStyle().getTemplateId() == null) {
            return "default";
        }
        return request.getStyle().getTemplateId();
    }
}
