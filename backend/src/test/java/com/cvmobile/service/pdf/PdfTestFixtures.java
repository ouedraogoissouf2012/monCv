package com.cvmobile.service.pdf;

import com.cvmobile.dto.CvResponse;
import com.cvmobile.model.Language;

import java.time.LocalDate;
import java.util.List;

public final class PdfTestFixtures {

    private PdfTestFixtures() {
    }

    public static CvResponse completeCv() {
        return CvResponse.builder()
                .titre("Product Manager")
                .personalInfo(CvResponse.PersonalInfoDto.builder()
                        .prenom("Awa").nom("Kone").titrePoste("Product Manager")
                        .email("awa@example.com").telephone("+225 01 02 03 04")
                        .ville("Abidjan").pays("Côte d'Ivoire")
                        .resumeProfessionnel("Pilote des produits numériques utiles et mesurables.")
                        .build())
                .experiences(List.of(CvResponse.ExperienceDto.builder()
                        .poste("Product Manager Senior").entreprise("Fintech Africa")
                        .lieu("Abidjan").dateDebut(LocalDate.of(2023, 1, 1)).actuel(true)
                        .description("Pilotage de la feuille de route produit.").build()))
                .educations(List.of(CvResponse.EducationDto.builder()
                        .diplome("Master Management").etablissement("Université de Dakar")
                        .domaine("Innovation").dateDebut(LocalDate.of(2018, 9, 1))
                        .dateFin(LocalDate.of(2020, 6, 1)).build()))
                .skills(List.of(CvResponse.SkillDto.builder()
                        .nom("Stratégie produit").niveau(5).categorie("Produit").build()))
                .languages(List.of(CvResponse.LanguageDto.builder()
                        .langue("Français").niveau(Language.NiveauLangue.NATIF).build()))
                .certifications(List.of(CvResponse.CertificationDto.builder()
                        .nom("Professional Scrum Product Owner I").organisme("Scrum.org")
                        .dateObtention(LocalDate.of(2022, 6, 15)).build()))
                .projects(List.of(CvResponse.ProjectDto.builder()
                        .nom("Optimisation du paiement marchand")
                        .description("Amélioration du taux de réussite des transactions.")
                        .technologies("SQL, Metabase").build()))
                .build();
    }
}
