package com.cvmobile.service.ai;

import com.cvmobile.dto.AiStatusResponse;
import com.cvmobile.service.ai.client.DeepSeekClient;
import com.cvmobile.service.ai.client.MockAiClient;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.concurrent.TimeUnit;

/**
 * Agrège l'état du sous-système IA pour l'endpoint GET /api/ai/status.
 *
 * Ne fait AUCUN appel réseau supplémentaire : lit uniquement l'état interne
 * (présence de clé, état du circuit breaker, présence du provider fallback).
 * Cheap, peut être appelé aussi souvent que nécessaire cote Flutter.
 */
@Service
@RequiredArgsConstructor
public class AiStatusService {

    private final CircuitBreakerRegistry circuitBreakerRegistry;
    private final AiTelemetry telemetry;

    @Autowired(required = false)
    private MockAiClient mockAiClient;

    @Value("${ai.deepseek.api-key:}")
    private String deepSeekApiKey;

    @Value("${ai.fallback.enabled:true}")
    private boolean fallbackEnabled;

    private volatile AiStatusResponse cachedStatus;
    private volatile long cacheExpiresAtNanos;

    private static final long CACHE_TTL_NANOS = TimeUnit.SECONDS.toNanos(10);

    public AiStatusResponse currentStatus() {
        long now = System.nanoTime();
        AiStatusResponse cached = cachedStatus;
        if (cached != null && now < cacheExpiresAtNanos) {
            return cached;
        }
        synchronized (this) {
            now = System.nanoTime();
            if (cachedStatus != null && now < cacheExpiresAtNanos) {
                return cachedStatus;
            }
            cachedStatus = buildStatus();
            cacheExpiresAtNanos = now + CACHE_TTL_NANOS;
            return cachedStatus;
        }
    }

    private AiStatusResponse buildStatus() {
        boolean keyConfigured = deepSeekApiKey != null && !deepSeekApiKey.isBlank();
        CircuitBreaker circuitBreaker = circuitBreakerRegistry
                .find("ai-deepseek")
                .orElseGet(() -> circuitBreakerRegistry.circuitBreaker("ai-deepseek"));
        CircuitBreaker.State cbState = circuitBreaker.getState();
        String primaryStatus = computePrimaryStatus(keyConfigured, cbState);
        boolean fallbackUp = fallbackEnabled && mockAiClient != null;
        boolean primaryUp = keyConfigured && switch (cbState) {
            case OPEN, FORCED_OPEN -> false;
            case HALF_OPEN, CLOSED, DISABLED, METRICS_ONLY -> true;
        };
        boolean available = keyConfigured && (primaryUp || fallbackUp);
        float failureRate = circuitBreaker.getMetrics().getFailureRate();
        double errorRate = failureRate < 0 ? 0 : failureRate;
        AiTelemetry.Snapshot snapshot = telemetry.snapshot();
        Instant checkedAt = Instant.now();
        AiStatusResponse.LastAiError lastError = snapshot.lastError() == null ? null
                : AiStatusResponse.LastAiError.builder()
                .timestamp(snapshot.lastError().timestamp())
                .type(snapshot.lastError().type())
                .build();

        return AiStatusResponse.builder()
                .available(available)
                .primaryProvider(AiProviderLabel.toPublicLabel(DeepSeekClient.PROVIDER_NAME))
                .primaryStatus(primaryStatus)
                .circuitBreakerState(cbState.name())
                .lastError(lastError)
                .latencyP50Ms(snapshot.latencyP50Ms())
                .latencyP95Ms(snapshot.latencyP95Ms())
                .errorRatePercent(errorRate)
                .fallbackInUse(snapshot.fallbackInUse())
                .fallbackAvailable(fallbackUp)
                .fallbackProvider(fallbackUp ? MockAiClient.PROVIDER_NAME : null)
                .lastChecked(checkedAt)
                .checkedAt(checkedAt)
                .build();
    }

    private String computePrimaryStatus(boolean keyConfigured, CircuitBreaker.State cbState) {
        if (!keyConfigured) {
            return "KEY_INVALID";
        }
        return switch (cbState) {
            case OPEN, FORCED_OPEN -> "CIRCUIT_OPEN";
            case HALF_OPEN -> "RECOVERING";
            case CLOSED, DISABLED, METRICS_ONLY -> "UP";
        };
    }
}
