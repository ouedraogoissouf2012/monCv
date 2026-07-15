package com.cvmobile.config;

import jakarta.validation.constraints.Min;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties("ai.suggestions")
public record AiSuggestionProperties(
        @DefaultValue("5") @Min(1) int maxSuggestions,
        @DefaultValue("600") @Min(1) int completionTokens
) {
}
