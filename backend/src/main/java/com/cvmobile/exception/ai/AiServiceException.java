package com.cvmobile.exception.ai;

/**
 * Base pour toutes les exceptions du sous-systeme IA.
 * Chaque sous-classe porte un errorCode stable utilise cote Flutter
 * pour afficher un message precis (remplace l'ancien "Mode hors ligne" trompeur).
 */
public abstract class AiServiceException extends RuntimeException {

    private final String providerName;
    private final String errorCode;
    private final Integer retryAfterSeconds;

    protected AiServiceException(String providerName, String errorCode,
                                 String message, Throwable cause,
                                 Integer retryAfterSeconds) {
        super(message, cause);
        this.providerName = providerName;
        this.errorCode = errorCode;
        this.retryAfterSeconds = retryAfterSeconds;
    }

    public String getProviderName() { return providerName; }
    public String getErrorCode() { return errorCode; }
    public Integer getRetryAfterSeconds() { return retryAfterSeconds; }
}
