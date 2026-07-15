package com.cvmobile.config;

import jakarta.validation.constraints.Min;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties("ai.job-match")
public record JobMatchProperties(
        @DefaultValue("50") @Min(1) int defaultScore,
        @DefaultValue("14") @Min(1) int maxKeywords,
        @DefaultValue("6") @Min(1) int maxSuggestions,
        @DefaultValue("5") @Min(1) int maxFallbackSuggestions,
        @DefaultValue("5") @Min(1) int maxRecommendations,
        @DefaultValue("100") @Min(1) int maxScore,
        @DefaultValue("1800") @Min(1) int completionTokens
) {
}
