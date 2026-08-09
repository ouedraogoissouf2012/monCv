package com.cvmobile.service.auth;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * Implementation par defaut (mail desactive) : simule l'envoi en journalisant
 * uniquement un email masque (issue #381). Active tant que {@code mail.enabled}
 * n'est pas {@code true} ; l'envoi SMTP reel viendra dans une PR dediee.
 *
 * Ne journalise JAMAIS le jeton en clair (OWASP).
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "mail.enabled", havingValue = "false", matchIfMissing = true)
public class LoggingPasswordResetEmailSender implements PasswordResetEmailSender {

    @Override
    public void sendResetLink(String email, String rawToken) {
        log.info("Email de reinitialisation (envoi simule, mail desactive) pour {}",
                maskEmail(email));
    }

    private String maskEmail(String email) {
        int at = email.indexOf('@');
        if (at <= 1) {
            return "***";
        }
        return email.charAt(0) + "***" + email.substring(at);
    }
}
