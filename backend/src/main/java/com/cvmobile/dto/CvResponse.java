package com.cvmobile.dto;

import com.cvmobile.model.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CvResponse {

    private Long id;
    private String titre;
    private PersonalInfoDto personalInfo;
    private List<EducationDto> educations;
    private List<ExperienceDto> experiences;
    private List<SkillDto> skills;
    private List<LanguageDto> languages;
    private List<CertificationDto> certifications;
    private List<ProjectDto> projects;
    private String publicToken;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static CvResponse fromEntity(Cv cv) {
        return CvResponse.builder()
                .id(cv.getId())
                .titre(cv.getTitre())
                .personalInfo(PersonalInfoDto.fromEntity(cv.getPersonalInfo()))
                .educations(cv.getEducations().stream()
                        .map(EducationDto::fromEntity)
                        .collect(Collectors.toList()))
                .experiences(cv.getExperiences().stream()
                        .map(ExperienceDto::fromEntity)
                        .collect(Collectors.toList()))
                .skills(cv.getSkills().stream()
                        .map(SkillDto::fromEntity)
                        .collect(Collectors.toList()))
                .languages(cv.getLanguages().stream()
                        .map(LanguageDto::fromEntity)
                        .collect(Collectors.toList()))
                .certifications(cv.getCertifications().stream()
                        .map(CertificationDto::fromEntity)
                        .collect(Collectors.toList()))
                .projects(cv.getProjects().stream()
                        .map(ProjectDto::fromEntity)
                        .collect(Collectors.toList()))
                .publicToken(cv.getPublicToken())
                .createdAt(cv.getCreatedAt())
                .updatedAt(cv.getUpdatedAt())
                .build();
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PersonalInfoDto {
        private String nom;
        private String prenom;
        private String email;
        private String telephone;
        private String adresse;
        private String ville;
        private String codePostal;
        private String pays;
        private String photoUrl;
        private String linkedIn;
        private String portfolio;
        private String titrePoste;
        private String resumeProfessionnel;

        public static PersonalInfoDto fromEntity(PersonalInfo info) {
            if (info == null) return null;
            return PersonalInfoDto.builder()
                    .nom(info.getNom())
                    .prenom(info.getPrenom())
                    .email(info.getEmail())
                    .telephone(info.getTelephone())
                    .adresse(info.getAdresse())
                    .ville(info.getVille())
                    .codePostal(info.getCodePostal())
                    .pays(info.getPays())
                    .photoUrl(info.getPhotoUrl())
                    .linkedIn(info.getLinkedIn())
                    .portfolio(info.getPortfolio())
                    .titrePoste(info.getTitrePoste())
                    .resumeProfessionnel(info.getResumeProfessionnel())
                    .build();
        }
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EducationDto {
        private Long id;
        private String etablissement;
        private String diplome;
        private String domaine;
        private LocalDate dateDebut;
        private LocalDate dateFin;
        private String description;

        public static EducationDto fromEntity(Education education) {
            return EducationDto.builder()
                    .id(education.getId())
                    .etablissement(education.getEtablissement())
                    .diplome(education.getDiplome())
                    .domaine(education.getDomaine())
                    .dateDebut(education.getDateDebut())
                    .dateFin(education.getDateFin())
                    .description(education.getDescription())
                    .build();
        }
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExperienceDto {
        private Long id;
        private String entreprise;
        private String poste;
        private String lieu;
        private LocalDate dateDebut;
        private LocalDate dateFin;
        private String description;
        private Boolean actuel;

        public static ExperienceDto fromEntity(Experience experience) {
            return ExperienceDto.builder()
                    .id(experience.getId())
                    .entreprise(experience.getEntreprise())
                    .poste(experience.getPoste())
                    .lieu(experience.getLieu())
                    .dateDebut(experience.getDateDebut())
                    .dateFin(experience.getDateFin())
                    .description(experience.getDescription())
                    .actuel(experience.getActuel())
                    .build();
        }
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SkillDto {
        private Long id;
        private String nom;
        private Integer niveau;
        private String categorie;

        public static SkillDto fromEntity(Skill skill) {
            return SkillDto.builder()
                    .id(skill.getId())
                    .nom(skill.getNom())
                    .niveau(skill.getNiveau())
                    .categorie(skill.getCategorie())
                    .build();
        }
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LanguageDto {
        private Long id;
        private String langue;
        private Language.NiveauLangue niveau;

        public static LanguageDto fromEntity(com.cvmobile.model.Language language) {
            return LanguageDto.builder()
                    .id(language.getId())
                    .langue(language.getLangue())
                    .niveau(language.getNiveau())
                    .build();
        }
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CertificationDto {
        private Long id;
        private String nom;
        private String organisme;
        private LocalDate dateObtention;
        private LocalDate dateExpiration;
        private String credentialUrl;

        public static CertificationDto fromEntity(com.cvmobile.model.Certification c) {
            return CertificationDto.builder()
                    .id(c.getId())
                    .nom(c.getNom())
                    .organisme(c.getOrganisme())
                    .dateObtention(c.getDateObtention())
                    .dateExpiration(c.getDateExpiration())
                    .credentialUrl(c.getCredentialUrl())
                    .build();
        }
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ProjectDto {
        private Long id;
        private String nom;
        private String description;
        private String technologies;
        private String lien;
        private LocalDate dateDebut;
        private LocalDate dateFin;

        public static ProjectDto fromEntity(com.cvmobile.model.Project p) {
            return ProjectDto.builder()
                    .id(p.getId())
                    .nom(p.getNom())
                    .description(p.getDescription())
                    .technologies(p.getTechnologies())
                    .lien(p.getLien())
                    .dateDebut(p.getDateDebut())
                    .dateFin(p.getDateFin())
                    .build();
        }
    }
}
