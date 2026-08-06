package com.cvmobile.service.ai;

import com.cvmobile.model.Cv;
import com.cvmobile.model.Education;
import com.cvmobile.model.Experience;
import com.cvmobile.model.Project;
import com.cvmobile.model.Skill;
import org.springframework.stereotype.Component;

import java.util.stream.Collectors;

import static com.cvmobile.service.ai.AiPromptRules.*;

/**
 * Construit les prompts envoyes a l'IA pour l'amelioration et l'adaptation d'un
 * CV (issue #256). Extrait de {@code EnhancementServiceImpl}.
 *
 * Compose les regles de {@link AiPromptRules} selon le niveau, decrit le format
 * de reponse attendu (marqueurs) et injecte les donnees actuelles du CV.
 */
@Component
public class CvPromptBuilder {

    public String buildEnhancePrompt(Cv cv, String level) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tu es un expert en redaction de CV professionnels, specialise en optimisation ATS ");
        sb.append("(Applicant Tracking System). Tu connais les attentes des recruteurs en 2026. ");

        sb.append(GRAMMAR_RULE); sb.append(TITLE_RULE);
        sb.append(FRANCOPHONE_MARKET_RULE);
        sb.append(GROUNDING_RULE);
        switch (level.toUpperCase()) {
            case "LITE" -> sb.append(
                    "Corrige uniquement l'orthographe, la grammaire et les accents. "
                    + "Garde exactement le même sens et les mêmes mots. "
                    + "Ne reformule PAS, ne change PAS la structure. "
                    + "Ajoute les accents manquants (Developpeur → Développeur). "
                    + PROOFREADING_SKILL_RULE);
            case "MEDIUM" -> {
                sb.append(
                    "Corrige l'orthographe et les accents. "
                    + "Reformule pour plus d'impact professionnel. ");
                sb.append(ANTI_CLICHES_RULE);
                sb.append(STYLE_RULE);
            }
            default -> { // MAX
                sb.append(
                    "Optimise complètement ce CV pour un maximum d'impact ATS et recruteur. ");
                sb.append(ANTI_CLICHES_RULE);
                sb.append(STYLE_RULE);
                sb.append(QUANTIFICATION_RULE);
                sb.append(SKILL_CATEGORY_RULE);
                sb.append(PROJECT_RULE);
                sb.append("Pour le résumé, écris 3-4 phrases percutantes. ");
            }
        }

        appendResponseFormat(sb, cv, false);
        appendCurrentCvData(sb, cv);

        return sb.toString();
    }

    public String buildAdaptPrompt(Cv cv, String jobDescription) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tu es un expert en redaction de CV professionnels. ");
        sb.append("Adapte ce CV pour correspondre au maximum a cette offre d'emploi. ");
        sb.append("Extrait aussi un titre court de l'offre (ex: 'Developpeur Backend Java — Sopra Steria'). ");
        sb.append("OFFRE D'EMPLOI:\n").append(jobDescription).append("\n\n");

        sb.append(GRAMMAR_RULE);
        sb.append(TITLE_RULE);
        sb.append(GROUNDING_RULE); sb.append(ANTI_CLICHES_RULE);
        sb.append(STYLE_RULE);
        sb.append(FRANCOPHONE_MARKET_RULE);
        sb.append(QUANTIFICATION_RULE);
        sb.append(SKILL_CATEGORY_RULE);

        appendResponseFormat(sb, cv, true);
        appendCurrentCvData(sb, cv);

        return sb.toString();
    }

    private void appendResponseFormat(StringBuilder sb, Cv cv, boolean includeJobTitle) {
        sb.append("\nReponds en francais uniquement. ");
        sb.append("IMPORTANT: Utilise EXACTEMENT ce format avec les marqueurs :\n\n");
        if (includeJobTitle) {
            sb.append("TITRE_OFFRE:\n(titre court de l'offre, max 60 caracteres, ex: 'Developpeur Backend Java — Sopra Steria')\n\n");
        }
        sb.append("TITRE_POSTE:\n(titre de poste ameliore)\n\n");
        sb.append("RESUME:\n(resume professionnel ameliore)\n\n");

        for (Experience exp : cv.getExperiences()) {
            sb.append("EXP_").append(exp.getId()).append(":\n");
            sb.append("(description amelioree avec tirets - pour chaque point)\n\n");
        }
        for (Education edu : cv.getEducations()) {
            sb.append("EDU_").append(edu.getId()).append(":\n");
            sb.append("(description amelioree de la formation)\n\n");
        }
        sb.append("COMPETENCES:\n(liste de competences separees par des virgules, une par une)\n\n");
        for (Project proj : cv.getProjects()) {
            sb.append("PROJ_").append(proj.getId()).append(":\n");
            sb.append("(description amelioree du projet)\n\n");
        }
    }

    private void appendCurrentCvData(StringBuilder sb, Cv cv) {
        sb.append("---\nDONNEES ACTUELLES DU CV :\n\n");

        if (cv.getPersonalInfo() != null) {
            sb.append("Titre de poste : ").append(
                    cv.getPersonalInfo().getTitrePoste() != null ? cv.getPersonalInfo().getTitrePoste() : "(vide)").append("\n");
            sb.append("Resume : ").append(
                    cv.getPersonalInfo().getResumeProfessionnel() != null ? cv.getPersonalInfo().getResumeProfessionnel() : "(vide)").append("\n\n");
        }

        for (Experience exp : cv.getExperiences()) {
            sb.append("EXP_").append(exp.getId()).append(" : ").append(exp.getPoste());
            sb.append(" chez ").append(exp.getEntreprise());
            sb.append(" | Description : ").append(exp.getDescription() != null ? exp.getDescription() : "(vide)").append("\n");
        }
        sb.append("\n");

        for (Education edu : cv.getEducations()) {
            sb.append("EDU_").append(edu.getId()).append(" : ").append(edu.getDiplome());
            sb.append(" a ").append(edu.getEtablissement());
            sb.append(" | Description : ").append(edu.getDescription() != null ? edu.getDescription() : "(vide)").append("\n");
        }
        sb.append("\n");

        sb.append("Competences actuelles : ");
        sb.append(cv.getSkills().stream().map(Skill::getNom).collect(Collectors.joining(", ")));
        sb.append("\n\n");

        for (Project proj : cv.getProjects()) {
            sb.append("PROJ_").append(proj.getId()).append(" : ").append(proj.getNom());
            sb.append(" | Technologies : ").append(proj.getTechnologies() != null ? proj.getTechnologies() : "");
            sb.append(" | Description : ").append(proj.getDescription() != null ? proj.getDescription() : "(vide)").append("\n");
        }
    }
}
