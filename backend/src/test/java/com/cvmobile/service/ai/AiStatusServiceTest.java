package com.cvmobile.service.ai;

import com.cvmobile.dto.AiStatusResponse;
import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.service.ai.client.MockAiClient;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

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
}
