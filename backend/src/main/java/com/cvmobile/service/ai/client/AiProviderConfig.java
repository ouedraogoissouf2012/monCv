package com.cvmobile.service.ai.client;

import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.retry.RetryRegistry;
import io.github.resilience4j.timelimiter.TimeLimiterRegistry;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.Executor;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Cablage des beans du sous-systeme IA.
 *
 * - aiExecutor : pool de threads dedie pour les appels IA async (TimeLimiter)
 * - resilientDeepSeek : DeepSeekClient brut decore par ResilientAiClient (retry+CB+timeout)
 *
 * Le CompositeAiClient (@Primary) est auto-injecte via @Component, pas besoin de @Bean ici.
 */
@Configuration
public class AiProviderConfig {

    /**
     * Pool dedie pour les appels IA async.
     * Taille = 4 : equilibre entre concurrence et protection de la JVM
     * contre un flood de requetes lentes.
     */
    @Bean
    public Executor aiExecutor() {
        return Executors.newFixedThreadPool(4, new ThreadFactory() {
            private final AtomicInteger counter = new AtomicInteger(1);
            @Override
            public Thread newThread(Runnable r) {
                Thread t = new Thread(r, "ai-exec-" + counter.getAndIncrement());
                t.setDaemon(true);
                return t;
            }
        });
    }

    /**
     * DeepSeekClient decore par Resilience4j.
     * Nomme "resilientDeepSeek" pour l'injection dans CompositeAiClient.
     */
    @Bean("resilientDeepSeek")
    public IAiClient resilientDeepSeek(
            DeepSeekClient raw,
            RetryRegistry retryRegistry,
            CircuitBreakerRegistry cbRegistry,
            TimeLimiterRegistry tlRegistry,
            MeterRegistry meters,
            Executor aiExecutor) {
        return new ResilientAiClient(
                raw,
                DeepSeekClient.PROVIDER_NAME,
                retryRegistry.retry("ai-deepseek"),
                cbRegistry.circuitBreaker("ai-deepseek"),
                tlRegistry.timeLimiter("ai-deepseek"),
                aiExecutor);
    }
}
