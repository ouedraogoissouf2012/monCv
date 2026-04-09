package com.cvmobile.dto;

import com.cvmobile.model.Language;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

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
    private int viewCount;
    private String publicToken;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

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
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LanguageDto {
        private Long id;
        private String langue;
        private Language.NiveauLangue niveau;
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
    }
}
