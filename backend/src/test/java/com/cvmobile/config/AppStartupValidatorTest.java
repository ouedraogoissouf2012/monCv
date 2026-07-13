package com.cvmobile.config;

import com.cvmobile.exception.ai.AiKeyInvalidException;
import com.cvmobile.exception.ai.AiProviderDownException;
import com.cvmobile.service.ai.client.DeepSeekClient;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

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
