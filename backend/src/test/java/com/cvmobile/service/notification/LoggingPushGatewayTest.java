package com.cvmobile.service.notification;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class LoggingPushGatewayTest {

    private ListAppender<ILoggingEvent> attachAppender() {
        Logger logger = (Logger) LoggerFactory.getLogger(LoggingPushGateway.class);
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        logger.addAppender(appender);
        return appender;
    }

    @Test
    void send_journaliseLeSuffixeDuTokenSansSonPrefixe_etRetourneTrue() {
        ListAppender<ILoggingEvent> appender = attachAppender();

        boolean sent = new LoggingPushGateway().send(
                "prefixe-secret-ABCDEF", "Titre", "Corps", Map.of("cle", "valeur"));

        assertThat(sent).isTrue();
        String logged = appender.list.get(0).getFormattedMessage();
        assertThat(logged)
                .contains("ABCDEF") // 6 derniers caracteres
                .contains("Titre")
                .doesNotContain("prefixe-secret"); // le prefixe n'est jamais logge
    }

    @Test
    void send_tokenPlusCourtQueSixCaracteres_neLevePasEtRetourneTrue() {
        attachAppender();

        boolean sent = new LoggingPushGateway().send("abc", "T", "B", Map.of());

        // Math.max(0, len-6) protege le substring : aucun IndexOutOfBounds.
        assertThat(sent).isTrue();
    }
}
