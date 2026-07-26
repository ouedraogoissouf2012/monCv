package com.cvmobile.config;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.NotBlank;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;
import org.springframework.validation.annotation.Validated;

import java.time.Duration;

@Validated
@ConfigurationProperties("security.rate-limit")
public record RateLimitProperties(
        @DefaultValue("false") boolean enabled,
        @DefaultValue("true") boolean adminBypass,
        @DefaultValue("10") @Min(1) int authRequests,
        @DefaultValue("1m") @NotNull Duration authWindow,
        @DefaultValue("20") @Min(1) int aiRequests,
        @DefaultValue("1h") @NotNull Duration aiWindow,
        @DefaultValue("5") @Min(1) int importRequests,
        @DefaultValue("1h") @NotNull Duration importWindow,
        @DefaultValue("60") @Min(1) int publicRequests,
        @DefaultValue("1m") @NotNull Duration publicWindow,
        @DefaultValue("6") @Min(1) int publicDownloadRequests,
        @DefaultValue("1m") @NotNull Duration publicDownloadWindow,
        @DefaultValue("20") @Min(1) int publicShareRequests,
        @DefaultValue("1m") @NotNull Duration publicShareWindow,
        @DefaultValue("redis://localhost:6379") @NotBlank String redisUrl,
        @DefaultValue("moncv:rate-limit:") @NotBlank String keyPrefix
) {
}
