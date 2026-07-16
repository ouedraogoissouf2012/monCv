package com.cvmobile.dto;

import com.cvmobile.model.Language;

import java.time.LocalDate;
import java.util.List;

public record PublicCvResponse(
        String titre,
        PersonalInfo personalInfo,
        List<Education> educations,
        List<Experience> experiences,
        List<Skill> skills,
        List<SpokenLanguage> languages,
        List<Certification> certifications,
        List<Project> projects,
        Style style,
        boolean publicDownloadsEnabled,
        boolean publicContactEnabled
) {
    public record Style(
            String templateId,
            Long primaryColor,
            String fontFamily
    ) {
    }

    public record PersonalInfo(
            String nom,
            String prenom,
            String email,
            String telephone,
            String ville,
            String pays,
            String photoUrl,
            String linkedIn,
            String portfolio,
            String titrePoste,
            String resumeProfessionnel
    ) {
    }

    public record Education(
            String etablissement,
            String diplome,
            String domaine,
            LocalDate dateDebut,
            LocalDate dateFin,
            String description
    ) {
    }

    public record Experience(
            String entreprise,
            String poste,
            String lieu,
            LocalDate dateDebut,
            LocalDate dateFin,
            String description,
            Boolean actuel
    ) {
    }

    public record Skill(
            String nom,
            Integer niveau,
            String categorie
    ) {
    }

    public record SpokenLanguage(
            String langue,
            Language.NiveauLangue niveau
    ) {
    }

    public record Certification(
            String nom,
            String organisme,
            LocalDate dateObtention,
            LocalDate dateExpiration,
            String credentialUrl
    ) {
    }

    public record Project(
            String nom,
            String description,
            String technologies,
            String lien,
            LocalDate dateDebut,
            LocalDate dateFin
    ) {
    }
}
