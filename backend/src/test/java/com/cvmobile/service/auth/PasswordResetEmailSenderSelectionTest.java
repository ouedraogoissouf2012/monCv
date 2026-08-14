package com.cvmobile.service.auth;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.mail.javamail.JavaMailSender;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

/**
 * Verifie le cablage conditionnel (issue #487) : c'est {@code mail.enabled} qui
 * choisit l'implementation de {@link PasswordResetEmailSender}, jamais les deux
 * a la fois. Defaut sur : le repli logging (aucun envoi reel sans activation
 * explicite).
 */
class PasswordResetEmailSenderSelectionTest {

    private final ApplicationContextRunner runner = new ApplicationContextRunner()
            .withUserConfiguration(SenderConfiguration.class)
            .withBean(JavaMailSender.class, () -> mock(JavaMailSender.class))
            .withPropertyValues(
                    "app.frontend-url=https://moncv.app",
                    "mail.from=no-reply@moncv.app");

    @Test
    void usesTheLoggingSenderWhenMailIsDisabledByDefault() {
        runner.run(context -> {
            assertThat(context).hasSingleBean(PasswordResetEmailSender.class);
            assertThat(context).hasSingleBean(LoggingPasswordResetEmailSender.class);
            assertThat(context).doesNotHaveBean(SmtpPasswordResetEmailSender.class);
        });
    }

    @Test
    void usesTheLoggingSenderWhenMailIsExplicitlyDisabled() {
        runner.withPropertyValues("mail.enabled=false").run(context -> {
            assertThat(context).hasSingleBean(PasswordResetEmailSender.class);
            assertThat(context).hasSingleBean(LoggingPasswordResetEmailSender.class);
            assertThat(context).doesNotHaveBean(SmtpPasswordResetEmailSender.class);
        });
    }

    @Test
    void usesTheSmtpSenderWhenMailIsEnabled() {
        runner.withPropertyValues("mail.enabled=true").run(context -> {
            assertThat(context).hasSingleBean(PasswordResetEmailSender.class);
            assertThat(context).hasSingleBean(SmtpPasswordResetEmailSender.class);
            assertThat(context).doesNotHaveBean(LoggingPasswordResetEmailSender.class);
        });
    }

    @Configuration(proxyBeanMethods = false)
    @Import({LoggingPasswordResetEmailSender.class, SmtpPasswordResetEmailSender.class})
    static class SenderConfiguration {
    }
}
