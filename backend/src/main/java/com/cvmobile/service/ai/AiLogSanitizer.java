package com.cvmobile.service.ai;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

public final class AiLogSanitizer {

    private AiLogSanitizer() {
    }

    public static String summarize(String payload) {
        String safePayload = payload == null ? "" : payload;
        return "chars=" + safePayload.length() + ", sha256=" + sha256(safePayload);
    }

    private static String sha256(String payload) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(payload.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (int i = 0; i < 12 && i < hash.length; i++) {
                hex.append(String.format("%02x", hash[i]));
            }
            return hex.toString();
        } catch (Exception e) {
            return "unavailable";
        }
    }
}
