package com.cvmobile.config;

import com.cvmobile.exception.ai.AiKeyInvalidException;
import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.service.ai.client.DeepSeekClient;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.test.util.ReflectionTestUtils;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(OutputCaptureExtension.class)
class AppStartupValidatorTest {

    private static final Map<String, Object> PRODUCTION_PROPERTIES = Map.ofEntries(
            Map.entry("ai.deepseek.api-key", "provider-" + "A1b2C3d4".repeat(4)),
            Map.entry("ai.deepseek.base-url", "https://api.deepseek.com/v1"),
            Map.entry("jwt.secret", "Aa1!Bb2@".repeat(10)),
            Map.entry("spring.datasource.username", "moncv_application"),
            Map.entry("spring.datasource.password", "Db9!" + "secure".repeat(4)),
            Map.entry("cors.allowed-origins", "https://cv.acme.org"),
            Map.entry("security.public-portfolio.encryption-key", productionEncryptionKey()),
            Map.entry("security.public-portfolio.allowed-media-origins", "https://cv.acme.org"),
            Map.entry("google.auth.client-id", "1234567890-abcdef.apps.googleusercontent.com"),
            Map.entry("ai.fallback.enabled", "false"),
            Map.entry("security.rate-limit.enabled", "true"),
            Map.entry("security.rate-limit.admin-bypass", "false"));

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
                    "test-secrets", Map.of("spring.datasource.password", "local-test-password")));
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
        AppStartupValidator validator = validator(environment("test"));

        assertThatCode(validator::validateSecrets).doesNotThrowAnyException();

        org.assertj.core.api.Assertions.assertThat(output)
                .doesNotContain("CV Mobile Startup Config")
                .doesNotContain("MISSING");
    }

    @Test
    void developmentLogsWarningsButStartsWhenDatabasePasswordExists(CapturedOutput output) {
        ConfigurableEnvironment environment = environment("dev");
        environment.getPropertySources().addFirst(new MapPropertySource(
                "development-secrets",
                Map.of("spring.datasource.password", "local-database-password")));
        AppStartupValidator validator = validator(environment);

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
                    "test-secrets",
                    Map.of("spring.datasource.password", "production-test-password")));

            assertThatThrownBy(context::refresh)
                    .hasRootCauseInstanceOf(IllegalStateException.class)
                    .rootCause()
                    .hasMessageContaining("DEEPSEEK_API_KEY")
                    .hasMessageContaining("JWT_SECRET")
                    .hasMessageContaining("ALLOWED_ORIGINS")
                    .hasMessageContaining("PUBLIC_MEDIA_ALLOWED_ORIGINS");
        }
    }

    @Test
    void productionStartsWithAllSecretsAndNeverLogsTheirValues(CapturedOutput output) {
        try (var context = validatorContext("prod")) {
            context.getEnvironment().getPropertySources().addFirst(
                    new MapPropertySource("production-properties", PRODUCTION_PROPERTIES));
            assertThatCode(context::refresh).doesNotThrowAnyException();
        }

        org.assertj.core.api.Assertions.assertThat(output)
                .contains("CV Mobile Startup Config")
                .contains("SET")
                .doesNotContain("length=")
                .doesNotContain("source:");
        PRODUCTION_PROPERTIES.values().forEach(secret ->
                org.assertj.core.api.Assertions.assertThat(output).doesNotContain(secret.toString()));
    }

    @Test
    void mixedProductionAndTestProfilesAreRejectedBeforeTestBypass() {
        ConfigurableEnvironment environment = environment("prod", "test");
        environment.getPropertySources().addFirst(
                new MapPropertySource("production-properties", PRODUCTION_PROPERTIES));
        AppStartupValidator validator = validator(environment);

        assertThatThrownBy(validator::validateSecrets)
                .hasMessageContaining("ACTIVE_PROFILES");
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
                "spring.datasource.password", "",
                "jwt.secret", "",
                "ai.deepseek.api-key", "",
                "cors.allowed-origins", "",
                "google.auth.client-id", "")));
        context.register(ProductionConfigurationPolicy.class, AppStartupValidator.class);
        return context;
    }

    private ConfigurableEnvironment environment(String... profiles) {
        ConfigurableEnvironment environment = new StandardEnvironment();
        environment.setActiveProfiles(profiles);
        return environment;
    }

    private static String productionEncryptionKey() {
        return Base64.getEncoder().encodeToString(
                "production-policy-key-32-bytes!!".getBytes(StandardCharsets.US_ASCII));
    }

    private AppStartupValidator validatorWithClient(
            ConfigurableEnvironment environment, DeepSeekClient deepSeek) {
        AppStartupValidator validator = validator(environment);
        ReflectionTestUtils.setField(validator, "deepSeekClient", deepSeek);
        return validator;
    }

    private AppStartupValidator validator(ConfigurableEnvironment environment) {
        return new AppStartupValidator(environment, new ProductionConfigurationPolicy());
    }
}
