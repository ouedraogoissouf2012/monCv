package com.cvmobile.service.cv;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.dto.EnhanceCvResponse;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Education;
import com.cvmobile.model.Experience;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.Project;
import com.cvmobile.model.Skill;
import com.cvmobile.model.User;
import com.cvmobile.repository.CvRepository;
import com.cvmobile.service.ai.IEnhancementService;
import com.cvmobile.service.user.IUserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Creation de variantes de CV adaptees a une offre d'emploi via l'IA
 * (issue #254). Extrait de {@code CvService}. S'execute dans la transaction de
 * la facade appelante.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CvVariantService {

    private static final int MAX_VARIANT_LABEL_LENGTH = 200;
    private static final int MAX_FALLBACK_LABEL_LENGTH = 60;
    private static final int MAX_ADAPTED_SKILLS = 10;

    private final CvRepository cvRepository;
    private final IUserService userService;
    private final CvMapper cvMapper;
    private final IEnhancementService enhancementService;
    private final CvFinder cvFinder;

    public CvResponse createVariant(Long parentCvId, String jobDescription, String label, Long userId) {
        Cv original = cvFinder.findByIdAndUserId(parentCvId, userId);
        User user = userService.findById(userId);

        // 1. L'IA adapte le contenu du CV a l'offre
        EnhanceCvResponse adapted = enhancementService.adaptCvToJob(parentCvId, userId, jobDescription);

        // 2. Determiner le label de la variante
        String resolvedLabel = resolveVariantLabel(label, adapted, jobDescription);

        // 3. Creer la copie avec lien parent
        Cv variant = Cv.builder()
                .titre(original.getTitre() + " — " + resolvedLabel)
                .user(user)
                .parent(original)
                .varianteLabel(resolvedLabel)
                .build();

        // 4. Copier le personalInfo avec les adaptations IA
        if (original.getPersonalInfo() != null) {
            PersonalInfo info = cvMapper.clonePersonalInfo(original.getPersonalInfo());
            if (adapted.getTitrePoste() != null && !adapted.getTitrePoste().isBlank()) {
                info.setTitrePoste(adapted.getTitrePoste());
            }
            if (adapted.getResumeProfessionnel() != null && !adapted.getResumeProfessionnel().isBlank()) {
                info.setResumeProfessionnel(adapted.getResumeProfessionnel());
            }
            variant.setPersonalInfo(info);
        }

        Cv savedVariant = cvRepository.save(variant);

        // 5-6. Copier experiences et educations avec descriptions adaptees
        applyAdaptedExperiences(original, adapted, savedVariant);
        applyAdaptedEducations(original, adapted, savedVariant);

        // 7. Competences : remplacer si l'IA en propose, sinon copier
        if (adapted.getSkills() != null && !adapted.getSkills().isEmpty()) {
            adapted.getSkills().stream().limit(MAX_ADAPTED_SKILLS).forEach(s ->
                savedVariant.addSkill(Skill.builder()
                        .nom(s.getNom())
                        .niveau(s.getNiveau() != null ? s.getNiveau() : 3)
                        .build()));
        } else {
            original.getSkills().forEach(s -> savedVariant.addSkill(cvMapper.cloneSkill(s)));
        }

        // 8. Copier langues et certifications telles quelles
        original.getLanguages().forEach(l -> savedVariant.addLanguage(cvMapper.cloneLanguage(l)));
        original.getCertifications().forEach(c -> savedVariant.addCertification(cvMapper.cloneCertification(c)));

        // 9. Copier les projets avec descriptions adaptees
        applyAdaptedProjects(original, adapted, savedVariant);

        Cv saved = cvRepository.save(savedVariant);
        log.info("Variante CV creee: parent={}, variante={}, label='{}', userId={}",
                parentCvId, saved.getId(), resolvedLabel, userId);
        return cvMapper.toResponse(saved);
    }

    public List<CvResponse> getVariantsByParentId(Long parentCvId, Long userId) {
        return cvRepository.findByParentIdAndUserId(parentCvId, userId).stream()
                .map(cvMapper::toResponse)
                .collect(Collectors.toList());
    }

    private String resolveVariantLabel(String userLabel, EnhanceCvResponse adapted, String jobDescription) {
        // Priorite : label fourni par l'utilisateur > titre extrait par l'IA > premiere ligne de l'offre
        if (userLabel != null && !userLabel.isBlank()) {
            return truncate(userLabel, MAX_VARIANT_LABEL_LENGTH);
        }
        if (adapted.getTitreOffre() != null && !adapted.getTitreOffre().isBlank()) {
            return truncate(adapted.getTitreOffre(), MAX_VARIANT_LABEL_LENGTH);
        }
        // Fallback : premiere ligne non vide de l'offre
        String firstLine = jobDescription.lines()
                .map(String::strip)
                .filter(l -> !l.isBlank())
                .findFirst()
                .orElse("Variante");
        return firstLine.length() > MAX_FALLBACK_LABEL_LENGTH
                ? firstLine.substring(0, MAX_FALLBACK_LABEL_LENGTH) + "..."
                : firstLine;
    }

    private String truncate(String value, int maxLength) {
        return value.length() > maxLength ? value.substring(0, maxLength) : value;
    }

    private void applyAdaptedExperiences(Cv original, EnhanceCvResponse adapted, Cv variant) {
        var adaptedExps = adapted.getExperiences() != null
                ? adapted.getExperiences() : List.<EnhanceCvResponse.ExperienceEnhancement>of();
        for (int i = 0; i < original.getExperiences().size(); i++) {
            Experience clone = cvMapper.cloneExperience(original.getExperiences().get(i));
            if (i < adaptedExps.size()) {
                String desc = adaptedExps.get(i).getDescription();
                if (desc != null && !desc.isBlank()) clone.setDescription(desc);
            }
            variant.addExperience(clone);
        }
    }

    private void applyAdaptedEducations(Cv original, EnhanceCvResponse adapted, Cv variant) {
        var adaptedEdus = adapted.getEducations() != null
                ? adapted.getEducations() : List.<EnhanceCvResponse.EducationEnhancement>of();
        for (int i = 0; i < original.getEducations().size(); i++) {
            Education clone = cvMapper.cloneEducation(original.getEducations().get(i));
            if (i < adaptedEdus.size()) {
                String desc = adaptedEdus.get(i).getDescription();
                if (desc != null && !desc.isBlank()) clone.setDescription(desc);
            }
            variant.addEducation(clone);
        }
    }

    private void applyAdaptedProjects(Cv original, EnhanceCvResponse adapted, Cv variant) {
        var adaptedProjs = adapted.getProjects() != null
                ? adapted.getProjects() : List.<EnhanceCvResponse.ProjectEnhancement>of();
        for (int i = 0; i < original.getProjects().size(); i++) {
            Project clone = cvMapper.cloneProject(original.getProjects().get(i));
            if (i < adaptedProjs.size()) {
                String desc = adaptedProjs.get(i).getDescription();
                if (desc != null && !desc.isBlank()) clone.setDescription(desc);
            }
            variant.addProject(clone);
        }
    }
}
