package com.cvmobile.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class JobMatchResponse {
    private int score;                        // 0-100%
    private List<String> matchedKeywords;     // Mots-cles presents dans le CV
    private List<String> missingKeywords;     // Mots-cles absents du CV
    private List<String> suggestions;         // Suggestions pour ameliorer le match
    private List<CategoryScore> categories;   // Detail du score ATS par categorie
    private List<PrioritizedRecommendation> prioritizedRecommendations;
    private List<FormatCheck> formatChecks;
    private String optimizedResume;           // Resume optimise pour cette offre
    private boolean aiGenerated;
    private boolean fallback;

    @Data
    @Builder
    public static class CategoryScore {
        private String key;
        private String label;
        private int score;
        private String summary;
        private List<String> evidence;
    }

    @Data
    @Builder
    public static class PrioritizedRecommendation {
        private int priority;
        private String title;
        private String description;
        private List<String> keywords;
    }

    @Data
    @Builder
    public static class FormatCheck {
        private String severity;
        private String label;
        private String detail;
    }
}
