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
import java.util.Optional;

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

    @Autowired(required = false)
    private MockAiClient mockAiClient;

    @Value("${ai.deepseek.api-key:}")
    private String deepSeekApiKey;

    @Value("${ai.fallback.enabled:true}")
    private boolean fallbackEnabled;

    public AiStatusResponse currentStatus() {
        String primaryStatus = computePrimaryStatus();
        boolean primaryUp = "UP".equals(primaryStatus);
        boolean fallbackUp = fallbackEnabled && mockAiClient != null;

        return AiStatusResponse.builder()
                .available(primaryUp || fallbackUp)
                .primaryProvider(DeepSeekClient.PROVIDER_NAME)
                .primaryStatus(primaryStatus)
                .fallbackAvailable(fallbackUp)
                .fallbackProvider(fallbackUp ? MockAiClient.PROVIDER_NAME : null)
                .lastChecked(Instant.now())
                .build();
    }

    private String computePrimaryStatus() {
        if (deepSeekApiKey == null || deepSeekApiKey.isBlank()) {
            return "KEY_INVALID";
        }
        CircuitBreaker.State cbState = Optional.ofNullable(
                circuitBreakerRegistry.find("ai-deepseek").orElse(null))
                .map(CircuitBreaker::getState)
                .orElse(CircuitBreaker.State.CLOSED);
        return switch (cbState) {
            case OPEN, FORCED_OPEN -> "CIRCUIT_OPEN";
            case HALF_OPEN -> "RECOVERING";
            case CLOSED, DISABLED, METRICS_ONLY -> "UP";
        };
    }
}
