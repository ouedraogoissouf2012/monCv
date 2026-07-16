package com.cvmobile.config;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties("security.request-body")
public record RequestBodyLimitProperties(
        @DefaultValue("1048576") @Min(65_536) @Max(16_777_216) int maxJsonBytes,
        @DefaultValue("8388608") @Min(1_048_576) @Max(16_777_216) int maxCvJsonBytes
) {
}
