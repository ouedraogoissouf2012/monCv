package com.cvmobile.service.ai;

import com.cvmobile.config.JobMatchProperties;
import com.cvmobile.dto.JobMatchResponse;
import com.cvmobile.model.Certification;
import com.cvmobile.model.Cv;
import com.cvmobile.model.Education;
import com.cvmobile.model.Experience;
import com.cvmobile.model.Language;
import com.cvmobile.model.PersonalInfo;
import com.cvmobile.model.Project;
import com.cvmobile.model.Skill;
import com.cvmobile.service.CvQualityService;
import com.cvmobile.service.ai.client.IAiClient;
import com.cvmobile.service.cv.CvOwnershipService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.text.Normalizer;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Analyse de correspondance CV / offre d'emploi.
 * Calcule un score ATS lisible, détaille les catégories clés et complète le rapport avec des recommandations IA.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class JobMatchServiceImpl implements IJobMatchService {
    private static final Pattern SCORE_PATTERN = Pattern.compile("SCORE:\\s*(\\d+)");
    private static final Pattern WORD_PATTERN = Pattern.compile("[\\p{L}\\p{N}][\\p{L}\\p{N}+.#/-]{2,}");
    private static final Set<String> STOP_WORDS = Set.of(
            "avec", "sans", "dans", "pour", "vous", "votre", "notre", "leurs", "elles", "nous",
            "mais", "donc", "etre", "avoir", "faire", "tres", "plus", "moins", "ainsi", "afin",
            "chez", "cette", "poste", "profil", "entreprise", "mission", "missions", "offre",
            "emploi", "candidat", "candidate", "projet", "projets", "travail", "entre",
            "toute", "tous", "tout", "from", "that", "this", "with", "will", "able", "must",
            "need", "needs", "required", "preferred", "experience", "experiences", "years", "year"
    );

    private static final Set<String> SOFT_SKILL_TERMS = Set.of(
            "communication", "leadership", "autonomie", "autonome", "rigueur", "rigoureux",
            "collaboration", "organisation", "empathie", "adaptabilite", "adaptability",
            "teamwork", "stakeholder", "presentation", "negociation", "negotiation",
            "mentoring", "coaching", "facilitation", "gestion", "coordination"
    );

    private static final Set<String> TECH_HINTS = Set.of(
            "java", "spring", "flutter", "dart", "kotlin", "android", "ios", "swift", "python",
            "sql", "nosql", "docker", "kubernetes", "aws", "azure", "gcp", "react", "angular",
            "node", "nodejs", "typescript", "javascript", "figma", "photoshop", "excel",
            "powerbi", "tableau", "scrum", "jira", "sap", "seo", "sem", "crm", "api", "rest",
            "graphql", "git", "github", "gitlab", "firebase", "linux", "mongodb", "postgresql"
    );

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

    private final IAiClient aiClient;
    private final CvOwnershipService cvOwnershipService;
    private final CvQualityService cvQualityService;
    private final JobMatchProperties properties;

    @Override
    public JobMatchResponse matchJob(Long cvId, Long userId, String jobDescription) {
        Cv cv = cvOwnershipService.requireOwnedCv(cvId, userId);

        return analyzeMatch(cv, jobDescription);
    }

    private JobMatchResponse analyzeMatch(Cv cv, String jobDescription) {
        String prompt = buildMatchPrompt(cv, jobDescription);
        String rawContent = aiClient.complete(prompt, properties.completionTokens());
        boolean fallback = aiClient.isFallbackResult();
        log.debug("AI match response received ({} chars)", rawContent.length());

        List<String> allMarkers = List.of(
                "SCORE:", "MOTS_CLES_PRESENTS:", "MOTS_CLES_MANQUANTS:",
                "SUGGESTIONS:", "RESUME_OPTIMISE:");

        int aiScore = extractAiScore(rawContent);
        List<String> aiMatched = AiResponseParser.extractListSection(rawContent, "MOTS_CLES_PRESENTS:", allMarkers);
        List<String> aiMissing = AiResponseParser.extractListSection(rawContent, "MOTS_CLES_MANQUANTS:", allMarkers);
        List<String> aiSuggestions = AiResponseParser.extractListSection(rawContent, "SUGGESTIONS:", allMarkers);
        String optimizedResume = AiResponseParser.extractBetweenMarkers(rawContent, "RESUME_OPTIMISE:", allMarkers);

        MatchAnalysis analysis = buildDeterministicAnalysis(cv, jobDescription, aiMatched, aiMissing, aiSuggestions, aiScore);

        return JobMatchResponse.builder()
                .score(analysis.globalScore())
                .matchedKeywords(analysis.matchedKeywords())
                .missingKeywords(analysis.missingKeywords())
                .suggestions(analysis.suggestions())
                .categories(analysis.categories())
                .prioritizedRecommendations(analysis.recommendations())
                .formatChecks(analysis.formatChecks())
                .optimizedResume(optimizedResume.isBlank() ? null : optimizedResume)
                .aiGenerated(!fallback)
                .fallback(fallback)
                .build();
    }

    private MatchAnalysis buildDeterministicAnalysis(
            Cv cv,
            String jobDescription,
            List<String> aiMatched,
            List<String> aiMissing,
            List<String> aiSuggestions,
            int aiScore
    ) {
        String cvText = collectCvText(cv);
        String normalizedCvText = normalize(cvText);
        LinkedHashSet<String> extractedKeywords = extractKeywords(jobDescription);

        List<String> matchedKeywords = mergeKeywords(
                aiMatched,
                extractedKeywords.stream()
                        .filter(keyword -> containsTerm(normalizedCvText, keyword))
                        .toList()
        );

        List<String> missingKeywords = mergeKeywords(
                aiMissing,
                extractedKeywords.stream()
                        .filter(keyword -> !containsTerm(normalizedCvText, keyword))
                        .toList()
        );

        List<String> technicalKeywords = extractedKeywords.stream()
                .filter(this::isTechnicalKeyword)
                .toList();
        List<String> softSkillKeywords = extractedKeywords.stream()
                .filter(this::isSoftSkillKeyword)
                .toList();

        List<JobMatchResponse.FormatCheck> formatChecks = buildFormatChecks(cv);
        List<String> qualityWarnings = cvQualityService.findReviewWarnings(cv);

        JobMatchResponse.CategoryScore keywordCategory = buildCategory(
                "keywords",
                "Mots-clés ATS",
                ratioScore(matchedKeywords.size(), matchedKeywords.size() + missingKeywords.size()),
                matchedKeywords.isEmpty()
                        ? "Le CV ne reprend pas encore les termes les plus visibles de l'offre."
                        : "Les mots-clés repris correspondent partiellement au vocabulaire demandé.",
                firstItems(missingKeywords.isEmpty() ? matchedKeywords : missingKeywords, 4)
        );

        JobMatchResponse.CategoryScore technicalCategory = buildCategory(
                "technical_skills",
                "Compétences techniques",
                scoreTechnicalSkills(cv, technicalKeywords),
                technicalKeywords.isEmpty()
                        ? "L'offre contient peu de marqueurs techniques explicites."
                        : "Les compétences techniques visibles dans le CV couvrent une partie des attentes.",
                firstItems(technicalKeywords, 4)
        );

        JobMatchResponse.CategoryScore softCategory = buildCategory(
                "soft_skills",
                "Soft skills",
                scoreSoftSkills(cv, softSkillKeywords),
                softSkillKeywords.isEmpty()
                        ? "L'offre décrit surtout des attendus métier."
                        : "Les qualités relationnelles ou de coordination sont partiellement visibles.",
                firstItems(softSkillKeywords, 4)
        );

        JobMatchResponse.CategoryScore titleCategory = buildCategory(
                "job_title",
                "Intitulé du poste",
                scoreTitleMatch(cv, jobDescription),
                buildTitleSummary(cv, jobDescription),
                List.of(safe(cv.getPersonalInfo() != null ? cv.getPersonalInfo().getTitrePoste() : null))
        );

        JobMatchResponse.CategoryScore experienceCategory = buildCategory(
                "experience",
                "Expérience",
                scoreExperience(cv, jobDescription),
                buildExperienceSummary(cv),
                firstItems(qualityWarnings, 3)
        );

        JobMatchResponse.CategoryScore educationCategory = buildCategory(
                "education",
                "Formation",
                scoreEducation(cv, jobDescription),
                buildEducationSummary(cv, jobDescription),
                buildEducationEvidence(cv, jobDescription)
        );

        JobMatchResponse.CategoryScore formatCategory = buildCategory(
                "ats_format",
                "Format ATS",
                scoreFormat(formatChecks),
                formatChecks.isEmpty()
                        ? "Aucun risque ATS critique n'a été détecté."
                        : "Le format présente encore des points à fiabiliser pour l'ATS.",
                formatChecks.stream().map(JobMatchResponse.FormatCheck::getLabel).toList()
        );

        List<JobMatchResponse.CategoryScore> categories = List.of(
                keywordCategory,
                technicalCategory,
                softCategory,
                titleCategory,
                experienceCategory,
                educationCategory,
                formatCategory
        );

        int weightedScore = weightedAverage(categories);
        int globalScore = Math.max(0, Math.min(properties.maxScore(), (weightedScore + aiScore) / 2));

        List<String> suggestions = mergeSuggestions(
                aiSuggestions,
                buildFallbackSuggestions(missingKeywords, formatChecks, qualityWarnings)
        );

        List<JobMatchResponse.PrioritizedRecommendation> recommendations = buildRecommendations(
                missingKeywords,
                technicalKeywords,
                softSkillKeywords,
                formatChecks,
                qualityWarnings,
                categories
        );

        return new MatchAnalysis(
                globalScore,
                matchedKeywords,
                missingKeywords,
                suggestions,
                categories,
                recommendations,
                formatChecks
        );
    }

    private int extractAiScore(String rawContent) {
        Matcher scoreMatcher = SCORE_PATTERN.matcher(rawContent);
        if (scoreMatcher.find()) {
            return Math.min(properties.maxScore(), Integer.parseInt(scoreMatcher.group(1)));
        }
        return properties.defaultScore();
    }

    private JobMatchResponse.CategoryScore buildCategory(
            String key,
            String label,
            int score,
            String summary,
            List<String> evidence
    ) {
        return JobMatchResponse.CategoryScore.builder()
                .key(key)
                .label(label)
                .score(Math.max(0, Math.min(properties.maxScore(), score)))
                .summary(summary)
                .evidence(evidence.stream().filter(s -> s != null && !s.isBlank()).distinct().toList())
                .build();
    }

    private List<JobMatchResponse.FormatCheck> buildFormatChecks(Cv cv) {
        List<JobMatchResponse.FormatCheck> checks = new ArrayList<>();
        PersonalInfo info = cv.getPersonalInfo();

        if (info == null || isBlank(info.getEmail()) || isBlank(info.getTelephone())) {
            checks.add(formatCheck(
                    "critical",
                    "Contact incomplet",
                    "Ajoutez au minimum un email valide et un numéro de téléphone."
            ));
        }
        if (info == null || isBlank(info.getTitrePoste())) {
            checks.add(formatCheck(
                    "warning",
                    "Titre de poste manquant",
                    "Un intitulé clair aide l'ATS à classer correctement le CV."
            ));
        }
        if (info == null || isBlank(info.getResumeProfessionnel())) {
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
        if (cv.getExperiences().stream().anyMatch(exp -> isBlank(exp.getDescription()) || safe(exp.getDescription()).length() < 90)) {
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

    private JobMatchResponse.FormatCheck formatCheck(String severity, String label, String detail) {
        return JobMatchResponse.FormatCheck.builder()
                .severity(severity)
                .label(label)
                .detail(detail)
                .build();
    }

    private int scoreTechnicalSkills(Cv cv, List<String> technicalKeywords) {
        if (technicalKeywords.isEmpty()) {
            return cv.getSkills().isEmpty() ? 55 : 85;
        }
        String normalizedSkills = normalize(
                cv.getSkills().stream()
                        .map(skill -> safe(skill.getNom()) + " " + safe(skill.getCategorie()))
                        .collect(Collectors.joining(" | "))
        );
        long matched = technicalKeywords.stream()
                .filter(keyword -> containsTerm(normalizedSkills, keyword))
                .count();
        return ratioScore((int) matched, technicalKeywords.size());
    }

    private int scoreSoftSkills(Cv cv, List<String> softSkillKeywords) {
        if (softSkillKeywords.isEmpty()) {
            return 80;
        }
        String normalizedCvText = normalize(collectCvText(cv));
        long matched = softSkillKeywords.stream()
                .filter(keyword -> containsTerm(normalizedCvText, keyword))
                .count();
        return ratioScore((int) matched, softSkillKeywords.size());
    }

    private int scoreTitleMatch(Cv cv, String jobDescription) {
        String candidateTitle = normalize(cv.getPersonalInfo() != null ? cv.getPersonalInfo().getTitrePoste() : cv.getTitre());
        String jobTitle = extractJobTitle(jobDescription);
        if (jobTitle.isBlank() || candidateTitle.isBlank()) {
            return 55;
        }

        Set<String> titleTokens = tokenize(jobTitle);
        if (titleTokens.isEmpty()) {
            return 55;
        }

        long overlap = titleTokens.stream()
                .filter(token -> containsTerm(candidateTitle, token))
                .count();
        return ratioScore((int) overlap, titleTokens.size());
    }

    private String buildTitleSummary(Cv cv, String jobDescription) {
        String cvTitle = safe(cv.getPersonalInfo() != null ? cv.getPersonalInfo().getTitrePoste() : cv.getTitre());
        String jobTitle = restoreSpacing(extractJobTitle(jobDescription));
        if (cvTitle.isBlank()) {
            return "Le CV n'affiche pas d'intitulé métier clair.";
        }
        if (jobTitle.isBlank()) {
            return "Le titre du CV est présent mais l'offre n'expose pas un intitulé simple à comparer.";
        }
        return "Titre CV : " + cvTitle + " | Intitulé détecté dans l'offre : " + jobTitle;
    }

    private int scoreExperience(Cv cv, String jobDescription) {
        if (cv.getExperiences().isEmpty()) {
            return 20;
        }
        int score = 45;
        long richDescriptions = cv.getExperiences().stream()
                .filter(exp -> safe(exp.getDescription()).length() >= 120)
                .count();
        score += (int) Math.min(25, richDescriptions * 8);

        long quantifiedDescriptions = cv.getExperiences().stream()
                .filter(exp -> safe(exp.getDescription()).matches("(?s).*\\d+.*"))
                .count();
        score += (int) Math.min(15, quantifiedDescriptions * 6);

        String normalizedExperience = normalize(
                cv.getExperiences().stream()
                        .map(exp -> safe(exp.getPoste()) + " " + safe(exp.getDescription()))
                        .collect(Collectors.joining(" "))
        );
        List<String> demandedKeywords = extractKeywords(jobDescription).stream().limit(12).toList();
        long matchedDemanded = demandedKeywords.stream()
                .filter(keyword -> containsTerm(normalizedExperience, keyword))
                .count();
        score += (int) Math.min(15, matchedDemanded * 3);
        return Math.min(properties.maxScore(), score);
    }

    private String buildExperienceSummary(Cv cv) {
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

    private int scoreEducation(Cv cv, String jobDescription) {
        List<String> requiredEducation = EDUCATION_TERMS.keySet().stream()
                .filter(term -> containsTerm(normalize(jobDescription), term))
                .toList();
        if (requiredEducation.isEmpty()) {
            return cv.getEducations().isEmpty() ? 65 : 85;
        }
        if (cv.getEducations().isEmpty() && cv.getCertifications().isEmpty()) {
            return 25;
        }
        String normalizedEducation = normalize(
                cv.getEducations().stream()
                        .map(edu -> safe(edu.getDiplome()) + " " + safe(edu.getDomaine()))
                        .collect(Collectors.joining(" "))
                        + " "
                        + cv.getCertifications().stream()
                        .map(certification -> safe(certification.getNom()))
                        .collect(Collectors.joining(" "))
        );
        long matched = requiredEducation.stream()
                .filter(term -> containsTerm(normalizedEducation, term))
                .count();
        return ratioScore((int) matched, requiredEducation.size());
    }

    private String buildEducationSummary(Cv cv, String jobDescription) {
        if (cv.getEducations().isEmpty() && cv.getCertifications().isEmpty()) {
            return "Aucune formation ou certification n'est encore visible dans le CV.";
        }
        List<String> expected = EDUCATION_TERMS.keySet().stream()
                .filter(term -> containsTerm(normalize(jobDescription), term))
                .map(EDUCATION_TERMS::get)
                .distinct()
                .toList();
        if (expected.isEmpty()) {
            return "Le CV contient déjà un socle formation/certification, même si l'offre reste peu précise sur ce point.";
        }
        return "Attendus repérés dans l'offre : " + String.join(", ", expected);
    }

    private List<String> buildEducationEvidence(Cv cv, String jobDescription) {
        List<String> evidence = new ArrayList<>();
        cv.getEducations().stream()
                .map(education -> safe(education.getDiplome()))
                .filter(value -> !value.isBlank())
                .limit(2)
                .forEach(evidence::add);
        cv.getCertifications().stream()
                .map(Certification::getNom)
                .map(this::safe)
                .filter(value -> !value.isBlank())
                .limit(2)
                .forEach(evidence::add);
        if (evidence.isEmpty()) {
            evidence.addAll(EDUCATION_TERMS.keySet().stream()
                    .filter(term -> containsTerm(normalize(jobDescription), term))
                    .map(EDUCATION_TERMS::get)
                    .distinct()
                    .limit(2)
                    .toList());
        }
        return evidence;
    }

    private int scoreFormat(List<JobMatchResponse.FormatCheck> checks) {
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

    private int weightedAverage(List<JobMatchResponse.CategoryScore> categories) {
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

    private List<JobMatchResponse.PrioritizedRecommendation> buildRecommendations(
            List<String> missingKeywords,
            List<String> technicalKeywords,
            List<String> softSkillKeywords,
            List<JobMatchResponse.FormatCheck> formatChecks,
            List<String> qualityWarnings,
            List<JobMatchResponse.CategoryScore> categories
    ) {
        List<JobMatchResponse.PrioritizedRecommendation> recommendations = new ArrayList<>();

        if (!missingKeywords.isEmpty()) {
            recommendations.add(JobMatchResponse.PrioritizedRecommendation.builder()
                    .priority(1)
                    .title("Ajouter les mots-clés manquants")
                    .description("Réinjectez les termes prioritaires dans le résumé, les expériences ou les compétences : "
                            + String.join(", ", firstItems(missingKeywords, 5)) + ".")
                    .keywords(firstItems(missingKeywords, 5))
                    .build());
        }

        if (!technicalKeywords.isEmpty()) {
            recommendations.add(JobMatchResponse.PrioritizedRecommendation.builder()
                    .priority(2)
                    .title("Rendre les compétences techniques visibles")
                    .description("Placez les outils et stack demandés dans un bloc compétences explicite et dans les expériences associées.")
                    .keywords(firstItems(technicalKeywords, 5))
                    .build());
        }

        if (!formatChecks.isEmpty()) {
            JobMatchResponse.FormatCheck topRisk = formatChecks.get(0);
            recommendations.add(JobMatchResponse.PrioritizedRecommendation.builder()
                    .priority(3)
                    .title("Sécuriser le format ATS")
                    .description(topRisk.getDetail())
                    .keywords(List.of(topRisk.getLabel()))
                    .build());
        }

        if (!qualityWarnings.isEmpty()) {
            recommendations.add(JobMatchResponse.PrioritizedRecommendation.builder()
                    .priority(4)
                    .title("Renforcer les preuves dans les expériences")
                    .description(qualityWarnings.getFirst())
                    .keywords(List.of("résultats", "missions", "chiffres"))
                    .build());
        }

        boolean weakSoftSkills = categories.stream()
                .anyMatch(category -> "soft_skills".equals(category.getKey()) && category.getScore() < 60);
        if (weakSoftSkills && !softSkillKeywords.isEmpty()) {
            recommendations.add(JobMatchResponse.PrioritizedRecommendation.builder()
                    .priority(5)
                    .title("Appuyer les soft skills demandées")
                    .description("Montrez où vous avez exercé ces qualités dans des situations concrètes.")
                    .keywords(firstItems(softSkillKeywords, 4))
                    .build());
        }

        return recommendations.stream()
                .sorted((left, right) -> Integer.compare(left.getPriority(), right.getPriority()))
                .limit(properties.maxRecommendations())
                .toList();
    }

    private List<String> buildFallbackSuggestions(
            List<String> missingKeywords,
            List<JobMatchResponse.FormatCheck> formatChecks,
            List<String> qualityWarnings
    ) {
        LinkedHashSet<String> suggestions = new LinkedHashSet<>();
        if (!missingKeywords.isEmpty()) {
            suggestions.add("Ajoutez dans le résumé et les expériences : " + String.join(", ", firstItems(missingKeywords, 4)) + ".");
        }
        if (!formatChecks.isEmpty()) {
            suggestions.add(formatChecks.get(0).getDetail());
        }
        qualityWarnings.stream().limit(2).forEach(suggestions::add);
        if (suggestions.isEmpty()) {
            suggestions.add("Le score est exploitable, mais vous pouvez encore créer une variante optimisée pour mieux cibler l'offre.");
        }
        return suggestions.stream().limit(properties.maxFallbackSuggestions()).toList();
    }

    private List<String> mergeSuggestions(List<String> aiSuggestions, List<String> fallbackSuggestions) {
        LinkedHashSet<String> merged = new LinkedHashSet<>();
        aiSuggestions.stream()
                .map(String::trim)
                .filter(value -> !value.isBlank())
                .forEach(merged::add);
        fallbackSuggestions.forEach(merged::add);
        return merged.stream().limit(properties.maxSuggestions()).toList();
    }

    private List<String> mergeKeywords(List<String> aiKeywords, List<String> detectedKeywords) {
        LinkedHashSet<String> merged = new LinkedHashSet<>();
        aiKeywords.stream()
                .map(this::cleanKeyword)
                .filter(value -> !value.isBlank())
                .forEach(merged::add);
        detectedKeywords.stream()
                .map(this::cleanKeyword)
                .filter(value -> !value.isBlank())
                .forEach(merged::add);
        return merged.stream().limit(properties.maxKeywords()).toList();
    }

    private LinkedHashSet<String> extractKeywords(String jobDescription) {
        LinkedHashSet<String> keywords = new LinkedHashSet<>();
        Matcher matcher = WORD_PATTERN.matcher(normalize(jobDescription));
        while (matcher.find()) {
            String token = matcher.group();
            if (token.length() < 4 || STOP_WORDS.contains(token)) {
                continue;
            }
            keywords.add(token);
        }
        return keywords;
    }

    private boolean isTechnicalKeyword(String keyword) {
        return TECH_HINTS.contains(keyword)
                || keyword.matches(".*\\d.*")
                || keyword.contains("+")
                || keyword.contains("#")
                || keyword.contains("sql");
    }

    private boolean isSoftSkillKeyword(String keyword) {
        return SOFT_SKILL_TERMS.contains(keyword);
    }

    private String extractJobTitle(String jobDescription) {
        String[] lines = jobDescription.split("\\R");
        for (String line : lines) {
            String trimmed = safe(line);
            if (trimmed.length() >= 5 && trimmed.length() <= 80) {
                return normalize(trimmed);
            }
        }
        return "";
    }

    private String collectCvText(Cv cv) {
        StringBuilder text = new StringBuilder();
        text.append(cv.getTitre()).append(' ');
        if (cv.getPersonalInfo() != null) {
            text.append(safe(cv.getPersonalInfo().getTitrePoste())).append(' ')
                    .append(safe(cv.getPersonalInfo().getResumeProfessionnel())).append(' ')
                    .append(safe(cv.getPersonalInfo().getVille())).append(' ')
                    .append(safe(cv.getPersonalInfo().getLinkedIn())).append(' ')
                    .append(safe(cv.getPersonalInfo().getPortfolio())).append(' ');
        }
        cv.getSkills().forEach(skill -> text.append(safe(skill.getNom())).append(' ')
                .append(safe(skill.getCategorie())).append(' '));
        cv.getExperiences().forEach(exp -> text.append(safe(exp.getPoste())).append(' ')
                .append(safe(exp.getEntreprise())).append(' ')
                .append(safe(exp.getDescription())).append(' '));
        cv.getEducations().forEach(education -> text.append(safe(education.getDiplome())).append(' ')
                .append(safe(education.getDomaine())).append(' ')
                .append(safe(education.getDescription())).append(' '));
        cv.getProjects().forEach(project -> text.append(safe(project.getNom())).append(' ')
                .append(safe(project.getTechnologies())).append(' ')
                .append(safe(project.getDescription())).append(' '));
        cv.getCertifications().forEach(certification -> text.append(safe(certification.getNom())).append(' ')
                .append(safe(certification.getOrganisme())).append(' '));
        cv.getLanguages().forEach(language -> text.append(safe(language.getLangue())).append(' ')
                .append(safe(language.getNiveau() != null ? language.getNiveau().name() : null)).append(' '));
        return text.toString();
    }

    private double estimateCvLength(Cv cv) {
        int sectionCount = cv.getExperiences().size() * 180
                + cv.getEducations().size() * 90
                + cv.getProjects().size() * 110
                + cv.getSkills().size() * 18
                + cv.getLanguages().size() * 18
                + safe(cv.getPersonalInfo() != null ? cv.getPersonalInfo().getResumeProfessionnel() : null).length();
        return sectionCount / 900.0;
    }

    private int ratioScore(int matched, int total) {
        if (total <= 0) {
            return 70;
        }
        return Math.max(0, Math.min(
                properties.maxScore(),
                (matched * properties.maxScore()) / total
        ));
    }

    private boolean containsTerm(String normalizedText, String keyword) {
        return Pattern.compile("(?<![\\p{L}\\p{N}])" + Pattern.quote(normalize(keyword)) + "(?![\\p{L}\\p{N}])")
                .matcher(normalizedText)
                .find();
    }

    private Set<String> tokenize(String normalizedText) {
        Matcher matcher = WORD_PATTERN.matcher(normalizedText);
        LinkedHashSet<String> tokens = new LinkedHashSet<>();
        while (matcher.find()) {
            String token = matcher.group();
            if (token.length() >= 3 && !STOP_WORDS.contains(token)) {
                tokens.add(token);
            }
        }
        return tokens;
    }

    private String normalize(String text) {
        if (text == null) {
            return "";
        }
        String normalized = Normalizer.normalize(text, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "")
                .toLowerCase(Locale.ROOT);
        return normalized.replaceAll("[^\\p{L}\\p{N}+.#/\\-\\s]", " ")
                .replaceAll("\\s+", " ")
                .trim();
    }

    private List<String> firstItems(List<String> values, int limit) {
        return values.stream()
                .map(this::safe)
                .filter(value -> !value.isBlank())
                .distinct()
                .limit(limit)
                .toList();
    }

    private String restoreSpacing(String normalized) {
        return normalized == null ? "" : normalized.trim().replaceAll("\\s+", " ");
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }

    private String cleanKeyword(String value) {
        return safe(value).replaceAll("^[\\p{Punct}\\s]+|[\\p{Punct}\\s]+$", "");
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private String buildMatchPrompt(Cv cv, String jobDescription) {
        StringBuilder sb = new StringBuilder();
        sb.append("Tu es un expert en recrutement et en optimisation de CV pour les ATS. ");
        sb.append("Analyse ce CV par rapport a cette offre d'emploi et donne un score de correspondance.\n\n");
        sb.append(AiPromptRules.FRANCOPHONE_MARKET_RULE);
        sb.append(AiPromptRules.ANTI_CLICHES_RULE);
        sb.append("Donne des suggestions courtes, concretes et directement actionnables. ");
        sb.append("Cite des mots-cles exacts quand c'est utile.\n\n");
        sb.append("Reponds EXACTEMENT dans ce format :\n\n");
        sb.append("SCORE: (nombre de 0 a 100)\n\n");
        sb.append("MOTS_CLES_PRESENTS:\n- mot1\n- mot2\n\n");
        sb.append("MOTS_CLES_MANQUANTS:\n- mot1\n- mot2\n\n");
        sb.append("SUGGESTIONS:\n- suggestion1\n- suggestion2\n- suggestion3\n\n");
        sb.append("RESUME_OPTIMISE:\n(resume professionnel reecrit pour correspondre a cette offre)\n\n");

        sb.append("---\nOFFRE D'EMPLOI :\n").append(jobDescription).append("\n\n");

        sb.append("---\nCV DU CANDIDAT :\n");
        if (cv.getPersonalInfo() != null) {
            sb.append("Poste : ").append(safe(cv.getPersonalInfo().getTitrePoste())).append("\n");
            sb.append("Resume : ").append(safe(cv.getPersonalInfo().getResumeProfessionnel())).append("\n");
            sb.append("Ville : ").append(safe(cv.getPersonalInfo().getVille())).append("\n\n");
        }
        sb.append("Competences : ");
        sb.append(cv.getSkills().stream().map(skill -> safe(skill.getNom())).collect(Collectors.joining(", ")));
        sb.append("\n\nExperiences :\n");
        for (Experience exp : cv.getExperiences()) {
            sb.append("- ").append(safe(exp.getPoste())).append(" chez ").append(safe(exp.getEntreprise()));
            sb.append(" : ").append(safe(exp.getDescription()).isBlank() ? "(vide)" : safe(exp.getDescription())).append("\n");
        }

        if (!cv.getEducations().isEmpty()) {
            sb.append("\nFormations :\n");
            for (Education education : cv.getEducations()) {
                sb.append("- ").append(safe(education.getDiplome())).append(" / ")
                        .append(safe(education.getDomaine())).append("\n");
            }
        }

        if (!cv.getProjects().isEmpty()) {
            sb.append("\nProjets :\n");
            for (Project project : cv.getProjects()) {
                sb.append("- ").append(safe(project.getNom())).append(" : ")
                        .append(safe(project.getTechnologies())).append(" / ")
                        .append(safe(project.getDescription())).append("\n");
            }
        }

        if (!cv.getCertifications().isEmpty()) {
            sb.append("\nCertifications :\n");
            for (Certification certification : cv.getCertifications()) {
                sb.append("- ").append(safe(certification.getNom())).append("\n");
            }
        }

        if (!cv.getLanguages().isEmpty()) {
            sb.append("\nLangues :\n");
            for (Language language : cv.getLanguages()) {
                sb.append("- ").append(safe(language.getLangue())).append(" : ")
                        .append(safe(language.getNiveau() != null ? language.getNiveau().name() : null)).append("\n");
            }
        }

        return sb.toString();
    }

    private record MatchAnalysis(
            int globalScore,
            List<String> matchedKeywords,
            List<String> missingKeywords,
            List<String> suggestions,
            List<JobMatchResponse.CategoryScore> categories,
            List<JobMatchResponse.PrioritizedRecommendation> recommendations,
            List<JobMatchResponse.FormatCheck> formatChecks
    ) {
    }
}
