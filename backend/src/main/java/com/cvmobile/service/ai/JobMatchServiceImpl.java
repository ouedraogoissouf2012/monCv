package com.cvmobile.service.ai;

import com.cvmobile.config.JobMatchProperties;
import com.cvmobile.dto.JobMatchResponse;
import com.cvmobile.model.Cv;
import com.cvmobile.service.CvQualityService;
import com.cvmobile.service.ai.client.IAiClient;
import com.cvmobile.service.cv.CvOwnershipService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Analyse de correspondance CV / offre d'emploi (issue #257).
 *
 * Orchestrateur : verifie la propriete du CV, appelle l'IA, puis assemble un
 * rapport deterministe a partir des collaborateurs specialises
 * ({@link JobMatchTextAnalyzer}, {@link JobMatchScorer},
 * {@link JobMatchFormatChecker}, {@link JobMatchRecommender},
 * {@link JobMatchPromptBuilder}). Combine le score IA et le score determine.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class JobMatchServiceImpl implements IJobMatchService {

    private static final Pattern SCORE_PATTERN = Pattern.compile("SCORE:\\s*(\\d+)");

    private final IAiClient aiClient;
    private final CvOwnershipService cvOwnershipService;
    private final CvQualityService cvQualityService;
    private final JobMatchProperties properties;
    private final JobMatchTextAnalyzer text;
    private final JobMatchScorer scorer;
    private final JobMatchFormatChecker formatChecker;
    private final JobMatchRecommender recommender;
    private final JobMatchPromptBuilder promptBuilder;

    @Override
    public JobMatchResponse matchJob(Long cvId, Long userId, String jobDescription) {
        Cv cv = cvOwnershipService.requireOwnedCv(cvId, userId);
        return analyzeMatch(cv, jobDescription);
    }

    private JobMatchResponse analyzeMatch(Cv cv, String jobDescription) {
        String prompt = promptBuilder.buildMatchPrompt(cv, jobDescription);
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
        String normalizedCvText = text.normalize(text.collectCvText(cv));
        LinkedHashSet<String> extractedKeywords = text.extractKeywords(jobDescription);

        List<String> matchedKeywords = recommender.mergeKeywords(
                aiMatched,
                extractedKeywords.stream()
                        .filter(keyword -> text.containsTerm(normalizedCvText, keyword))
                        .toList()
        );

        List<String> missingKeywords = recommender.mergeKeywords(
                aiMissing,
                extractedKeywords.stream()
                        .filter(keyword -> !text.containsTerm(normalizedCvText, keyword))
                        .toList()
        );

        List<String> technicalKeywords = extractedKeywords.stream()
                .filter(text::isTechnicalKeyword)
                .toList();
        List<String> softSkillKeywords = extractedKeywords.stream()
                .filter(text::isSoftSkillKeyword)
                .toList();

        List<JobMatchResponse.FormatCheck> formatChecks = formatChecker.buildFormatChecks(cv);
        List<String> qualityWarnings = cvQualityService.findReviewWarnings(cv);

        JobMatchResponse.CategoryScore keywordCategory = scorer.buildCategory(
                "keywords",
                "Mots-clés ATS",
                scorer.ratioScore(matchedKeywords.size(), matchedKeywords.size() + missingKeywords.size()),
                matchedKeywords.isEmpty()
                        ? "Le CV ne reprend pas encore les termes les plus visibles de l'offre."
                        : "Les mots-clés repris correspondent partiellement au vocabulaire demandé.",
                text.firstItems(missingKeywords.isEmpty() ? matchedKeywords : missingKeywords, 4)
        );

        JobMatchResponse.CategoryScore technicalCategory = scorer.buildCategory(
                "technical_skills",
                "Compétences techniques",
                scorer.scoreTechnicalSkills(cv, technicalKeywords),
                technicalKeywords.isEmpty()
                        ? "L'offre contient peu de marqueurs techniques explicites."
                        : "Les compétences techniques visibles dans le CV couvrent une partie des attentes.",
                text.firstItems(technicalKeywords, 4)
        );

        JobMatchResponse.CategoryScore softCategory = scorer.buildCategory(
                "soft_skills",
                "Soft skills",
                scorer.scoreSoftSkills(cv, softSkillKeywords),
                softSkillKeywords.isEmpty()
                        ? "L'offre décrit surtout des attendus métier."
                        : "Les qualités relationnelles ou de coordination sont partiellement visibles.",
                text.firstItems(softSkillKeywords, 4)
        );

        JobMatchResponse.CategoryScore titleCategory = scorer.buildCategory(
                "job_title",
                "Intitulé du poste",
                scorer.scoreTitleMatch(cv, jobDescription),
                scorer.buildTitleSummary(cv, jobDescription),
                List.of(text.safe(cv.getPersonalInfo() != null ? cv.getPersonalInfo().getTitrePoste() : null))
        );

        JobMatchResponse.CategoryScore experienceCategory = scorer.buildCategory(
                "experience",
                "Expérience",
                scorer.scoreExperience(cv, jobDescription),
                scorer.buildExperienceSummary(cv),
                text.firstItems(qualityWarnings, 3)
        );

        JobMatchResponse.CategoryScore educationCategory = scorer.buildCategory(
                "education",
                "Formation",
                scorer.scoreEducation(cv, jobDescription),
                scorer.buildEducationSummary(cv, jobDescription),
                scorer.buildEducationEvidence(cv, jobDescription)
        );

        JobMatchResponse.CategoryScore formatCategory = scorer.buildCategory(
                "ats_format",
                "Format ATS",
                formatChecker.scoreFormat(formatChecks),
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

        int weightedScore = scorer.weightedAverage(categories);
        int globalScore = Math.max(0, Math.min(properties.maxScore(), (weightedScore + aiScore) / 2));

        List<String> suggestions = recommender.mergeSuggestions(
                aiSuggestions,
                recommender.buildFallbackSuggestions(missingKeywords, formatChecks, qualityWarnings)
        );

        List<JobMatchResponse.PrioritizedRecommendation> recommendations = recommender.buildRecommendations(
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
            try {
                return Math.min(properties.maxScore(), Integer.parseInt(scoreMatcher.group(1)));
            } catch (NumberFormatException e) {
                // Output IA non fiable : un SCORE numeriquement invalide (ex. overflow
                // int) ne doit pas planter l'analyse -> on retombe sur le score par
                // defaut, le score deterministe restant maitre (M-8).
                log.warn("Score IA illisible (overflow), score par defaut applique");
            }
        }
        return properties.defaultScore();
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
