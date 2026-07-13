package com.cvmobile.service.ai.client;

import com.cvmobile.exception.ai.AiKeyInvalidException;
import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.exception.ai.AiTimeoutException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.retry.RetryConfig;
import io.github.resilience4j.timelimiter.TimeLimiter;
import io.github.resilience4j.timelimiter.TimeLimiterConfig;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class ResilientAiClientTest {

    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    @AfterEach
    void tearDown() {
        executor.shutdownNow();
    }

    @Test
    void retriesProviderFailureUntilThirdAttemptSucceeds() {
        IAiClient delegate = mock(IAiClient.class);
        when(delegate.complete("prompt", 100))
                .thenThrow(providerDown())
                .thenThrow(providerDown())
                .thenReturn("generated content");
        AtomicInteger retries = new AtomicInteger();
        Retry retry = retry(3);
        retry.getEventPublisher().onRetry(event -> retries.incrementAndGet());

        ResilientAiClient client = client(delegate, retry, closedCircuitBreaker(),
                timeLimiter(Duration.ofSeconds(2)));

        assertThat(client.complete("prompt", 100)).isEqualTo("generated content");
        assertThat(retries).hasValue(2);
    }

    @Test
    void doesNotRetryInvalidProviderKey() {
        IAiClient delegate = mock(IAiClient.class);
        AtomicInteger calls = new AtomicInteger();
        when(delegate.complete("prompt", 100)).thenAnswer(invocation -> {
            calls.incrementAndGet();
            throw new AiKeyInvalidException("deepseek", null);
        });

        ResilientAiClient client = client(delegate, retry(3), closedCircuitBreaker(),
                timeLimiter(Duration.ofSeconds(2)));

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiKeyInvalidException.class);
        assertThat(calls).hasValue(1);
    }

    @Test
    void opensCircuitAfterConfiguredFailureThreshold() {
        IAiClient delegate = mock(IAiClient.class);
        AtomicInteger calls = new AtomicInteger();
        when(delegate.complete("prompt", 100)).thenAnswer(invocation -> {
            calls.incrementAndGet();
            throw providerDown();
        });
        CircuitBreaker circuitBreaker = CircuitBreaker.of("test-ai", CircuitBreakerConfig.custom()
                .slidingWindowType(CircuitBreakerConfig.SlidingWindowType.COUNT_BASED)
                .slidingWindowSize(2)
                .minimumNumberOfCalls(2)
                .failureRateThreshold(50)
                .recordExceptions(AiProviderDownException.class)
                .build());
        ResilientAiClient client = client(delegate, retry(1), circuitBreaker,
                timeLimiter(Duration.ofSeconds(2)));

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiProviderDownException.class);
        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiProviderDownException.class);
        assertThat(circuitBreaker.getState()).isEqualTo(CircuitBreaker.State.OPEN);

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiProviderDownException.class)
                .hasMessageContaining("Circuit breaker open");
        assertThat(calls).hasValue(2);
    }

    @Test
    void enforcesTimeLimiter() {
        IAiClient delegate = mock(IAiClient.class);
        when(delegate.complete("prompt", 100)).thenAnswer(invocation -> {
            Thread.sleep(500);
            return "too late";
        });
        ResilientAiClient client = client(delegate, retry(1), closedCircuitBreaker(),
                timeLimiter(Duration.ofMillis(50)));

        long startedAt = System.nanoTime();
        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiTimeoutException.class)
                .extracting(error -> ((AiTimeoutException) error).getErrorCode())
                .isEqualTo("AI_TIMEOUT");
        assertThat(Duration.ofNanos(System.nanoTime() - startedAt))
                .isLessThan(Duration.ofMillis(400));
    }

    private ResilientAiClient client(IAiClient delegate, Retry retry,
                                     CircuitBreaker circuitBreaker, TimeLimiter timeLimiter) {
        return new ResilientAiClient(
                delegate, "deepseek", retry, circuitBreaker, timeLimiter, executor);
    }

    private Retry retry(int maxAttempts) {
        RetryConfig config = RetryConfig.custom()
                .maxAttempts(maxAttempts)
                .waitDuration(Duration.ZERO)
                .retryExceptions(AiProviderDownException.class)
                .ignoreExceptions(AiKeyInvalidException.class)
                .build();
        return Retry.of("test-ai", config);
    }

    private CircuitBreaker closedCircuitBreaker() {
        CircuitBreakerConfig config = CircuitBreakerConfig.custom()
                .minimumNumberOfCalls(10)
                .recordExceptions(AiProviderDownException.class)
                .ignoreExceptions(AiKeyInvalidException.class)
                .build();
        return CircuitBreaker.of("test-ai", config);
    }

    private TimeLimiter timeLimiter(Duration timeout) {
        return TimeLimiter.of(TimeLimiterConfig.custom()
                .timeoutDuration(timeout)
                .cancelRunningFuture(true)
                .build());
    }

    private AiProviderDownException providerDown() {
        return new AiProviderDownException("deepseek", "HTTP 503", null);
    }
}
