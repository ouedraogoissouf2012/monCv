package com.cvmobile.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class EnhanceCvResponse {

    private String titrePoste;
    private String resumeProfessionnel;
    private String titreOffre;
    private List<ExperienceEnhancement> experiences;
    private List<EducationEnhancement> educations;
    private List<SkillEnhancement> skills;
    private List<ProjectEnhancement> projects;
    private boolean aiGenerated;
    private String level;

    @Data
    @Builder
    public static class ExperienceEnhancement {
        private Long id;
        private String poste;
        private String description;
    }

    @Data
    @Builder
    public static class EducationEnhancement {
        private Long id;
        private String description;
    }

    @Data
    @Builder
    public static class SkillEnhancement {
        private String nom;
        private Integer niveau;
    }

    @Data
    @Builder
    public static class ProjectEnhancement {
        private Long id;
        private String description;
    }
}
