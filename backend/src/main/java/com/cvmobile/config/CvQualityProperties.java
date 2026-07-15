package com.cvmobile.config;

import jakarta.validation.constraints.Min;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties("cv.quality")
public record CvQualityProperties(
        @DefaultValue("100") @Min(1) int initialScore,
        @DefaultValue("20") @Min(1) int penaltyMissingProfile,
        @DefaultValue("10") @Min(1) int penaltyShortDescription,
        @DefaultValue("5") @Min(1) int penaltyCliche,
        @DefaultValue("5") @Min(1) int penaltyAiTrace,
        @DefaultValue("100") @Min(1) int minimumProfileLength,
        @DefaultValue("80") @Min(1) int minimumExperienceDescriptionLength,
        @DefaultValue("10") @Min(1) int maxSkillsDisplayed
) {
}
