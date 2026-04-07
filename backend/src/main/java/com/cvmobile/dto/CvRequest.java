package com.cvmobile.dto;

import com.cvmobile.model.Language;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CvRequest {

    @NotBlank(message = "Le titre du CV est obligatoire")
    @Size(max = 200, message = "Le titre ne doit pas depasser 200 caracteres")
    private String titre;

    @Valid
    private PersonalInfoDto personalInfo;

    @Valid
    private List<EducationDto> educations;

    @Valid
    private List<ExperienceDto> experiences;

    @Valid
    private List<SkillDto> skills;

    @Valid
    private List<LanguageDto> languages;

    @Valid
    private List<CertificationDto> certifications;

    @Valid
    private List<ProjectDto> projects;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PersonalInfoDto {
        @Size(max = 100, message = "Le nom ne doit pas depasser 100 caracteres")
        private String nom;

        @Size(max = 100, message = "Le prenom ne doit pas depasser 100 caracteres")
        private String prenom;

        @Email(message = "Format d'email invalide")
        private String email;

        @Size(max = 20, message = "Le telephone ne doit pas depasser 20 caracteres")
        private String telephone;

        private String adresse;
        private String ville;
        private String codePostal;
        private String pays;
        private String photoUrl;

        @Size(max = 500, message = "L'URL LinkedIn ne doit pas depasser 500 caracteres")
        private String linkedIn;

        @Size(max = 500, message = "L'URL portfolio ne doit pas depasser 500 caracteres")
        private String portfolio;

        @Size(max = 500, message = "Le titre de poste ne doit pas depasser 500 caracteres")
        private String titrePoste;

        private String resumeProfessionnel;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EducationDto {
        private Long id;

        @NotBlank(message = "L'etablissement est obligatoire")
        @Size(max = 200, message = "L'etablissement ne doit pas depasser 200 caracteres")
        private String etablissement;

        @NotBlank(message = "Le diplome est obligatoire")
        @Size(max = 200, message = "Le diplome ne doit pas depasser 200 caracteres")
        private String diplome;

        private String domaine;

        @NotNull(message = "La date de debut est obligatoire")
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

        @NotBlank(message = "L'entreprise est obligatoire")
        @Size(max = 200, message = "L'entreprise ne doit pas depasser 200 caracteres")
        private String entreprise;

        @NotBlank(message = "Le poste est obligatoire")
        @Size(max = 200, message = "Le poste ne doit pas depasser 200 caracteres")
        private String poste;

        private String lieu;

        @NotNull(message = "La date de debut est obligatoire")
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

        @NotBlank(message = "Le nom de la competence est obligatoire")
        @Size(max = 100, message = "Le nom ne doit pas depasser 100 caracteres")
        private String nom;

        @Min(value = 1, message = "Le niveau minimum est 1")
        @Max(value = 5, message = "Le niveau maximum est 5")
        private Integer niveau;

        private String categorie;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LanguageDto {
        private Long id;

        @NotBlank(message = "La langue est obligatoire")
        private String langue;

        @NotNull(message = "Le niveau est obligatoire")
        private Language.NiveauLangue niveau;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CertificationDto {
        private Long id;

        @NotBlank(message = "Le nom de la certification est obligatoire")
        @Size(max = 200, message = "Le nom ne doit pas depasser 200 caracteres")
        private String nom;

        private String organisme;
        private LocalDate dateObtention;
        private LocalDate dateExpiration;

        @Size(max = 500, message = "L'URL credential ne doit pas depasser 500 caracteres")
        private String credentialUrl;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ProjectDto {
        private Long id;

        @NotBlank(message = "Le nom du projet est obligatoire")
        @Size(max = 200, message = "Le nom ne doit pas depasser 200 caracteres")
        private String nom;

        private String description;

        @Size(max = 500, message = "Les technologies ne doivent pas depasser 500 caracteres")
        private String technologies;

        @Size(max = 500, message = "Le lien ne doit pas depasser 500 caracteres")
        private String lien;

        private LocalDate dateDebut;
        private LocalDate dateFin;
    }
}
