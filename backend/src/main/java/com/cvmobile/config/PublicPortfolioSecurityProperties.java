package com.cvmobile.config;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;
import org.springframework.validation.annotation.Validated;

import java.time.Duration;
import java.util.List;

@Validated
@ConfigurationProperties("security.public-portfolio")
public record PublicPortfolioSecurityProperties(
        @NotBlank String encryptionKey,
        @DefaultValue("5m") @NotNull Duration viewDeduplicationWindow,
        @DefaultValue("2") @Min(1) @Max(16) int maxConcurrentDocuments,
        @DefaultValue("250ms") @NotNull Duration documentAcquireTimeout,
        @DefaultValue("10485760") @Min(1_048_576) @Max(52_428_800) int maxDocumentBytes,
        List<String> allowedMediaOrigins
) {
    public PublicPortfolioSecurityProperties {
        allowedMediaOrigins = allowedMediaOrigins == null
                ? List.of()
                : allowedMediaOrigins.stream()
                        .map(String::trim)
                        .filter(value -> !value.isEmpty())
                        .toList();
    }
}
