package com.cvmobile.service.ai;

import com.cvmobile.model.Certification;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Education;
import com.cvmobile.model.Experience;
import com.cvmobile.model.Language;
import com.cvmobile.model.Project;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.stream.Collectors;

/**
 * Construit le prompt d'analyse de correspondance CV / offre envoye a l'IA
 * (issue #257). Extrait de {@code JobMatchServiceImpl}.
 */
@Component
@RequiredArgsConstructor
public class JobMatchPromptBuilder {

    private final JobMatchTextAnalyzer text;

    public String buildMatchPrompt(Cv cv, String jobDescription) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tu es un expert en recrutement et en optimisation de CV pour les ATS. ");
        sb.append("Analyse ce CV par rapport a cette offre d'emploi et donne un score de correspondance.\n\n");
        sb.append(AiPromptRules.FRANCOPHONE_MARKET_RULE);
        sb.append(AiPromptRules.ANTI_CLICHES_RULE);
        sb.append(AiPromptRules.INJECTION_GUARD);
        sb.append("Donne des suggestions courtes, concretes et directement actionnables. ");
        sb.append("Cite des mots-cles exacts quand c'est utile.\n\n");
        sb.append("Reponds EXACTEMENT dans ce format :\n\n");
        sb.append("SCORE: (nombre de 0 a 100)\n\n");
        sb.append("MOTS_CLES_PRESENTS:\n- mot1\n- mot2\n\n");
        sb.append("MOTS_CLES_MANQUANTS:\n- mot1\n- mot2\n\n");
        sb.append("SUGGESTIONS:\n- suggestion1\n- suggestion2\n- suggestion3\n\n");
        sb.append("RESUME_OPTIMISE:\n(resume professionnel reecrit pour correspondre a cette offre)\n\n");

        sb.append("---\nOFFRE D'EMPLOI :\n").append(AiPromptRules.fenceUserContent(jobDescription)).append("\n\n");

        sb.append("---\nCV DU CANDIDAT :\n");
        if (cv.getPersonalInfo() != null) {
            sb.append("Poste : ").append(text.safe(cv.getPersonalInfo().getTitrePoste())).append("\n");
            sb.append("Resume : ").append(text.safe(cv.getPersonalInfo().getResumeProfessionnel())).append("\n");
            sb.append("Ville : ").append(text.safe(cv.getPersonalInfo().getVille())).append("\n\n");
        }
        sb.append("Competences : ");
        sb.append(cv.getSkills().stream().map(skill -> text.safe(skill.getNom())).collect(Collectors.joining(", ")));
        sb.append("\n\nExperiences :\n");
        for (Experience exp : cv.getExperiences()) {
            sb.append("- ").append(text.safe(exp.getPoste())).append(" chez ").append(text.safe(exp.getEntreprise()));
            sb.append(" : ").append(text.safe(exp.getDescription()).isBlank() ? "(vide)" : text.safe(exp.getDescription())).append("\n");
        }

        if (!cv.getEducations().isEmpty()) {
            sb.append("\nFormations :\n");
            for (Education education : cv.getEducations()) {
                sb.append("- ").append(text.safe(education.getDiplome())).append(" / ")
                        .append(text.safe(education.getDomaine())).append("\n");
            }
        }

        if (!cv.getProjects().isEmpty()) {
            sb.append("\nProjets :\n");
            for (Project project : cv.getProjects()) {
                sb.append("- ").append(text.safe(project.getNom())).append(" : ")
                        .append(text.safe(project.getTechnologies())).append(" / ")
                        .append(text.safe(project.getDescription())).append("\n");
            }
        }

        if (!cv.getCertifications().isEmpty()) {
            sb.append("\nCertifications :\n");
            for (Certification certification : cv.getCertifications()) {
                sb.append("- ").append(text.safe(certification.getNom())).append("\n");
            }
        }

        if (!cv.getLanguages().isEmpty()) {
            sb.append("\nLangues :\n");
            for (Language language : cv.getLanguages()) {
                sb.append("- ").append(text.safe(language.getLangue())).append(" : ")
                        .append(text.safe(language.getNiveau() != null ? language.getNiveau().name() : null)).append("\n");
            }
        }

        return sb.toString();
    }
}
