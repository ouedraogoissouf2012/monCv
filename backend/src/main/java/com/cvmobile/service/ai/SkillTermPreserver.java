package com.cvmobile.service.ai;

import java.text.Normalizer;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;

final class SkillTermPreserver {

    private static final List<String> CONNECTORS = List.of("et", "and", "de", "des", "du");

    private SkillTermPreserver() {
    }

    static boolean isReformulationOf(String original, String candidate) {
        List<String> originalTokens = tokens(original);
        List<String> candidateTokens = tokens(candidate);
        if (originalTokens.isEmpty() || candidateTokens.isEmpty()) {
            return false;
        }
        if (candidateTokens.size() > originalTokens.size()) {
            return false;
        }
        return preserves(original, candidate) || preserves(candidate, original);
    }

    static boolean preserves(String original, String candidate) {
        List<String> originalTokens = tokens(original);
        List<String> candidateTokens = tokens(candidate);
        if (originalTokens.isEmpty() || candidateTokens.size() < originalTokens.size()) return false;

        int candidateIndex = 0;
        for (String originalToken : originalTokens) {
            boolean matched = false;
            while (candidateIndex < candidateTokens.size()) {
                String candidateToken = candidateTokens.get(candidateIndex++);
                int tolerance = Math.max(1, originalToken.length() / 4);
                if (originalToken.charAt(0) == candidateToken.charAt(0)
                        && editDistance(originalToken, candidateToken) <= tolerance) {
                    matched = true;
                    break;
                }
            }
            if (!matched) return false;
        }
        return true;
    }

    private static List<String> tokens(String value) {
        if (value == null || value.isBlank()) return List.of();
        String normalized = Normalizer.normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT);
        return Arrays.stream(normalized.split("[^\\p{L}\\p{N}+#/.]+"))
                .filter(token -> !token.isBlank())
                .filter(token -> !CONNECTORS.contains(token))
                .toList();
    }

    private static int editDistance(String left, String right) {
        int[] previous = new int[right.length() + 1];
        for (int j = 0; j <= right.length(); j++) previous[j] = j;
        for (int i = 1; i <= left.length(); i++) {
            int[] current = new int[right.length() + 1];
            current[0] = i;
            for (int j = 1; j <= right.length(); j++) {
                int substitution = previous[j - 1]
                        + (left.charAt(i - 1) == right.charAt(j - 1) ? 0 : 1);
                current[j] = Math.min(Math.min(current[j - 1] + 1, previous[j] + 1), substitution);
            }
            previous = current;
        }
        return previous[right.length()];
    }
}
