package com.cvmobile.service.auth;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.slf4j.LoggerFactory;
import org.springframework.mail.MailSendException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class SmtpPasswordResetEmailSenderTest {

    private static final String FRONTEND_URL = "https://moncv.app";
    private static final String FROM_ADDRESS = "no-reply@moncv.app";
    private static final String RAW_TOKEN = "secret-token-123";

    private JavaMailSender mailSender;
    private SmtpPasswordResetEmailSender sender;

    @BeforeEach
    void setUp() {
        mailSender = mock(JavaMailSender.class);
        sender = new SmtpPasswordResetEmailSender(mailSender, FRONTEND_URL, FROM_ADDRESS);
    }

    private ListAppender<ILoggingEvent> attachAppender() {
        Logger logger =
                (Logger) LoggerFactory.getLogger(SmtpPasswordResetEmailSender.class);
        ListAppender<ILoggingEvent> appender = new ListAppender<>();
        appender.start();
        logger.addAppender(appender);
        return appender;
    }

    @Test
    void sendResetLink_envoieUnEmailContenantLeLienDeReinitialisation() {
        sender.sendResetLink("john@example.com", RAW_TOKEN);

        ArgumentCaptor<SimpleMailMessage> captor = ArgumentCaptor.forClass(SimpleMailMessage.class);
        verify(mailSender).send(captor.capture());

        SimpleMailMessage sent = captor.getValue();
        assertThat(sent.getFrom()).isEqualTo(FROM_ADDRESS);
        assertThat(sent.getTo()).containsExactly("john@example.com");
        assertThat(sent.getText()).contains(FRONTEND_URL + "/#/reset-password/" + RAW_TOKEN);
    }

    @Test
    void sendResetLink_journaliseUnEmailMasqueSansLeJetonEnCasDeSucces() {
        ListAppender<ILoggingEvent> appender = attachAppender();

        sender.sendResetLink("john@example.com", RAW_TOKEN);

        String logged = appender.list.get(0).getFormattedMessage();
        assertThat(logged)
                .contains("j***@example.com")
                .doesNotContain(RAW_TOKEN);
    }

    @Test
    void sendResetLink_nAvorteJamaisEtNeFuitNiJetonNiEmailEnClairQuandLEnvoiEchoue() {
        ListAppender<ILoggingEvent> appender = attachAppender();
        // Un MailSendException reel embarque frequemment l'adresse destinataire en
        // clair : on verifie qu'elle ne fuite pas dans les logs (PII).
        doThrow(new MailSendException("Invalid Addresses: john@example.com"))
                .when(mailSender).send(any(SimpleMailMessage.class));

        sender.sendResetLink("john@example.com", RAW_TOKEN);

        ILoggingEvent event = appender.list.get(0);
        assertThat(event.getFormattedMessage())
                .contains("j***@example.com")        // email masque pour le triage
                .contains("MailSendException")        // type d'incident, pas le detail brut
                .doesNotContain(RAW_TOKEN)            // jamais le jeton
                .doesNotContain("john@example.com");  // jamais l'email en clair (PII)
        // L'exception brute n'est jamais journalisee (sa stacktrace/message peut contenir la PII).
        assertThat(event.getThrowableProxy()).isNull();
    }

    @Test
    void sendResetLink_masqueEntierementUnEmailTresCourt() {
        ListAppender<ILoggingEvent> appender = attachAppender();

        sender.sendResetLink("a@b.c", RAW_TOKEN);

        assertThat(appender.list.get(0).getFormattedMessage())
                .contains("***")
                .doesNotContain(RAW_TOKEN);
    }
}
