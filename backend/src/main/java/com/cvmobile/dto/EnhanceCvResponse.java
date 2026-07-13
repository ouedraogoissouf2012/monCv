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
    private List<LanguageEnhancement> languages;
    private List<CertificationEnhancement> certifications;
    private List<ProjectEnhancement> projects;
    private List<String> warnings;
    private int correctionCount;
    private boolean aiGenerated;
    private boolean fallback;
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
        private String etablissement;
        private String diplome;
        private String domaine;
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
    public static class LanguageEnhancement {
        private Long id;
        private String langue;
    }

    @Data
    @Builder
    public static class CertificationEnhancement {
        private Long id;
        private String nom;
        private String organisme;
    }

    @Data
    @Builder
    public static class ProjectEnhancement {
        private Long id;
        private String nom;
        private String description;
        private String technologies;
    }
}
