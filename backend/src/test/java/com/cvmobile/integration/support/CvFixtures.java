package com.cvmobile.integration.support;

import java.util.List;
import java.util.Map;

/**
 * Payloads JSON reutilisables pour les tests d'integration CV (#234).
 *
 * <p>Regroupe les corps de requete auparavant dupliques dans le flow
 * monolithique. Aucune assertion : uniquement des donnees de fixture.
 */
public final class CvFixtures {

    private CvFixtures() {
    }

    /** Couleur primaire "moderne" (bleu) utilisee a la creation. */
    public static final long COLOR_MODERNE = 0xFF2563EBL;

    /** Couleur primaire "classique" (vert) utilisee a la mise a jour. */
    public static final long COLOR_CLASSIQUE = 0xFF10B981L;

    /**
     * CV complet (identite, experience, formation, competences, langues,
     * style) tel qu'envoye a {@code POST /api/cvs}.
     */
    public static Map<String, Object> completeCv() {
        return Map.of(
                "titre", "Developpeur Full Stack",
                "personalInfo", Map.of(
                        "prenom", "Test",
                        "nom", "Integration",
                        "email", "test@integration.com",
                        "telephone", "+225 0700000000",
                        "ville", "Abidjan",
                        "pays", "Cote d'Ivoire",
                        "titrePoste", "Developpeur Full Stack Java",
                        "resumeProfessionnel", "Developpeur avec 3 ans d'experience"),
                "experiences", List.of(Map.of(
                        "poste", "Developpeur Web",
                        "entreprise", "TechCorp",
                        "lieu", "Abidjan",
                        "dateDebut", "2023-01-01",
                        "dateFin", "2025-12-31",
                        "description", "- Developpement applications web\n- Collaboration equipe agile",
                        "actuel", false)),
                "educations", List.of(Map.of(
                        "diplome", "Licence Informatique",
                        "etablissement", "Universite Test",
                        "dateDebut", "2019-10-01",
                        "dateFin", "2022-07-01",
                        "description", "Informatique")),
                "skills", List.of(
                        Map.of("nom", "Java", "niveau", 4),
                        Map.of("nom", "Angular", "niveau", 3),
                        Map.of("nom", "Spring Boot", "niveau", 4)),
                "languages", List.of(
                        Map.of("nom", "Francais", "langue", "Francais", "niveau", "C2"),
                        Map.of("nom", "Anglais", "langue", "Anglais", "niveau", "B1")),
                "style", Map.of(
                        "templateId", "moderne",
                        "primaryColor", COLOR_MODERNE,
                        "fontFamily", "Roboto"));
    }

    /**
     * Corps de mise a jour : nouveau titre, sections videes et style
     * "classique", tel qu'envoye a {@code PUT /api/cvs/{id}}.
     */
    public static Map<String, Object> renamedCv() {
        return Map.of(
                "titre", "Senior Developpeur Full Stack",
                "personalInfo", Map.of(
                        "prenom", "Test",
                        "nom", "Integration",
                        "email", "test@integration.com",
                        "titrePoste", "Senior Developpeur Full Stack"),
                "experiences", List.of(),
                "educations", List.of(),
                "skills", List.of(),
                "languages", List.of(),
                "style", Map.of(
                        "templateId", "classique",
                        "primaryColor", COLOR_CLASSIQUE,
                        "fontFamily", "Lato"));
    }
}
