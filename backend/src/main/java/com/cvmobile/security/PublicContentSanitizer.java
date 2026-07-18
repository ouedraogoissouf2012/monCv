package com.cvmobile.security;

import org.springframework.stereotype.Component;

@Component
public final class PublicContentSanitizer {
    public String text(String value, int maxCodePoints) {
        if (value == null) return null;

        StringBuilder sanitized = new StringBuilder(Math.min(value.length(), maxCodePoints));
        int kept = 0;
        for (int offset = 0; offset < value.length() && kept < maxCodePoints; ) {
            int codePoint = value.codePointAt(offset);
            offset += Character.charCount(codePoint);
            if (isAllowed(codePoint)) {
                sanitized.appendCodePoint(codePoint);
                kept++;
            }
        }
        return sanitized.toString();
    }

    private boolean isAllowed(int codePoint) {
        if (codePoint == '\n' || codePoint == '\r' || codePoint == '\t') return true;
        if (Character.isISOControl(codePoint)) return false;
        boolean bidiOverride = codePoint >= 0x202A && codePoint <= 0x202E;
        boolean bidiIsolate = codePoint >= 0x2066 && codePoint <= 0x2069;
        return !bidiOverride && !bidiIsolate;
    }
}
