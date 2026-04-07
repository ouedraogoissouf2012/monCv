package com.cvmobile.service.ai;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Utilitaire pour parser les reponses structurees de l'IA.
 * Extrait des sections delimitees par des marqueurs (SCORE:, RESUME:, EXP_1:, etc.).
 */
public final class AiResponseParser {

    private AiResponseParser() {}

    /**
     * Extrait le contenu entre un marker et le prochain marker connu.
     */
    public static String extractBetweenMarkers(String content, String marker, List<String> allMarkers) {
        int start = content.indexOf(marker);
        if (start == -1) return "";
        int contentStart = start + marker.length();

        int nextMarker = content.length();
        for (String m : allMarkers) {
            if (m.equals(marker)) continue;
            int pos = content.indexOf(m, contentStart);
            if (pos != -1 && pos < nextMarker) nextMarker = pos;
        }
        int sep = content.indexOf("---", contentStart);
        if (sep != -1 && sep < nextMarker) nextMarker = sep;

        return content.substring(contentStart, nextMarker).strip();
    }

    /**
     * Extrait une section sous forme de liste (lignes prefixees par - ou *).
     */
    public static List<String> extractListSection(String content, String marker, List<String> allMarkers) {
        String section = extractBetweenMarkers(content, marker, allMarkers);
        if (section.isBlank()) return List.of();
        return Arrays.stream(section.split("\n"))
                .map(String::trim)
                .filter(l -> !l.isBlank())
                .map(l -> l.replaceAll("^[\\-\\*•]+\\s*", ""))
                .filter(l -> !l.isBlank())
                .collect(Collectors.toList());
    }

    /**
     * Parse des lignes de suggestions (nettoie numerotation, tirets, puces).
     */
    public static List<String> parseSuggestions(String content) {
        return Arrays.stream(content.split("\n"))
                .map(String::trim)
                .filter(line -> !line.isBlank())
                .map(line -> line.replaceAll("^[\\d•\\-–—*]+[.)]?\\s*", ""))
                .filter(line -> !line.isBlank())
                .limit(5)
                .collect(Collectors.toList());
    }
}
