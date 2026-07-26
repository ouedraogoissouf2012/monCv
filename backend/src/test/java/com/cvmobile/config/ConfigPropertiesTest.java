package com.cvmobile.config;

import org.junit.jupiter.api.Test;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;

class ConfigPropertiesTest {

    private final ApplicationContextRunner contextRunner = new ApplicationContextRunner()
            .withUserConfiguration(PropertiesConfiguration.class);

    @Test
    void bindsDocumentedDefaults() {
        contextRunner.run(context -> {
            assertThat(context).hasNotFailed();
            assertThat(context.getBean(CvQualityProperties.class))
                    .isEqualTo(new CvQualityProperties(100, 20, 10, 5, 5, 100, 80, 10));
            assertThat(context.getBean(JobMatchProperties.class))
                    .isEqualTo(new JobMatchProperties(50, 14, 6, 5, 5, 100, 1800));
            assertThat(context.getBean(AiSuggestionProperties.class))
                    .isEqualTo(new AiSuggestionProperties(5, 600));
            assertThat(context.getBean(AiEnhancementProperties.class))
                    .isEqualTo(new AiEnhancementProperties(3000));
            assertThat(context.getBean(RateLimitProperties.class))
                    .isEqualTo(new RateLimitProperties(
                            false,
                            true,
                            10,
                            Duration.ofMinutes(1),
                            20,
                            Duration.ofHours(1),
                            5,
                            Duration.ofHours(1),
                            60,
                            Duration.ofMinutes(1),
                            6,
                            Duration.ofMinutes(1),
                            20,
                            Duration.ofMinutes(1),
                            "redis://localhost:6379",
                            "moncv:rate-limit:"
                    ));
            assertThat(context.getBean(NotificationProperties.class))
                    .isEqualTo(new NotificationProperties(30));
        });
    }

    @Test
    void profileValuesOverrideDefaults() {
        contextRunner
                .withPropertyValues(
                        "cv.quality.initial-score=90",
                        "cv.quality.max-skills-displayed=7",
                        "ai.job-match.default-score=45",
                        "ai.job-match.max-keywords=9",
                        "ai.suggestions.max-suggestions=3",
                        "ai.enhancement.completion-tokens=2400",
                        "security.rate-limit.enabled=true",
                        "security.rate-limit.ai-requests=12",
                        "security.rate-limit.ai-window=30s",
                        "notifications.stale-cv-days=21"
                )
                .run(context -> {
                    assertThat(context.getBean(CvQualityProperties.class).initialScore()).isEqualTo(90);
                    assertThat(context.getBean(CvQualityProperties.class).maxSkillsDisplayed()).isEqualTo(7);
                    assertThat(context.getBean(JobMatchProperties.class).defaultScore()).isEqualTo(45);
                    assertThat(context.getBean(JobMatchProperties.class).maxKeywords()).isEqualTo(9);
                    assertThat(context.getBean(AiSuggestionProperties.class).maxSuggestions()).isEqualTo(3);
                    assertThat(context.getBean(AiEnhancementProperties.class).completionTokens()).isEqualTo(2400);
                    assertThat(context.getBean(RateLimitProperties.class).enabled()).isTrue();
                    assertThat(context.getBean(RateLimitProperties.class).aiRequests()).isEqualTo(12);
                    assertThat(context.getBean(RateLimitProperties.class).aiWindow())
                            .isEqualTo(Duration.ofSeconds(30));
                    assertThat(context.getBean(NotificationProperties.class).staleCvDays()).isEqualTo(21);
                });
    }

    @Configuration(proxyBeanMethods = false)
    @EnableConfigurationProperties({
            CvQualityProperties.class,
            JobMatchProperties.class,
            AiSuggestionProperties.class,
            AiEnhancementProperties.class,
            RateLimitProperties.class,
            NotificationProperties.class
    })
    static class PropertiesConfiguration {
    }
}
