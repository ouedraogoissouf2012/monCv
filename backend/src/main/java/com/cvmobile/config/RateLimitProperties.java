package com.cvmobile.config;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;
import org.springframework.validation.annotation.Validated;

import java.time.Duration;

@Validated
@ConfigurationProperties("security.rate-limit")
public record RateLimitProperties(
        @DefaultValue("10") @Min(1) int authRequests,
        @DefaultValue("20") @Min(1) int aiRequests,
        @DefaultValue("60") @Min(1) int publicRequests,
        @DefaultValue("1m") @NotNull Duration window
) {
}
