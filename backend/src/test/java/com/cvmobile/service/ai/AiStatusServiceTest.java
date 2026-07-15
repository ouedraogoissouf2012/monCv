package com.cvmobile.service.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.cvmobile.dto.AiStatusResponse;
import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.service.ai.client.MockAiClient;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class AiStatusServiceTest {

    private CircuitBreaker circuitBreaker;
    private AiTelemetry telemetry;
    private AiStatusService service;

    @BeforeEach
    void setUp() {
        CircuitBreakerRegistry registry = CircuitBreakerRegistry.of(
                CircuitBreakerConfig.custom()
                        .minimumNumberOfCalls(2)
                        .slidingWindowSize(2)
                        .failureRateThreshold(50)
                        .build());
        circuitBreaker = registry.circuitBreaker("ai-deepseek");
        telemetry = new AiTelemetry();
        service = new AiStatusService(registry, telemetry);
        ReflectionTestUtils.setField(service, "deepSeekApiKey", "configured-key");
        ReflectionTestUtils.setField(service, "fallbackEnabled", true);
        ReflectionTestUtils.setField(service, "mockAiClient", new MockAiClient());
    }

    @Test
    void exposesCircuitTelemetryAndCachesResponse() {
        telemetry.recordSuccess(100, false);
        telemetry.recordSuccess(300, true);
        telemetry.recordLastError(
                new AiProviderDownException("deepseek", "HTTP 503", null));
        circuitBreaker.onError(10, java.util.concurrent.TimeUnit.MILLISECONDS,
                new IllegalStateException("provider down"));
        circuitBreaker.onSuccess(10, java.util.concurrent.TimeUnit.MILLISECONDS);

        AiStatusResponse first = service.currentStatus();
        AiStatusResponse cached = service.currentStatus();

        assertThat(first).isSameAs(cached);
        assertThat(first.isAvailable()).isTrue();
        assertThat(first.getCircuitBreakerState()).isEqualTo("OPEN");
        assertThat(first.getErrorRatePercent()).isEqualTo(50.0);
        assertThat(first.getLatencyP50Ms()).isEqualTo(100);
        assertThat(first.getLatencyP95Ms()).isEqualTo(300);
        assertThat(first.isFallbackInUse()).isTrue();
        assertThat(first.getLastError().getType()).isEqualTo("AI_PROVIDER_DOWN");
        assertThat(first.getCheckedAt()).isEqualTo(first.getLastChecked());
    }

    @Test
    void reportsUnavailableWhenProviderKeyIsMissingEvenIfMockExists() {
        ReflectionTestUtils.setField(service, "deepSeekApiKey", "");

        AiStatusResponse status = service.currentStatus();

        assertThat(status.isAvailable()).isFalse();
        assertThat(status.getPrimaryStatus()).isEqualTo("KEY_INVALID");
    }

    @Test
    void reportsAvailableWhenPrimaryAndFallbackAreUp() {
        AiStatusResponse status = service.currentStatus();

        assertThat(status.isAvailable()).isTrue();
        assertThat(status.getPrimaryStatus()).isEqualTo("UP");
        assertThat(status.getCircuitBreakerState()).isEqualTo("CLOSED");
        assertThat(status.isFallbackAvailable()).isTrue();
        assertThat(status.getFallbackProvider()).isEqualTo("mock");
    }

    @Test
    void reportsUnavailableWhenCircuitIsOpenAndFallbackIsDisabled() {
        ReflectionTestUtils.setField(service, "fallbackEnabled", false);
        ReflectionTestUtils.setField(service, "mockAiClient", null);
        circuitBreaker.transitionToOpenState();

        AiStatusResponse status = service.currentStatus();

        assertThat(status.isAvailable()).isFalse();
        assertThat(status.getPrimaryStatus()).isEqualTo("CIRCUIT_OPEN");
        assertThat(status.getCircuitBreakerState()).isEqualTo("OPEN");
        assertThat(status.isFallbackAvailable()).isFalse();
    }

    @Test
    void serializesPublicStatusContract() {
        AiStatusResponse status = service.currentStatus();
        JsonNode json = new ObjectMapper().findAndRegisterModules().valueToTree(status);

        List.of(
                "available",
                "primaryProvider",
                "primaryStatus",
                "circuitBreakerState",
                "latencyP50Ms",
                "latencyP95Ms",
                "errorRatePercent",
                "fallbackInUse",
                "fallbackAvailable",
                "lastChecked",
                "checkedAt")
                .forEach(field -> assertThat(json.has(field)).as(field).isTrue());
        assertThat(json.get("primaryProvider").asText()).isEqualTo("deepseek");
        assertThat(json.get("available").asBoolean()).isTrue();
    }
}
