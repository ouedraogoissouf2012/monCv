package com.cvmobile.config;

import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AppStartupValidatorTest {

    @Test
    void applicationContextFailsWithoutDatabasePassword() {
        try (var context = validatorContext("dev")) {
            assertThatThrownBy(context::refresh)
                    .hasRootCauseInstanceOf(IllegalStateException.class)
                    .rootCause()
                    .hasMessageContaining("DB_PASSWORD");
        }
    }

    @Test
    void applicationContextStartsWhenDevelopmentRequirementsArePresent() {
        try (var context = validatorContext("dev")) {
            context.getEnvironment().getPropertySources().addFirst(new MapPropertySource(
                    "test-secrets", Map.of("DB_PASSWORD", "local-test-password")));
            assertThatCode(context::refresh).doesNotThrowAnyException();
        }
    }

    @Test
    void testProfileDoesNotRequireProductionSecrets() {
        try (var context = validatorContext("test")) {
            assertThatCode(context::refresh).doesNotThrowAnyException();
        }
    }

    @Test
    void productionContextFailsWhenCriticalSecretsAreMissing() {
        try (var context = validatorContext("prod")) {
            context.getEnvironment().getPropertySources().addFirst(new MapPropertySource(
                    "test-secrets", Map.of("DB_PASSWORD", "production-test-password")));

            assertThatThrownBy(context::refresh)
                    .hasRootCauseInstanceOf(IllegalStateException.class)
                    .rootCause()
                    .hasMessageContaining("DEEPSEEK_API_KEY")
                    .hasMessageContaining("JWT_SECRET")
                    .hasMessageContaining("ALLOWED_ORIGINS");
        }
    }

    private AnnotationConfigApplicationContext validatorContext(String profile) {
        var context = new AnnotationConfigApplicationContext();
        ConfigurableEnvironment environment = context.getEnvironment();
        environment.setActiveProfiles(profile);
        environment.getPropertySources().addFirst(new MapPropertySource("masked-system-secrets", Map.of(
                "DB_PASSWORD", "",
                "JWT_SECRET", "",
                "DEEPSEEK_API_KEY", "",
                "ALLOWED_ORIGINS", "")));
        context.registerBean(AppStartupValidator.class, () -> new AppStartupValidator(environment));
        return context;
    }
}
