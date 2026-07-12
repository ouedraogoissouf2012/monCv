package com.cvmobile.exception.ai;

/**
 * Sous-cas particulier de AiProviderDownException : timeout.
 * Code distinct pour afficher un message UX specifique cote Flutter
 * ("le service IA met trop de temps a repondre").
 * Cote HTTP : 504 Gateway Timeout + code "AI_TIMEOUT".
 */
public class AiTimeoutException extends AiProviderDownException {

    public AiTimeoutException(String provider, Throwable cause) {
        super(provider, "AI_TIMEOUT",
                "Fournisseur " + provider + " : timeout",
                cause);
    }
}
