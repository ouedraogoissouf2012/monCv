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

import static com.cvmobile.dto.CvValidationLimits.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CvRequest {

    @NotBlank(message = "Le titre du CV est obligatoire")
    @Size(max = MAX_MEDIUM_TEXT_LENGTH, message = "Le titre ne doit pas depasser 200 caracteres")
    private String titre;

    @Valid
    private PersonalInfoDto personalInfo;

    @Size(max = MAX_SECTION_ITEMS, message = "Le nombre de formations ne doit pas depasser 50")
    private List<@NotNull @Valid EducationDto> educations;

    @Size(max = MAX_SECTION_ITEMS, message = "Le nombre d'experiences ne doit pas depasser 50")
    private List<@NotNull @Valid ExperienceDto> experiences;

    @Size(max = MAX_SKILLS, message = "Le nombre de competences ne doit pas depasser 100")
    private List<@NotNull @Valid SkillDto> skills;

    @Size(max = MAX_SECTION_ITEMS, message = "Le nombre de langues ne doit pas depasser 50")
    private List<@NotNull @Valid LanguageDto> languages;

    @Size(max = MAX_SECTION_ITEMS, message = "Le nombre de certifications ne doit pas depasser 50")
    private List<@NotNull @Valid CertificationDto> certifications;

    @Size(max = MAX_SECTION_ITEMS, message = "Le nombre de projets ne doit pas depasser 50")
    private List<@NotNull @Valid ProjectDto> projects;

    @Valid
    private StyleDto style;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class StyleDto {
        @Size(max = MAX_TEMPLATE_LENGTH, message = "Le template ne doit pas depasser 50 caracteres")
        private String templateId;

        @Min(value = 0, message = "La couleur doit etre un entier ARGB positif")
        @Max(value = 4294967295L, message = "La couleur doit etre un entier ARGB valide")
        private Long primaryColor;

        @Size(max = MAX_SHORT_TEXT_LENGTH, message = "La police ne doit pas depasser 100 caracteres")
        private String fontFamily;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PersonalInfoDto {
        @Size(max = MAX_SHORT_TEXT_LENGTH, message = "Le nom ne doit pas depasser 100 caracteres")
        private String nom;

        @Size(max = MAX_SHORT_TEXT_LENGTH, message = "Le prenom ne doit pas depasser 100 caracteres")
        private String prenom;

        @Email(message = "Format d'email invalide")
        @Size(max = MAX_EMAIL_LENGTH, message = "L'email ne doit pas depasser 254 caracteres")
        private String email;

        @Size(max = MAX_PHONE_LENGTH, message = "Le telephone ne doit pas depasser 20 caracteres")
        private String telephone;

        @Size(max = MAX_MEDIUM_TEXT_LENGTH, message = "L'adresse ne doit pas depasser 200 caracteres")
        private String adresse;
        @Size(max = MAX_SHORT_TEXT_LENGTH, message = "La ville ne doit pas depasser 100 caracteres")
        private String ville;
        @Size(max = MAX_POSTAL_CODE_LENGTH, message = "Le code postal ne doit pas depasser 32 caracteres")
        private String codePostal;
        @Size(max = MAX_SHORT_TEXT_LENGTH, message = "Le pays ne doit pas depasser 100 caracteres")
        private String pays;
        @Size(max = MAX_URL_LENGTH, message = "L'URL de photo ne doit pas depasser 500 caracteres")
        private String photoUrl;

        @Size(max = MAX_URL_LENGTH, message = "L'URL LinkedIn ne doit pas depasser 500 caracteres")
        private String linkedIn;

        @Size(max = MAX_URL_LENGTH, message = "L'URL portfolio ne doit pas depasser 500 caracteres")
        private String portfolio;

        @Size(max = MAX_MEDIUM_TEXT_LENGTH, message = "Le titre de poste ne doit pas depasser 200 caracteres")
        private String titrePoste;

        @Size(max = MAX_LONG_TEXT_LENGTH, message = "Le resume ne doit pas depasser 10000 caracteres")
        private String resumeProfessionnel;

        @Min(value = 1920, message = "Annee de naissance invalide")
        @Max(value = 2015, message = "Annee de naissance invalide")
        private Integer anneeNaissance;

        @Size(max = 40, message = "Situation matrimoniale trop longue")
        private String situationMatrimoniale;

        @Size(max = 20, message = "Sexe trop long")
        private String sexe;

        private Boolean afficherInfosSensibles;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EducationDto {
        private Long id;

        @NotBlank(message = "L'etablissement est obligatoire")
        @Size(max = MAX_MEDIUM_TEXT_LENGTH, message = "L'etablissement ne doit pas depasser 200 caracteres")
        private String etablissement;

        @NotBlank(message = "Le diplome est obligatoire")
        @Size(max = MAX_MEDIUM_TEXT_LENGTH, message = "Le diplome ne doit pas depasser 200 caracteres")
        private String diplome;

        @Size(max = MAX_MEDIUM_TEXT_LENGTH, message = "Le domaine ne doit pas depasser 200 caracteres")
        private String domaine;

        @NotNull(message = "La date de debut est obligatoire")
        private LocalDate dateDebut;

        private LocalDate dateFin;
        @Size(max = MAX_LONG_TEXT_LENGTH, message = "La description ne doit pas depasser 10000 caracteres")
        private String description;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExperienceDto {
        private Long id;

        @NotBlank(message = "L'entreprise est obligatoire")
        @Size(max = MAX_MEDIUM_TEXT_LENGTH, message = "L'entreprise ne doit pas depasser 200 caracteres")
        private String entreprise;

        @NotBlank(message = "Le poste est obligatoire")
        @Size(max = MAX_MEDIUM_TEXT_LENGTH, message = "Le poste ne doit pas depasser 200 caracteres")
        private String poste;

        @Size(max = MAX_MEDIUM_TEXT_LENGTH, message = "Le lieu ne doit pas depasser 200 caracteres")
        private String lieu;

        @NotNull(message = "La date de debut est obligatoire")
        private LocalDate dateDebut;

        private LocalDate dateFin;
        @Size(max = MAX_LONG_TEXT_LENGTH, message = "La description ne doit pas depasser 10000 caracteres")
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
        @Size(max = MAX_SHORT_TEXT_LENGTH, message = "Le nom ne doit pas depasser 100 caracteres")
        private String nom;

        @Min(value = 1, message = "Le niveau minimum est 1")
        @Max(value = 5, message = "Le niveau maximum est 5")
        private Integer niveau;

        @Size(max = MAX_SHORT_TEXT_LENGTH, message = "La categorie ne doit pas depasser 100 caracteres")
        private String categorie;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LanguageDto {
        private Long id;

        @NotBlank(message = "La langue est obligatoire")
        @Size(max = MAX_SHORT_TEXT_LENGTH, message = "La langue ne doit pas depasser 100 caracteres")
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
        @Size(max = MAX_MEDIUM_TEXT_LENGTH, message = "Le nom ne doit pas depasser 200 caracteres")
        private String nom;

        @Size(max = MAX_MEDIUM_TEXT_LENGTH, message = "L'organisme ne doit pas depasser 200 caracteres")
        private String organisme;
        private LocalDate dateObtention;
        private LocalDate dateExpiration;

        @Size(max = MAX_URL_LENGTH, message = "L'URL credential ne doit pas depasser 500 caracteres")
        private String credentialUrl;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ProjectDto {
        private Long id;

        @NotBlank(message = "Le nom du projet est obligatoire")
        @Size(max = MAX_MEDIUM_TEXT_LENGTH, message = "Le nom ne doit pas depasser 200 caracteres")
        private String nom;

        @Size(max = MAX_LONG_TEXT_LENGTH, message = "La description ne doit pas depasser 10000 caracteres")
        private String description;

        @Size(max = MAX_URL_LENGTH, message = "Les technologies ne doivent pas depasser 500 caracteres")
        private String technologies;

        @Size(max = MAX_URL_LENGTH, message = "Le lien ne doit pas depasser 500 caracteres")
        private String lien;

        private LocalDate dateDebut;
        private LocalDate dateFin;
    }
}
