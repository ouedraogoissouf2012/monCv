package com.cvmobile.service.auth;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;

import static org.assertj.core.api.Assertions.assertThat;

class LoggingPasswordResetEmailSenderTest {

    private ListAppender<ILoggingEvent> attachAppender() {
        Logger logger =
                (Logger) LoggerFactory.getLogger(LoggingPasswordResetEmailSender.class);
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        logger.addAppender(appender);
        return appender;
    }

    @Test
    void sendResetLink_journaliseUnEmailMasqueSansLeJeton() {
        ListAppender<ILoggingEvent> appender = attachAppender();

        new LoggingPasswordResetEmailSender()
                .sendResetLink("john@example.com", "secret-token-123");

        String logged = appender.list.get(0).getFormattedMessage();
        assertThat(logged)
                .contains("j***@example.com")
                .doesNotContain("secret-token-123");
    }

    @Test
    void sendResetLink_masqueEntierementUnEmailTresCourt() {
        ListAppender<ILoggingEvent> appender = attachAppender();

        new LoggingPasswordResetEmailSender().sendResetLink("a@b.c", "secret");

        assertThat(appender.list.get(0).getFormattedMessage())
                .contains("***")
                .doesNotContain("secret");
    }
}
