package com.cvmobile.service.auth;

/**
 * Port d'envoi de l'email de reinitialisation de mot de passe (issue #381).
 *
 * L'implementation par defaut ({@link LoggingPasswordResetEmailSender}) simule
 * l'envoi ; l'envoi SMTP reel est fourni par une PR dediee (activation via
 * {@code mail.enabled=true}). Le jeton en clair ne doit JAMAIS etre journalise.
 */
public interface PasswordResetEmailSender {

    /**
     * Envoie a [email] un lien contenant le jeton [rawToken] en clair (le seul
     * endroit ou il transite en clair, jamais persiste ni logge).
     */
    void sendResetLink(String email, String rawToken);
}
