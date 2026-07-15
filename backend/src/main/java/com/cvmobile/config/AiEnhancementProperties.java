package com.cvmobile.config;

import jakarta.validation.constraints.Min;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties("ai.enhancement")
public record AiEnhancementProperties(
        @DefaultValue("3000") @Min(1) int completionTokens
) {
}
