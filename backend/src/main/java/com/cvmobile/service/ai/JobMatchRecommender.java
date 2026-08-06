package com.cvmobile.service.ai;

import com.cvmobile.config.JobMatchProperties;
import com.cvmobile.dto.JobMatchResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;

/**
 * Construit les recommandations priorisees et les suggestions du matching, et
 * fusionne les listes IA + deterministes (issue #257). Extrait de
 * {@code JobMatchServiceImpl}.
 */
@Component
@RequiredArgsConstructor
public class JobMatchRecommender {

    private final JobMatchTextAnalyzer text;
    private final JobMatchProperties properties;

    public List<JobMatchResponse.PrioritizedRecommendation> buildRecommendations(
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
                            + String.join(", ", text.firstItems(missingKeywords, 5)) + ".")
                    .keywords(text.firstItems(missingKeywords, 5))
                    .build());
        }

        if (!technicalKeywords.isEmpty()) {
            recommendations.add(JobMatchResponse.PrioritizedRecommendation.builder()
                    .priority(2)
                    .title("Rendre les compétences techniques visibles")
                    .description("Placez les outils et stack demandés dans un bloc compétences explicite et dans les expériences associées.")
                    .keywords(text.firstItems(technicalKeywords, 5))
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
                    .keywords(text.firstItems(softSkillKeywords, 4))
                    .build());
        }

        return recommendations.stream()
                .sorted((left, right) -> Integer.compare(left.getPriority(), right.getPriority()))
                .limit(properties.maxRecommendations())
                .toList();
    }

    public List<String> buildFallbackSuggestions(
            List<String> missingKeywords,
            List<JobMatchResponse.FormatCheck> formatChecks,
            List<String> qualityWarnings
    ) {
        LinkedHashSet<String> suggestions = new LinkedHashSet<>();
        if (!missingKeywords.isEmpty()) {
            suggestions.add("Ajoutez dans le résumé et les expériences : " + String.join(", ", text.firstItems(missingKeywords, 4)) + ".");
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

    public List<String> mergeSuggestions(List<String> aiSuggestions, List<String> fallbackSuggestions) {
        LinkedHashSet<String> merged = new LinkedHashSet<>();
        aiSuggestions.stream()
                .map(String::trim)
                .filter(value -> !value.isBlank())
                .forEach(merged::add);
        fallbackSuggestions.forEach(merged::add);
        return merged.stream().limit(properties.maxSuggestions()).toList();
    }

    public List<String> mergeKeywords(List<String> aiKeywords, List<String> detectedKeywords) {
        LinkedHashSet<String> merged = new LinkedHashSet<>();
        aiKeywords.stream()
                .map(text::cleanKeyword)
                .filter(value -> !value.isBlank())
                .forEach(merged::add);
        detectedKeywords.stream()
                .map(text::cleanKeyword)
                .filter(value -> !value.isBlank())
                .forEach(merged::add);
        return merged.stream().limit(properties.maxKeywords()).toList();
    }
}
