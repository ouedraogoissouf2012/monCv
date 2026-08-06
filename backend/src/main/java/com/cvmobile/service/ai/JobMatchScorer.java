package com.cvmobile.service.ai;

import com.cvmobile.config.JobMatchProperties;
import com.cvmobile.dto.JobMatchResponse;
import com.cvmobile.model.Certification;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Experience;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Calcule les scores par categorie du matching CV / offre et leurs resumes
 * (issue #257). Extrait de {@code JobMatchServiceImpl}.
 *
 * Les constantes de ponderation restent volontairement en ligne : ce sont des
 * valeurs de tuning locales, lisibles dans leur contexte de scoring.
 */
@Component
@RequiredArgsConstructor
public class JobMatchScorer {

    private static final Map<String, String> EDUCATION_TERMS = Map.of(
            "master", "Master / Bac+5",
            "bac+5", "Master / Bac+5",
            "licence", "Licence / Bac+3",
            "bachelor", "Licence / Bachelor",
            "doctorat", "Doctorat",
            "phd", "Doctorat",
            "certification", "Certification demandée",
            "diplome", "Diplôme demandé",
            "degree", "Degree required"
    );

    private final JobMatchTextAnalyzer text;
    private final JobMatchProperties properties;

    public JobMatchResponse.CategoryScore buildCategory(
            String key, String label, int score, String summary, List<String> evidence) {
        return JobMatchResponse.CategoryScore.builder()
                .key(key)
                .label(label)
                .score(Math.max(0, Math.min(properties.maxScore(), score)))
                .summary(summary)
                .evidence(evidence.stream().filter(s -> s != null && !s.isBlank()).distinct().toList())
                .build();
    }

    public int scoreTechnicalSkills(Cv cv, List<String> technicalKeywords) {
        if (technicalKeywords.isEmpty()) {
            return cv.getSkills().isEmpty() ? 55 : 85;
        }
        String normalizedSkills = text.normalize(
                cv.getSkills().stream()
                        .map(skill -> text.safe(skill.getNom()) + " " + text.safe(skill.getCategorie()))
                        .collect(Collectors.joining(" | "))
        );
        long matched = technicalKeywords.stream()
                .filter(keyword -> text.containsTerm(normalizedSkills, keyword))
                .count();
        return ratioScore((int) matched, technicalKeywords.size());
    }

    public int scoreSoftSkills(Cv cv, List<String> softSkillKeywords) {
        if (softSkillKeywords.isEmpty()) {
            return 80;
        }
        String normalizedCvText = text.normalize(text.collectCvText(cv));
        long matched = softSkillKeywords.stream()
                .filter(keyword -> text.containsTerm(normalizedCvText, keyword))
                .count();
        return ratioScore((int) matched, softSkillKeywords.size());
    }

    public int scoreTitleMatch(Cv cv, String jobDescription) {
        String candidateTitle = text.normalize(cv.getPersonalInfo() != null ? cv.getPersonalInfo().getTitrePoste() : cv.getTitre());
        String jobTitle = text.extractJobTitle(jobDescription);
        if (jobTitle.isBlank() || candidateTitle.isBlank()) {
            return 55;
        }

        var titleTokens = text.tokenize(jobTitle);
        if (titleTokens.isEmpty()) {
            return 55;
        }

        long overlap = titleTokens.stream()
                .filter(token -> text.containsTerm(candidateTitle, token))
                .count();
        return ratioScore((int) overlap, titleTokens.size());
    }

    public String buildTitleSummary(Cv cv, String jobDescription) {
        String cvTitle = text.safe(cv.getPersonalInfo() != null ? cv.getPersonalInfo().getTitrePoste() : cv.getTitre());
        String jobTitle = text.restoreSpacing(text.extractJobTitle(jobDescription));
        if (cvTitle.isBlank()) {
            return "Le CV n'affiche pas d'intitulé métier clair.";
        }
        if (jobTitle.isBlank()) {
            return "Le titre du CV est présent mais l'offre n'expose pas un intitulé simple à comparer.";
        }
        return "Titre CV : " + cvTitle + " | Intitulé détecté dans l'offre : " + jobTitle;
    }

    public int scoreExperience(Cv cv, String jobDescription) {
        if (cv.getExperiences().isEmpty()) {
            return 20;
        }
        int score = 45;
        long richDescriptions = cv.getExperiences().stream()
                .filter(exp -> text.safe(exp.getDescription()).length() >= 120)
                .count();
        score += (int) Math.min(25, richDescriptions * 8);

        long quantifiedDescriptions = cv.getExperiences().stream()
                .filter(exp -> text.safe(exp.getDescription()).matches("(?s).*\\d+.*"))
                .count();
        score += (int) Math.min(15, quantifiedDescriptions * 6);

        String normalizedExperience = text.normalize(
                cv.getExperiences().stream()
                        .map(exp -> text.safe(exp.getPoste()) + " " + text.safe(exp.getDescription()))
                        .collect(Collectors.joining(" "))
        );
        List<String> demandedKeywords = text.extractKeywords(jobDescription).stream().limit(12).toList();
        long matchedDemanded = demandedKeywords.stream()
                .filter(keyword -> text.containsTerm(normalizedExperience, keyword))
                .count();
        score += (int) Math.min(15, matchedDemanded * 3);
        return Math.min(properties.maxScore(), score);
    }

    public String buildExperienceSummary(Cv cv) {
        if (cv.getExperiences().isEmpty()) {
            return "Aucune expérience professionnelle n'est encore renseignée.";
        }
        long totalMonths = cv.getExperiences().stream()
                .mapToLong(this::estimateMonths)
                .sum();
        return "Le CV présente " + cv.getExperiences().size() + " expérience(s) pour environ "
                + Math.max(1, totalMonths / 12) + " an(s) d'activité visible.";
    }

    private long estimateMonths(Experience experience) {
        if (experience.getDateDebut() == null) {
            return 6;
        }
        LocalDate start = experience.getDateDebut();
        LocalDate end = Boolean.TRUE.equals(experience.getActuel()) || experience.getDateFin() == null
                ? LocalDate.now()
                : experience.getDateFin();
        return Math.max(1, ChronoUnit.MONTHS.between(start, end.plusDays(1)));
    }

    public int scoreEducation(Cv cv, String jobDescription) {
        List<String> requiredEducation = EDUCATION_TERMS.keySet().stream()
                .filter(term -> text.containsTerm(text.normalize(jobDescription), term))
                .toList();
        if (requiredEducation.isEmpty()) {
            return cv.getEducations().isEmpty() ? 65 : 85;
        }
        if (cv.getEducations().isEmpty() && cv.getCertifications().isEmpty()) {
            return 25;
        }
        String normalizedEducation = text.normalize(
                cv.getEducations().stream()
                        .map(edu -> text.safe(edu.getDiplome()) + " " + text.safe(edu.getDomaine()))
                        .collect(Collectors.joining(" "))
                        + " "
                        + cv.getCertifications().stream()
                        .map(certification -> text.safe(certification.getNom()))
                        .collect(Collectors.joining(" "))
        );
        long matched = requiredEducation.stream()
                .filter(term -> text.containsTerm(normalizedEducation, term))
                .count();
        return ratioScore((int) matched, requiredEducation.size());
    }

    public String buildEducationSummary(Cv cv, String jobDescription) {
        if (cv.getEducations().isEmpty() && cv.getCertifications().isEmpty()) {
            return "Aucune formation ou certification n'est encore visible dans le CV.";
        }
        List<String> expected = EDUCATION_TERMS.keySet().stream()
                .filter(term -> text.containsTerm(text.normalize(jobDescription), term))
                .map(EDUCATION_TERMS::get)
                .distinct()
                .toList();
        if (expected.isEmpty()) {
            return "Le CV contient déjà un socle formation/certification, même si l'offre reste peu précise sur ce point.";
        }
        return "Attendus repérés dans l'offre : " + String.join(", ", expected);
    }

    public List<String> buildEducationEvidence(Cv cv, String jobDescription) {
        List<String> evidence = new ArrayList<>();
        cv.getEducations().stream()
                .map(education -> text.safe(education.getDiplome()))
                .filter(value -> !value.isBlank())
                .limit(2)
                .forEach(evidence::add);
        cv.getCertifications().stream()
                .map(Certification::getNom)
                .map(text::safe)
                .filter(value -> !value.isBlank())
                .limit(2)
                .forEach(evidence::add);
        if (evidence.isEmpty()) {
            evidence.addAll(EDUCATION_TERMS.keySet().stream()
                    .filter(term -> text.containsTerm(text.normalize(jobDescription), term))
                    .map(EDUCATION_TERMS::get)
                    .distinct()
                    .limit(2)
                    .toList());
        }
        return evidence;
    }

    public int weightedAverage(List<JobMatchResponse.CategoryScore> categories) {
        Map<String, Integer> weights = new LinkedHashMap<>();
        weights.put("keywords", 24);
        weights.put("technical_skills", 18);
        weights.put("soft_skills", 10);
        weights.put("job_title", 10);
        weights.put("experience", 18);
        weights.put("education", 8);
        weights.put("ats_format", 12);

        int totalWeight = weights.values().stream().mapToInt(Integer::intValue).sum();
        int weightedSum = categories.stream()
                .mapToInt(category -> category.getScore() * weights.getOrDefault(category.getKey(), 10))
                .sum();
        return weightedSum / totalWeight;
    }

    public int ratioScore(int matched, int total) {
        if (total <= 0) {
            return 70;
        }
        return Math.max(0, Math.min(
                properties.maxScore(),
                (matched * properties.maxScore()) / total
        ));
    }
}
