package com.cvmobile.service.ai.client;

import com.cvmobile.exception.ai.AiKeyInvalidException;
import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.exception.ai.AiQuotaExceededException;
import com.cvmobile.exception.ai.AiServiceException;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * Client IA composite avec chaine de fallback : primary -> fallback.
 *
 * Decision architecturale cle : le fallback ne se declenche QUE pour
 * AiProviderDownException (service down temporaire).
 *
 * - AiKeyInvalidException : probleme de config -> propage immediatement
 *   (ne pas masquer le bug)
 * - AiQuotaExceededException : probleme de quota -> propage
 *   (utilisateur doit savoir)
 * - AiProviderDownException : 5xx / timeout / circuit ouvert -> fallback
 * - AiParseException : reponse malformee -> propage
 *   (un mock ne resoudra rien ici)
 *
 * Expose les metriques Micrometer : ai.requests.total, ai.latency
 */
@Slf4j
@Primary
@Component
public class CompositeAiClient implements IAiClient {

    private final List<IAiClient> providers;
    private final MeterRegistry meters;

    public CompositeAiClient(
            @Qualifier("resilientDeepSeek") IAiClient primary,
            @Qualifier("mockAiClient") IAiClient fallback,
            MeterRegistry meters,
            @Value("${ai.fallback.enabled:true}") boolean fallbackEnabled) {
        List<IAiClient> chain = new ArrayList<>();
        chain.add(primary);
        if (fallbackEnabled) {
            chain.add(fallback);
            log.info("AI provider chain: {} -> {} (fallback enabled)",
                    providerName(primary), providerName(fallback));
        } else {
            log.info("AI provider chain: {} (no fallback)", providerName(primary));
        }
        this.providers = List.copyOf(chain);
        this.meters = meters;
    }

    @Override
    public boolean isAvailable() {
        return providers.stream().anyMatch(IAiClient::isAvailable);
    }

    @Override
    public String complete(String prompt, int maxTokens) {
        AiProviderDownException lastDown = null;

        for (int i = 0; i < providers.size(); i++) {
            IAiClient provider = providers.get(i);
            String providerName = providerName(provider);
            boolean isPrimary = (i == 0);

            Timer.Sample sample = Timer.start(meters);
            try {
                String result = provider.complete(prompt, maxTokens);
                sample.stop(meters.timer("ai.latency",
                        "provider", providerName));
                meters.counter("ai.requests.total",
                        "provider", providerName,
                        "status", isPrimary ? "primary_ok" : "fallback_ok").increment();
                if (!isPrimary) {
                    log.warn("Primary provider failed, served via fallback {}", providerName);
                }
                return result;

            } catch (AiKeyInvalidException | AiQuotaExceededException e) {
                // Ces erreurs doivent remonter immediatement : pas de fallback silencieux
                sample.stop(meters.timer("ai.latency", "provider", providerName));
                meters.counter("ai.requests.total",
                        "provider", providerName,
                        "status", "config_error").increment();
                throw e;

            } catch (AiProviderDownException e) {
                sample.stop(meters.timer("ai.latency", "provider", providerName));
                meters.counter("ai.requests.total",
                        "provider", providerName,
                        "status", "failed").increment();
                lastDown = e;
                log.warn("Provider {} down, trying next provider. Reason: {}",
                        providerName, e.getMessage());

            } catch (AiServiceException e) {
                // AiParseException et autres : pas de fallback (mock ne resoudra rien)
                sample.stop(meters.timer("ai.latency", "provider", providerName));
                meters.counter("ai.requests.total",
                        "provider", providerName,
                        "status", "error").increment();
                throw e;
            }
        }

        // Tous les providers ont echoue
        throw lastDown != null ? lastDown
                : new AiProviderDownException("composite", "All providers exhausted", null);
    }

    private String providerName(IAiClient client) {
        if (client instanceof MockAiClient) return MockAiClient.PROVIDER_NAME;
        if (client instanceof ResilientAiClient) return "resilient-" + DeepSeekClient.PROVIDER_NAME;
        return client.getClass().getSimpleName();
    }
}
