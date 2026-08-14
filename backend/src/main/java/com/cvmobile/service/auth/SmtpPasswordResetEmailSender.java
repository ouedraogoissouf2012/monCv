package com.cvmobile.service.auth;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

/**
 * Implementation SMTP reelle de l'envoi du lien de reinitialisation (issue #381).
 * Active uniquement via {@code mail.enabled=true} ; sinon {@link LoggingPasswordResetEmailSender}
 * simule l'envoi.
 *
 * Ne journalise JAMAIS le jeton en clair (OWASP) : seul un email masque apparait dans les logs,
 * y compris en cas d'echec d'envoi.
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "mail.enabled", havingValue = "true")
public class SmtpPasswordResetEmailSender implements PasswordResetEmailSender {

    private static final String RESET_PATH = "/#/reset-password/";
    private static final String SUBJECT = "Réinitialisation de votre mot de passe MonCV";

    private final JavaMailSender mailSender;
    private final String frontendUrl;
    private final String fromAddress;

    public SmtpPasswordResetEmailSender(
            JavaMailSender mailSender,
            @Value("${app.frontend-url}") String frontendUrl,
            @Value("${mail.from}") String fromAddress) {
        this.mailSender = mailSender;
        this.frontendUrl = frontendUrl;
        this.fromAddress = fromAddress;
    }

    @Override
    public void sendResetLink(String email, String rawToken) {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromAddress);
        message.setTo(email);
        message.setSubject(SUBJECT);
        message.setText(buildBody(frontendUrl + RESET_PATH + rawToken));

        try {
            mailSender.send(message);
        } catch (MailException exception) {
            // L'echec d'envoi ne doit jamais remonter : la reponse du controleur reste uniforme
            // (anti-enumeration d'emails, voir PasswordResetService). L'incident reste visible
            // via ce log d'erreur : email masque + type d'exception seulement. On NE journalise
            // PAS l'exception brute — un MailSendException peut contenir l'adresse destinataire
            // en clair (PII) et jamais le jeton.
            log.error("Echec de l'envoi de l'email de reinitialisation pour {} (cause: {})",
                    maskEmail(email), exception.getClass().getSimpleName());
            return;
        }
        log.info("Email de reinitialisation envoye pour {}", maskEmail(email));
    }

    private String buildBody(String resetLink) {
        return """
                Vous avez demandé la réinitialisation de votre mot de passe MonCV.

                Cliquez sur le lien suivant pour choisir un nouveau mot de passe (valide 30 minutes) :
                %s

                Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.
                """.formatted(resetLink);
    }

    private String maskEmail(String email) {
        int at = email.indexOf('@');
        if (at <= 1) {
            return "***";
        }
        return email.charAt(0) + "***" + email.substring(at);
    }
}
