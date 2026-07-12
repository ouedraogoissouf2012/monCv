package com.cvmobile.exception.ai;

/**
 * Levee quand le provider IA retourne 429 (rate limit / quota).
 * Non retryable immediate. Le Retry-After header propage via HTTP 503.
 * Ne doit PAS declencher le fallback — on veut que l'utilisateur sache.
 */
public class AiQuotaExceededException extends AiServiceException {

    public AiQuotaExceededException(String provider, Integer retryAfterSeconds, Throwable cause) {
        super(provider, "AI_QUOTA_EXCEEDED",
                "Limite d'usage atteinte pour le fournisseur " + provider + ".",
                cause, retryAfterSeconds);
    }
}
