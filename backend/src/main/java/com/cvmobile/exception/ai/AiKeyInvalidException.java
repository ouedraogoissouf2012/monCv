package com.cvmobile.exception.ai;

/**
 * Levee quand le provider IA rejette la cle API (HTTP 401).
 * Non retryable. Ne doit PAS declencher le fallback vers MockAiClient
 * car c'est un probleme de configuration a resoudre.
 * Cote HTTP : 503 + code "AI_KEY_INVALID".
 */
public class AiKeyInvalidException extends AiServiceException {

    public AiKeyInvalidException(String provider, Throwable cause) {
        super(provider, "AI_KEY_INVALID",
                "La cle API du fournisseur " + provider + " est invalide ou expiree.",
                cause, null);
    }
}
