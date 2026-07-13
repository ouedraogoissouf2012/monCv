package com.cvmobile.observability;

import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.LoggerContext;
import ch.qos.logback.classic.spi.LoggingEvent;
import net.logstash.logback.encoder.LogstashEncoder;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class LogbackJsonEncoderTest {

    @Test
    void jsonEncoderIncludesCorrelationIdFromMdc() {
        LoggerContext context = new LoggerContext();
        LogstashEncoder encoder = new LogstashEncoder();
        encoder.setContext(context);
        encoder.setIncludeMdc(true);
        encoder.setIncludeContext(false);
        encoder.start();

        LoggingEvent event = new LoggingEvent();
        event.setLoggerName("com.cvmobile.observability.LogbackJsonEncoderTest");
        event.setLevel(Level.INFO);
        event.setMessage("probe");
        event.setThreadName("test-thread");
        event.setTimeStamp(System.currentTimeMillis());
        event.setMDCPropertyMap(Map.of("correlationId", "cid-123"));

        String json = new String(encoder.encode(event), StandardCharsets.UTF_8);

        assertThat(json).contains("\"correlationId\":\"cid-123\"");
    }
}
