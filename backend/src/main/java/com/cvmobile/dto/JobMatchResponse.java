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
    private String optimizedResume;           // Resume optimise pour cette offre
    private boolean aiGenerated;
}
