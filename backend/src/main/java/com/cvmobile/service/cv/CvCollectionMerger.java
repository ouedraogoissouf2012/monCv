package com.cvmobile.service.cv;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.mapper.CvMapper;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Certification;
import com.cvmobile.model.Education;
import com.cvmobile.model.Experience;
import com.cvmobile.model.Language;
import com.cvmobile.model.Project;
import com.cvmobile.model.Skill;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.function.BiConsumer;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Fusion « intelligente » des collections d'un CV lors d'une mise a jour
 * (issue #254). Extrait de {@code CvService}, ou six methodes quasi-identiques
 * etaient dupliquees.
 *
 * Regle, appliquee identiquement a chaque collection :
 * <ul>
 *   <li>element de la requete avec un ID connu -&gt; mise a jour en place ;</li>
 *   <li>element sans ID -&gt; insertion ;</li>
 *   <li>element existant absent de la requete -&gt; suppression ;</li>
 *   <li>liste nulle -&gt; collection videe.</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
public class CvCollectionMerger {

    private final CvMapper cvMapper;

    /**
     * Applique la fusion a toutes les collections du CV a partir de la requete.
     */
    public void mergeCollections(Cv cv, CvRequest request) {
        merge(cv.getExperiences(), request.getExperiences(),
                Experience::getId, CvRequest.ExperienceDto::getId,
                cvMapper::updateExperience, cvMapper::toExperience, cv::addExperience);
        merge(cv.getEducations(), request.getEducations(),
                Education::getId, CvRequest.EducationDto::getId,
                cvMapper::updateEducation, cvMapper::toEducation, cv::addEducation);
        merge(cv.getSkills(), request.getSkills(),
                Skill::getId, CvRequest.SkillDto::getId,
                cvMapper::updateSkill, cvMapper::toSkill, cv::addSkill);
        merge(cv.getLanguages(), request.getLanguages(),
                Language::getId, CvRequest.LanguageDto::getId,
                cvMapper::updateLanguage, cvMapper::toLanguage, cv::addLanguage);
        merge(cv.getCertifications(), request.getCertifications(),
                Certification::getId, CvRequest.CertificationDto::getId,
                cvMapper::updateCertification, cvMapper::toCertification, cv::addCertification);
        merge(cv.getProjects(), request.getProjects(),
                Project::getId, CvRequest.ProjectDto::getId,
                cvMapper::updateProject, cvMapper::toProject, cv::addProject);
    }

    /**
     * Fusion generique d'une collection d'entites avec une liste de DTOs.
     *
     * @param existing   collection vivante de l'entite (modifiee en place)
     * @param dtos       DTOs de la requete ({@code null} = tout supprimer)
     * @param entityId   accesseur d'ID de l'entite
     * @param dtoId      accesseur d'ID du DTO
     * @param update     applique un DTO sur une entite existante (en place)
     * @param toEntity   cree une entite a partir d'un DTO
     * @param add        rattache une nouvelle entite au CV (positionne le parent)
     */
    private <E, D> void merge(
            List<E> existing,
            List<D> dtos,
            Function<E, Long> entityId,
            Function<D, Long> dtoId,
            BiConsumer<D, E> update,
            Function<D, E> toEntity,
            Consumer<E> add) {
        if (dtos == null) {
            existing.clear();
            return;
        }

        var existingById = existing.stream()
                .filter(e -> entityId.apply(e) != null)
                .collect(Collectors.toMap(entityId, e -> e));
        Set<Long> newIds = dtos.stream()
                .map(dtoId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        existing.removeIf(e -> entityId.apply(e) != null && !newIds.contains(entityId.apply(e)));

        for (D dto : dtos) {
            Long id = dtoId.apply(dto);
            if (id != null && existingById.containsKey(id)) {
                update.accept(dto, existingById.get(id));
            } else {
                add.accept(toEntity.apply(dto));
            }
        }
    }
}
