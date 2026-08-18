package com.cvmobile.service.ai.client;

import com.cvmobile.exception.ai.AiKeyInvalidException;
import com.cvmobile.exception.ai.AiParseException;
import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.exception.ai.AiQuotaExceededException;
import com.cvmobile.observability.BusinessMetrics;
import com.cvmobile.service.ai.AiTelemetry;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class CompositeAiClientTest {

    private IAiClient primary;
    private IAiClient fallback;
    private SimpleMeterRegistry meters;
    private BusinessMetrics businessMetrics;
    private CompositeAiClient client;

    @BeforeEach
    void setUp() {
        primary = mock(IAiClient.class);
        fallback = mock(IAiClient.class);
        meters = new SimpleMeterRegistry();
        businessMetrics = new BusinessMetrics(meters);
        client = new CompositeAiClient(primary, fallback, meters, businessMetrics, new AiTelemetry(), true);
    }

    @Test
    void returnsPrimaryResultWithoutFallback() {
        when(primary.complete("prompt", 100)).thenReturn("primary result");

        assertThat(client.complete("prompt", 100)).isEqualTo("primary result");
        assertThat(client.isFallbackResult()).isFalse();
        verify(fallback, never()).complete("prompt", 100);
    }

    @Test
    void usesFallbackOnlyWhenPrimaryProviderIsDown() {
        when(primary.complete("prompt", 100)).thenThrow(providerDown("primary"));
        when(fallback.complete("prompt", 100)).thenReturn("fallback result");

        assertThat(client.complete("prompt", 100)).isEqualTo("fallback result");
        assertThat(client.isFallbackResult()).isTrue();
    }

    @Test
    void propagatesInvalidKeyWithoutCallingFallback() {
        AiKeyInvalidException invalidKey = new AiKeyInvalidException("deepseek", null);
        when(primary.complete("prompt", 100)).thenThrow(invalidKey);

        assertThatThrownBy(() -> client.complete("prompt", 100)).isSameAs(invalidKey);
        verify(fallback, never()).complete("prompt", 100);
    }

    @Test
    void propagatesQuotaWithoutCallingFallback() {
        AiQuotaExceededException quota = new AiQuotaExceededException("deepseek", 60, null);
        when(primary.complete("prompt", 100)).thenThrow(quota);

        assertThatThrownBy(() -> client.complete("prompt", 100)).isSameAs(quota);
        verify(fallback, never()).complete("prompt", 100);
    }

    @Test
    void propagatesParseErrorWithoutCallingFallback() {
        AiParseException parseError = new AiParseException("deepseek", "bad body", null);
        when(primary.complete("prompt", 100)).thenThrow(parseError);

        assertThatThrownBy(() -> client.complete("prompt", 100)).isSameAs(parseError);
        verify(fallback, never()).complete("prompt", 100);
    }

    @Test
    void propagatesLastExceptionWhenFallbackAlsoFails() {
        AiProviderDownException fallbackFailure = providerDown("mock");
        when(primary.complete("prompt", 100)).thenThrow(providerDown("primary"));
        when(fallback.complete("prompt", 100)).thenThrow(fallbackFailure);

        assertThatThrownBy(() -> client.complete("prompt", 100)).isSameAs(fallbackFailure);
    }

    @Test
    void incrementsDedicatedFallbackMetric() {
        when(primary.complete("prompt", 100)).thenThrow(providerDown("primary"));
        when(fallback.complete("prompt", 100)).thenReturn("fallback result");

        client.complete("prompt", 100);

        assertThat(meters.get("ai.fallback.triggered").counter().count()).isEqualTo(1.0);
        assertThat(meters.get("ai.fallback.triggered.total").counter().count()).isEqualTo(1.0);
    }

    @Test
    void incrementsAiCallsMetricWhenProviderReturnsParseError() {
        AiParseException parseError = new AiParseException("deepseek", "bad body", null);
        when(primary.complete("prompt", 100)).thenThrow(parseError);

        assertThatThrownBy(() -> client.complete("prompt", 100)).isSameAs(parseError);

        assertThat(meters.get("ai.calls.total")
                .tag("provider", primary.getClass().getSimpleName())
                .tag("operation", "complete")
                .tag("status", "error")
                .counter()
                .count()).isEqualTo(1.0);
    }

    @Test
    void propagatesPrimaryFailureWhenFallbackIsDisabled() {
        AiProviderDownException failure = providerDown("primary");
        CompositeAiClient withoutFallback = new CompositeAiClient(
                primary, fallback, meters, businessMetrics, new AiTelemetry(), false);
        when(primary.complete("prompt", 100)).thenThrow(failure);

        assertThatThrownBy(() -> withoutFallback.complete("prompt", 100)).isSameAs(failure);
        verify(fallback, never()).complete("prompt", 100);
    }

    @Test
    void startsWithoutMockBeanWhenFallbackDisabled() {
        AiProviderDownException failure = providerDown("primary");
        CompositeAiClient withoutMock = new CompositeAiClient(
                primary, null, meters, businessMetrics, new AiTelemetry(), false);
        when(primary.complete("prompt", 100)).thenThrow(failure);

        assertThatThrownBy(() -> withoutMock.complete("prompt", 100)).isSameAs(failure);
    }

    private AiProviderDownException providerDown(String provider) {
        return new AiProviderDownException(provider, "unavailable", null);
    }
}
