package com.cvmobile.security;

import com.cvmobile.config.RateLimitProperties;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.BucketConfiguration;
import io.github.bucket4j.ConsumptionProbe;
import io.github.bucket4j.distributed.proxy.ProxyManager;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;

import java.time.Duration;

@Service
public class RedisRateLimitService implements RateLimitService {

    private final ProxyManager<String> proxyManager;
    private final RateLimitProperties properties;

    public RedisRateLimitService(
            @Lazy ProxyManager<String> proxyManager,
            RateLimitProperties properties) {
        this.proxyManager = proxyManager;
        this.properties = properties;
    }

    @Override
    public RateLimitResult consume(String key, long capacity, Duration refillPeriod) {
        BucketConfiguration configuration = BucketConfiguration.builder()
                .addLimit(limit -> limit
                        .capacity(capacity)
                        .refillIntervally(capacity, refillPeriod))
                .build();
        Bucket bucket = proxyManager.getProxy(
                properties.keyPrefix() + key,
                () -> configuration
        );

        ConsumptionProbe probe = bucket.tryConsumeAndReturnRemaining(1);
        if (probe.isConsumed()) {
            return RateLimitResult.allowed(probe.getRemainingTokens());
        }
        return RateLimitResult.rejected(Duration.ofNanos(probe.getNanosToWaitForRefill()));
    }
}
