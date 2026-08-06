package com.cvmobile.service.ai;

import com.cvmobile.config.JobMatchProperties;
import com.cvmobile.dto.JobMatchResponse;
import com.cvmobile.model.Cv;
import com.cvmobile.model.PersonalInfo;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * Detecte les risques de compatibilite ATS d'un CV et en derive un score de
 * format (issue #257). Extrait de {@code JobMatchServiceImpl}.
 */
@Component
@RequiredArgsConstructor
public class JobMatchFormatChecker {

    private final JobMatchTextAnalyzer text;
    private final JobMatchProperties properties;

    public List<JobMatchResponse.FormatCheck> buildFormatChecks(Cv cv) {
        List<JobMatchResponse.FormatCheck> checks = new ArrayList<>();
        PersonalInfo info = cv.getPersonalInfo();

        if (info == null || text.isBlank(info.getEmail()) || text.isBlank(info.getTelephone())) {
            checks.add(formatCheck(
                    "critical",
                    "Contact incomplet",
                    "Ajoutez au minimum un email valide et un numéro de téléphone."
            ));
        }
        if (info == null || text.isBlank(info.getTitrePoste())) {
            checks.add(formatCheck(
                    "warning",
                    "Titre de poste manquant",
                    "Un intitulé clair aide l'ATS à classer correctement le CV."
            ));
        }
        if (info == null || text.isBlank(info.getResumeProfessionnel())) {
            checks.add(formatCheck(
                    "warning",
                    "Résumé professionnel absent",
                    "Ajoutez 3 à 4 lignes ciblées pour reprendre le vocabulaire de l'offre."
            ));
        }
        if ("creatif".equalsIgnoreCase(cv.getStyleTemplateId())) {
            checks.add(formatCheck(
                    "warning",
                    "Template bicolonne",
                    "Le template créatif peut être moins fiable sur certains ATS. Préférez ATS-Safe ou Classique pour postuler."
            ));
        }
        if (estimateCvLength(cv) > 1.85) {
            checks.add(formatCheck(
                    "warning",
                    "CV probablement trop long",
                    "Le volume actuel risque de dépasser la longueur idéale pour une première lecture ATS."
            ));
        }
        if (cv.getExperiences().stream().anyMatch(exp -> text.isBlank(exp.getDescription()) || text.safe(exp.getDescription()).length() < 90)) {
            checks.add(formatCheck(
                    "info",
                    "Expériences peu détaillées",
                    "Ajoutez missions, outils et résultats pour éviter des sections trop génériques."
            ));
        }
        if (cv.getSkills().isEmpty()) {
            checks.add(formatCheck(
                    "critical",
                    "Compétences absentes",
                    "Sans bloc compétences, l'ATS repère moins bien les correspondances avec l'offre."
            ));
        }
        return checks;
    }

    public int scoreFormat(List<JobMatchResponse.FormatCheck> checks) {
        int score = properties.maxScore();
        for (JobMatchResponse.FormatCheck check : checks) {
            score -= switch (check.getSeverity()) {
                case "critical" -> 22;
                case "warning" -> 12;
                default -> 6;
            };
        }
        return Math.max(25, score);
    }

    private JobMatchResponse.FormatCheck formatCheck(String severity, String label, String detail) {
        return JobMatchResponse.FormatCheck.builder()
                .severity(severity)
                .label(label)
                .detail(detail)
                .build();
    }

    private double estimateCvLength(Cv cv) {
        int sectionCount = cv.getExperiences().size() * 180
                + cv.getEducations().size() * 90
                + cv.getProjects().size() * 110
                + cv.getSkills().size() * 18
                + cv.getLanguages().size() * 18
                + text.safe(cv.getPersonalInfo() != null ? cv.getPersonalInfo().getResumeProfessionnel() : null).length();
        return sectionCount / 900.0;
    }
}
