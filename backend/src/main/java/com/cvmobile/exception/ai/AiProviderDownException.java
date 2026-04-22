package com.cvmobile.exception.ai;

/**
 * Levee quand le provider IA est temporairement indisponible :
 * - HTTP 5xx
 * - Connexion refusee
 * - Socket reset
 * - Circuit breaker ouvert
 *
 * Retryable et declenche le fallback via CompositeAiClient.
 * Cote HTTP : 503 + code "AI_PROVIDER_DOWN".
 */
public class AiProviderDownException extends AiServiceException {

    public AiProviderDownException(String provider, String detail, Throwable cause) {
        super(provider, "AI_PROVIDER_DOWN",
                "Fournisseur " + provider + " temporairement indisponible : " + detail,
                cause, null);
    }

    protected AiProviderDownException(String provider, String errorCode, String message, Throwable cause) {
        super(provider, errorCode, message, cause, null);
    }
}
