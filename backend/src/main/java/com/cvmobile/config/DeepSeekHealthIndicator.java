package com.cvmobile.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.health.AbstractHealthIndicator;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.context.annotation.Profile;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;
import java.time.Instant;

/**
 * Health check pour l'API DeepSeek.
 * Expose via /actuator/health (composant "deepseek").
 *
 * - UP : cle configuree ET API joignable (200 sur /models)
 * - OUT_OF_SERVICE : cle invalide (401)
 * - DOWN : cle manquante
 * - UNKNOWN : timeout reseau
 *
 * Cache 60s pour eviter de saturer l'API DeepSeek (actuator peut etre sollicite souvent).
 */
@Slf4j
@Component("deepseek")
@Profile("!test")
public class DeepSeekHealthIndicator extends AbstractHealthIndicator {

    private static final Duration CACHE_TTL = Duration.ofSeconds(60);

    private final String apiKey;
    private final String baseUrl;
    private final String model;
    private final RestTemplate restTemplate;

    private volatile Health cachedHealth;
    private volatile Instant lastCheck = Instant.EPOCH;

    public DeepSeekHealthIndicator(
            @Value("${ai.deepseek.api-key:}") String apiKey,
            @Value("${ai.deepseek.base-url:https://api.deepseek.com/v1}") String baseUrl,
            @Value("${ai.deepseek.model:deepseek-chat}") String model,
            RestTemplateBuilder builder) {
        this.apiKey = apiKey;
        this.baseUrl = baseUrl;
        this.model = model;
        this.restTemplate = builder
                .setConnectTimeout(Duration.ofSeconds(2))
                .setReadTimeout(Duration.ofSeconds(2))
                .build();
    }

    @Override
    protected void doHealthCheck(Health.Builder builder) {
        // Cache
        if (cachedHealth != null && Duration.between(lastCheck, Instant.now()).compareTo(CACHE_TTL) < 0) {
            copyHealth(cachedHealth, builder);
            return;
        }

        Health result = probe();
        this.cachedHealth = result;
        this.lastCheck = Instant.now();
        copyHealth(result, builder);
    }

    private Health probe() {
        if (apiKey == null || apiKey.isBlank()) {
            return Health.down()
                    .withDetail("reason", "api-key-missing")
                    .withDetail("hint", "Set DEEPSEEK_API_KEY environment variable")
                    .build();
        }

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(apiKey);
            HttpEntity<Void> entity = new HttpEntity<>(headers);

            restTemplate.exchange(baseUrl + "/models", HttpMethod.GET, entity, String.class);
            return Health.up()
                    .withDetail("model", model)
                    .withDetail("baseUrl", baseUrl)
                    .build();
        } catch (HttpClientErrorException.Unauthorized e) {
            return Health.outOfService()
                    .withDetail("reason", "api-key-invalid")
                    .withDetail("httpStatus", 401)
                    .build();
        } catch (Exception e) {
            log.debug("DeepSeek health probe failed: {}", e.getMessage());
            return Health.unknown()
                    .withDetail("reason", "probe-failed")
                    .withDetail("error", e.getClass().getSimpleName())
                    .build();
        }
    }

    private void copyHealth(Health source, Health.Builder target) {
        target.status(source.getStatus());
        source.getDetails().forEach(target::withDetail);
    }
}
