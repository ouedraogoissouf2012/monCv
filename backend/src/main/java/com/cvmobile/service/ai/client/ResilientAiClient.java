package com.cvmobile.service.ai.client;

import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.exception.ai.AiServiceException;
import com.cvmobile.exception.ai.AiTimeoutException;
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.timelimiter.TimeLimiter;
import lombok.extern.slf4j.Slf4j;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executor;
import java.util.concurrent.TimeoutException;
import java.util.function.Supplier;

/**
 * Decorateur IAiClient avec retry + circuit breaker + timeout.
 *
 * Architecture :
 * - TimeLimiter (outer) : 10s cap dur sur l'appel total
 *   -> AiTimeoutException si depasse
 * - CircuitBreaker (middle) : ouvre apres N echecs dans fenetre glissante
 *   -> AiProviderDownException("Circuit open") si circuit ouvert
 * - Retry (inner) : 2 retries avec backoff expo + jitter sur AiProviderDownException
 *   Pas de retry sur KeyInvalid / Quota / Parse (ignoreExceptions config)
 *
 * Les services appellent IAiClient sans connaitre cette couche.
 */
@Slf4j
public class ResilientAiClient implements IAiClient {

    private final IAiClient delegate;
    private final String providerName;
    private final Retry retry;
    private final CircuitBreaker circuitBreaker;
    private final TimeLimiter timeLimiter;
    private final Executor executor;

    public ResilientAiClient(IAiClient delegate,
                             String providerName,
                             Retry retry,
                             CircuitBreaker circuitBreaker,
                             TimeLimiter timeLimiter,
                             Executor executor) {
        this.delegate = delegate;
        this.providerName = providerName;
        this.retry = retry;
        this.circuitBreaker = circuitBreaker;
        this.timeLimiter = timeLimiter;
        this.executor = executor;
    }

    @Override
    public boolean isAvailable() {
        return circuitBreaker.getState() != CircuitBreaker.State.OPEN
                && delegate.isAvailable();
    }

    @Override
    public String complete(String prompt, int maxTokens) {
        // Chaine : Retry(CircuitBreaker(delegate))
        Supplier<String> decorated = Retry.decorateSupplier(retry,
                CircuitBreaker.decorateSupplier(circuitBreaker,
                        () -> delegate.complete(prompt, maxTokens)));

        // TimeLimiter via CompletableFuture
        CompletableFuture<String> future = CompletableFuture.supplyAsync(decorated, executor);

        try {
            return timeLimiter.executeFutureSupplier(() -> future);
        } catch (TimeoutException e) {
            future.cancel(true);
            throw new AiTimeoutException(providerName, e);
        } catch (CallNotPermittedException e) {
            // Circuit breaker ouvert
            throw new AiProviderDownException(providerName, "Circuit breaker open", e);
        } catch (RuntimeException e) {
            // Deballer les CompletionException issues de CompletableFuture
            Throwable cause = unwrap(e);
            if (cause instanceof AiServiceException ase) throw ase;
            if (cause instanceof TimeoutException) {
                throw new AiTimeoutException(providerName, cause);
            }
            if (cause instanceof CallNotPermittedException) {
                throw new AiProviderDownException(providerName, "Circuit breaker open", cause);
            }
            throw new AiProviderDownException(providerName,
                    "Unexpected error: " + cause.getMessage(), cause);
        } catch (Exception e) {
            throw new AiProviderDownException(providerName,
                    "Unexpected error: " + e.getMessage(), e);
        }
    }

    private Throwable unwrap(Throwable t) {
        while ((t instanceof java.util.concurrent.CompletionException || t instanceof ExecutionException)
                && t.getCause() != null && t.getCause() != t) {
            t = t.getCause();
        }
        return t;
    }
}
