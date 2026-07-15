package com.cvmobile.service.ai.client;

import com.cvmobile.exception.ai.AiKeyInvalidException;
import com.cvmobile.exception.ai.AiParseException;
import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.exception.ai.AiQuotaExceededException;
import com.cvmobile.exception.ai.AiServiceException;
import com.cvmobile.exception.ai.AiTimeoutException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.retry.RetryConfig;
import io.github.resilience4j.core.IntervalFunction;
import io.github.resilience4j.timelimiter.TimeLimiter;
import io.github.resilience4j.timelimiter.TimeLimiterConfig;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.CompletionException;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.ArgumentMatchers.any;
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
        List<Duration> retryWaits = new ArrayList<>();
        Retry retry = retryWithExponentialBackoff();
        retry.getEventPublisher().onRetry(event -> retryWaits.add(event.getWaitInterval()));

        ResilientAiClient client = client(delegate, retry, closedCircuitBreaker(),
                timeLimiter(Duration.ofSeconds(2)));

        assertThat(client.complete("prompt", 100)).isEqualTo("generated content");
        assertThat(retryWaits).containsExactly(
                Duration.ofMillis(1),
                Duration.ofMillis(2));
    }

    @Test
    void propagatesProviderFailureAfterThirdAttempt() {
        AtomicInteger calls = new AtomicInteger();
        IAiClient delegate = (prompt, maxTokens) -> {
            calls.incrementAndGet();
            throw providerDown();
        };
        ResilientAiClient client = client(delegate, retry(3), closedCircuitBreaker(),
                timeLimiter(Duration.ofSeconds(2)));

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiProviderDownException.class)
                .hasMessageContaining("HTTP 503");
        assertThat(calls).hasValue(3);
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

    @ParameterizedTest
    @MethodSource("nonRetryableExceptions")
    void doesNotRetryQuotaOrParseErrors(AiServiceException failure) {
        AtomicInteger calls = new AtomicInteger();
        IAiClient delegate = (prompt, maxTokens) -> {
            calls.incrementAndGet();
            throw failure;
        };
        ResilientAiClient client = client(delegate, retry(3), closedCircuitBreaker(),
                timeLimiter(Duration.ofSeconds(2)));

        assertThatThrownBy(() -> client.complete("prompt", 100)).isSameAs(failure);
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
                .slidingWindowSize(5)
                .minimumNumberOfCalls(5)
                .failureRateThreshold(100)
                .recordExceptions(AiProviderDownException.class)
                .build());
        ResilientAiClient client = client(delegate, retry(1), circuitBreaker,
                timeLimiter(Duration.ofSeconds(2)));

        for (int attempt = 0; attempt < 5; attempt++) {
            assertThatThrownBy(() -> client.complete("prompt", 100))
                    .isInstanceOf(AiProviderDownException.class);
        }
        assertThat(circuitBreaker.getState()).isEqualTo(CircuitBreaker.State.OPEN);

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiProviderDownException.class)
                .hasMessageContaining("Circuit breaker open");
        assertThat(calls).hasValue(5);
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

    @Test
    void wrapsUnexpectedDelegateFailureAsProviderDown() {
        IAiClient delegate = (prompt, maxTokens) -> {
            throw new IllegalStateException("unexpected delegate failure");
        };
        ResilientAiClient client = client(delegate, retry(1), closedCircuitBreaker(),
                timeLimiter(Duration.ofSeconds(2)));

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiProviderDownException.class)
                .hasMessageContaining("Unexpected error")
                .hasMessageContaining("unexpected delegate failure");
    }

    @Test
    void unwrapsNestedTimeoutFailure() {
        IAiClient delegate = (prompt, maxTokens) -> {
            throw new CompletionException(new TimeoutException("nested timeout"));
        };
        ResilientAiClient client = client(delegate, retry(1), closedCircuitBreaker(),
                timeLimiter(Duration.ofSeconds(2)));

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiTimeoutException.class);
    }

    @Test
    void unwrapsNestedOpenCircuitFailure() {
        CircuitBreaker circuitBreaker = closedCircuitBreaker();
        IAiClient delegate = (prompt, maxTokens) -> {
            throw new CompletionException(
                    io.github.resilience4j.circuitbreaker.CallNotPermittedException
                            .createCallNotPermittedException(circuitBreaker));
        };
        ResilientAiClient client = client(delegate, retry(1), circuitBreaker,
                timeLimiter(Duration.ofSeconds(2)));

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiProviderDownException.class)
                .hasMessageContaining("Circuit breaker open");
    }

    @Test
    void wrapsUnexpectedCheckedTimeLimiterFailure() throws Exception {
        TimeLimiter failingTimeLimiter = mock(TimeLimiter.class);
        when(failingTimeLimiter.executeFutureSupplier(any()))
                .thenThrow(new Exception("time limiter failure"));
        ResilientAiClient client = client(
                (prompt, maxTokens) -> "unused",
                retry(1),
                closedCircuitBreaker(),
                failingTimeLimiter);

        assertThatThrownBy(() -> client.complete("prompt", 100))
                .isInstanceOf(AiProviderDownException.class)
                .hasMessageContaining("time limiter failure");
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
                .ignoreExceptions(
                        AiKeyInvalidException.class,
                        AiQuotaExceededException.class,
                        AiParseException.class)
                .build();
        return Retry.of("test-ai", config);
    }

    private Retry retryWithExponentialBackoff() {
        RetryConfig config = RetryConfig.custom()
                .maxAttempts(3)
                .intervalFunction(IntervalFunction.ofExponentialBackoff(1, 2.0))
                .retryExceptions(AiProviderDownException.class)
                .ignoreExceptions(
                        AiKeyInvalidException.class,
                        AiQuotaExceededException.class,
                        AiParseException.class)
                .build();
        return Retry.of("test-ai-backoff", config);
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

    private static Stream<AiServiceException> nonRetryableExceptions() {
        return Stream.of(
                new AiQuotaExceededException("deepseek", 60, null),
                new AiParseException("deepseek", "invalid body", null));
    }
}
