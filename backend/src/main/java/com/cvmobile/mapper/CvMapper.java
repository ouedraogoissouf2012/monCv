package com.cvmobile.mapper;

import com.cvmobile.dto.CvRequest;
import com.cvmobile.dto.CvResponse;
import com.cvmobile.model.*;
import org.mapstruct.*;

import java.util.List;

/**
 * MapStruct mapper pour les conversions CV.
 * Genere a la compilation le code de mapping DTO <-> Entity.
 *
 * Couvre :
 * - Cv -> CvResponse (lecture)
 * - CvRequest.XxxDto -> Entity (creation)
 * - Entity -> Entity (duplication, ignore id + cv)
 * - CvRequest.XxxDto -> Entity existant (update in-place pour smart merge)
 */
@Mapper(componentModel = "spring",
        nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
public interface CvMapper {

    // ── Entity -> Response DTO ───────────────────────────────────

    @Mapping(target = "parentCvId", source = "parent.id")
    @Mapping(target = "variantCount", ignore = true)
    CvResponse toResponse(Cv cv);

    CvResponse.PersonalInfoDto toPersonalInfoDto(PersonalInfo info);

    CvResponse.EducationDto toEducationDto(Education education);

    CvResponse.ExperienceDto toExperienceDto(Experience experience);

    CvResponse.SkillDto toSkillDto(Skill skill);

    CvResponse.LanguageDto toLanguageDto(Language language);

    CvResponse.CertificationDto toCertificationDto(Certification certification);

    CvResponse.ProjectDto toProjectDto(Project project);

    List<CvResponse.EducationDto> toEducationDtoList(List<Education> educations);
    List<CvResponse.ExperienceDto> toExperienceDtoList(List<Experience> experiences);
    List<CvResponse.SkillDto> toSkillDtoList(List<Skill> skills);
    List<CvResponse.LanguageDto> toLanguageDtoList(List<Language> languages);
    List<CvResponse.CertificationDto> toCertificationDtoList(List<Certification> certifications);
    List<CvResponse.ProjectDto> toProjectDtoList(List<Project> projects);

    // ── Request DTO -> Entity (creation) ─────────────────────────

    PersonalInfo toPersonalInfo(CvRequest.PersonalInfoDto dto);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    Education toEducation(CvRequest.EducationDto dto);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    @Mapping(target = "actuel", defaultValue = "false")
    Experience toExperience(CvRequest.ExperienceDto dto);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    Skill toSkill(CvRequest.SkillDto dto);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    Language toLanguage(CvRequest.LanguageDto dto);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    Certification toCertification(CvRequest.CertificationDto dto);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    Project toProject(CvRequest.ProjectDto dto);

    // ── Request DTO -> Entity existant (update in-place) ─────────

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    @Mapping(target = "actuel", defaultValue = "false")
    void updateExperience(CvRequest.ExperienceDto dto, @MappingTarget Experience experience);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    void updateEducation(CvRequest.EducationDto dto, @MappingTarget Education education);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    void updateSkill(CvRequest.SkillDto dto, @MappingTarget Skill skill);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    void updateLanguage(CvRequest.LanguageDto dto, @MappingTarget Language language);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    void updateCertification(CvRequest.CertificationDto dto, @MappingTarget Certification certification);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    void updateProject(CvRequest.ProjectDto dto, @MappingTarget Project project);

    // ── Entity -> Entity (duplication deep copy, sans id ni cv) ──

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    Education cloneEducation(Education source);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    Experience cloneExperience(Experience source);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    Skill cloneSkill(Skill source);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    Language cloneLanguage(Language source);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    Certification cloneCertification(Certification source);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "cv", ignore = true)
    Project cloneProject(Project source);

    PersonalInfo clonePersonalInfo(PersonalInfo source);
}
