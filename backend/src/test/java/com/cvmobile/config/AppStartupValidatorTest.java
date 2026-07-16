package com.cvmobile.config;

import com.cvmobile.exception.ai.AiKeyInvalidException;
import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.service.ai.client.DeepSeekClient;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(OutputCaptureExtension.class)
class AppStartupValidatorTest {

    private static final Map<String, Object> PRODUCTION_SECRETS = Map.of(
            "DEEPSEEK_API_KEY", "deepseek-secret-value",
            "JWT_SECRET", "jwt-secret-value-with-enough-length",
            "DB_PASSWORD", "database-secret-value",
            "ALLOWED_ORIGINS", "https://app.example.com",
            "PUBLIC_LINK_ENCRYPTION_KEY",
            "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=");

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
    void testProfileReturnsBeforeValidationAndDoesNotLogBanner(CapturedOutput output) {
        AppStartupValidator validator = new AppStartupValidator(environment("test"));

        assertThatCode(validator::validateSecrets).doesNotThrowAnyException();

        org.assertj.core.api.Assertions.assertThat(output)
                .doesNotContain("CV Mobile Startup Config")
                .doesNotContain("MISSING");
    }

    @Test
    void developmentLogsWarningsButStartsWhenDatabasePasswordExists(CapturedOutput output) {
        ConfigurableEnvironment environment = environment("dev");
        environment.getPropertySources().addFirst(new MapPropertySource(
                "development-secrets", Map.of("DB_PASSWORD", "local-database-password")));
        AppStartupValidator validator = new AppStartupValidator(environment);

        assertThatCode(validator::validateSecrets).doesNotThrowAnyException();

        org.assertj.core.api.Assertions.assertThat(output)
                .contains("DEEPSEEK_API_KEY")
                .contains("MISSING")
                .contains("DeepSeek desactive");
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
                    .hasMessageContaining("ALLOWED_ORIGINS")
                    .hasMessageContaining("PUBLIC_LINK_ENCRYPTION_KEY");
        }
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "DEEPSEEK_API_KEY",
            "JWT_SECRET",
            "DB_PASSWORD",
            "ALLOWED_ORIGINS",
            "PUBLIC_LINK_ENCRYPTION_KEY"
    })
    void productionFailsForEachMissingRequiredSecret(String missingSecret) {
        ConfigurableEnvironment environment = environment("prod");
        Map<String, Object> secrets = new HashMap<>(PRODUCTION_SECRETS);
        secrets.put(missingSecret, "");
        environment.getPropertySources().addFirst(new MapPropertySource("test-secrets", secrets));
        AppStartupValidator validator = new AppStartupValidator(environment);

        assertThatThrownBy(validator::validateSecrets)
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining(missingSecret);
    }

    @Test
    void productionStartsWithAllSecretsAndNeverLogsTheirValues(CapturedOutput output) {
        ConfigurableEnvironment environment = environment("prod");
        environment.getPropertySources().addFirst(
                new MapPropertySource("applicationConfig: [classpath:/application.yml]", PRODUCTION_SECRETS));
        AppStartupValidator validator = new AppStartupValidator(environment);

        assertThatCode(validator::validateSecrets).doesNotThrowAnyException();

        org.assertj.core.api.Assertions.assertThat(output)
                .contains("CV Mobile Startup Config")
                .contains("source: application.yml")
                .contains("length=");
        PRODUCTION_SECRETS.values().forEach(secret ->
                org.assertj.core.api.Assertions.assertThat(output).doesNotContain(secret.toString()));
    }

    @Test
    void reportsDotenvSystemEnvironmentAndApplicationSources(CapturedOutput output) {
        ConfigurableEnvironment environment = environment("prod");
        environment.getPropertySources().addFirst(new MapPropertySource(
                "applicationConfig: [classpath:/application.yml]",
                Map.of(
                        "DB_PASSWORD", "database-value",
                        "ALLOWED_ORIGINS", "https://app.example.com",
                        "PUBLIC_LINK_ENCRYPTION_KEY",
                        "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=")));
        environment.getPropertySources().addFirst(new MapPropertySource(
                "systemEnvironment-test", Map.of("JWT_SECRET", "jwt-value")));
        environment.getPropertySources().addFirst(new MapPropertySource(
                "dotenv-test", Map.of("DEEPSEEK_API_KEY", "deepseek-value")));
        AppStartupValidator validator = new AppStartupValidator(environment);

        validator.validateSecrets();

        org.assertj.core.api.Assertions.assertThat(output)
                .contains("source: dotenv")
                .contains("source: systemEnvironment")
                .contains("source: application.yml");
    }

    @Test
    void productionStartupProbeFailsWhenProviderRejectsKey() {
        ConfigurableEnvironment environment = environment("prod");
        DeepSeekClient deepSeek = mock(DeepSeekClient.class);
        when(deepSeek.complete("Reponds uniquement par OK.", 8))
                .thenThrow(new AiKeyInvalidException("deepseek", null));
        AppStartupValidator validator = validatorWithClient(environment, deepSeek);

        assertThatThrownBy(() -> validator.onApplicationEvent(null))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("DEEPSEEK_API_KEY");
    }

    @Test
    void productionStartupProbeAllowsTransientProviderFailure() {
        ConfigurableEnvironment environment = environment("prod");
        DeepSeekClient deepSeek = mock(DeepSeekClient.class);
        when(deepSeek.complete("Reponds uniquement par OK.", 8))
                .thenThrow(new AiProviderDownException("deepseek", "HTTP 503", null));
        AppStartupValidator validator = validatorWithClient(environment, deepSeek);

        assertThatCode(() -> validator.onApplicationEvent(null)).doesNotThrowAnyException();
    }

    @Test
    void developmentStartupProbeAllowsInvalidKey() {
        ConfigurableEnvironment environment = environment("dev");
        DeepSeekClient deepSeek = mock(DeepSeekClient.class);
        when(deepSeek.complete("Reponds uniquement par OK.", 8))
                .thenThrow(new AiKeyInvalidException("deepseek", null));
        AppStartupValidator validator = validatorWithClient(environment, deepSeek);

        assertThatCode(() -> validator.onApplicationEvent(null)).doesNotThrowAnyException();
    }

    @Test
    void testProfileSkipsStartupProbe() {
        ConfigurableEnvironment environment = environment("test");
        DeepSeekClient deepSeek = mock(DeepSeekClient.class);
        AppStartupValidator validator = validatorWithClient(environment, deepSeek);

        validator.onApplicationEvent(null);

        verify(deepSeek, never()).complete("Reponds uniquement par OK.", 8);
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

    private ConfigurableEnvironment environment(String profile) {
        ConfigurableEnvironment environment = new StandardEnvironment();
        environment.setActiveProfiles(profile);
        return environment;
    }

    private AppStartupValidator validatorWithClient(
            ConfigurableEnvironment environment, DeepSeekClient deepSeek) {
        AppStartupValidator validator = new AppStartupValidator(environment);
        ReflectionTestUtils.setField(validator, "deepSeekClient", deepSeek);
        return validator;
    }
}
