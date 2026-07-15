package com.cvmobile.security;

import java.time.Duration;

public record RateLimitResult(
        boolean allowed,
        long remainingTokens,
        Duration retryAfter
) {
    public static RateLimitResult allowed(long remainingTokens) {
        return new RateLimitResult(true, remainingTokens, Duration.ZERO);
    }

    public static RateLimitResult rejected(Duration retryAfter) {
        return new RateLimitResult(false, 0, retryAfter);
    }
}
