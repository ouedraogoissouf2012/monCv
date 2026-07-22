package com.cvmobile.config;

import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class ProductionConfigurationPolicyTest {
    private final ProductionConfigurationPolicy policy = new ProductionConfigurationPolicy();

    @Test
    void acceptsAValidProductionConfiguration() {
        assertThatCode(() -> policy.validate(validConfiguration()))
                .doesNotThrowAnyException();
    }

    @Test
    void ignoresNonProductionProfilesToPreserveLocalDefaults() {
        ProductionConfiguration development = configuration(
                Set.of("dev"), ProductionSetting.DB_PASSWORD, null);

        assertThatCode(() -> policy.validate(development)).doesNotThrowAnyException();
    }

    @Test
    void rejectsEveryProfileMixedWithProduction() {
        for (String profile : List.of("dev", "test", "staging")) {
            ProductionConfiguration mixed = new ProductionConfiguration(
                    Set.of("prod", profile), validValues());

            assertThatThrownBy(() -> policy.validate(mixed))
                    .hasMessageContaining(ProductionSetting.ACTIVE_PROFILES.name())
                    .hasMessageNotContaining(profile);
        }
    }

    @Test
    void rejectsEveryMissingProductionSetting() {
        for (ProductionSetting setting : validValues().keySet()) {
            assertInvalid(setting, null);
        }
    }

    @Test
    void rejectsWeakKnownAndPlaceholderCredentials() {
        Map<ProductionSetting, List<String>> invalid = Map.of(
                ProductionSetting.DEEPSEEK_API_KEY,
                List.of("short", "a".repeat(32), "deepseek_key_placeholder", " replace-me"),
                ProductionSetting.JWT_SECRET,
                List.of("short", "A".repeat(80), "moncv-dev-only-value", "<generated-secret>"),
                ProductionSetting.DB_USERNAME,
                List.of("postgres", "x", "change_me_user"),
                ProductionSetting.DB_PASSWORD,
                List.of("short", "a".repeat(20), "change_me_local_db_password", " password"),
                ProductionSetting.GOOGLE_CLIENT_ID,
                List.of("short", "your-web-client-id.apps.googleusercontent.com"));

        invalid.forEach((setting, values) -> values.forEach(value -> assertInvalid(setting, value)));
    }

    @Test
    void acceptsOnlyStrictHttpsOrigins() {
        for (ProductionSetting setting : List.of(
                ProductionSetting.ALLOWED_ORIGINS,
                ProductionSetting.PUBLIC_MEDIA_ALLOWED_ORIGINS)) {
            for (String value : List.of(
                    "", "*", "http://cv.acme.org", "/relative",
                    "https://user:password@cv.acme.org", "https://cv.acme.org/path",
                    "https://cv.acme.org?query=1", "https://cv.acme.org#fragment",
                    "https://localhost", "https://sub.localhost", "https://127.0.0.2",
                    "https://example.com", "https://example.com.", "https://cv.acme.org:",
                    "https://cv.acme.org:0", "https://cv.acme.org:99999",
                    "https://cv.acme.org,,https://media.acme.org")) {
                assertInvalid(setting, value);
            }
        }

        ProductionConfiguration multiple = configuration(
                Set.of("prod"), ProductionSetting.ALLOWED_ORIGINS,
                "https://cv.acme.org, https://admin.acme.org:8443");
        assertThatCode(() -> policy.validate(multiple)).doesNotThrowAnyException();
    }

    @Test
    void rejectsMalformedWeakAndDevelopmentEncryptionKeys() {
        for (String value : List.of(
                "not-base64",
                encode(new byte[31]),
                encode(new byte[32]),
                encode("ab".repeat(16).getBytes(StandardCharsets.US_ASCII)),
                encode("0123456789abcdef0123456789abcdef".getBytes(StandardCharsets.US_ASCII)))) {
            assertInvalid(ProductionSetting.PUBLIC_LINK_ENCRYPTION_KEY, value);
        }
    }

    @Test
    void acceptsOnlyAConfidentialHttpsProviderEndpoint() {
        for (String value : List.of(
                "http://api.deepseek.com/v1", "/v1", "https://user@api.deepseek.com/v1",
                "https://api.deepseek.com/v1?token=value",
                "https://api.deepseek.com/v1#fragment", "https://localhost/v1",
                "https://api.example.com/v1", "https://api.deepseek.com/v1/../admin",
                "https://api.deepseek.com:")) {
            assertInvalid(ProductionSetting.DEEPSEEK_BASE_URL, value);
        }
    }

    @Test
    void requiresHardenedProductionFlags() {
        assertInvalid(ProductionSetting.AI_FALLBACK_ENABLED, "true");
        assertInvalid(ProductionSetting.AI_FALLBACK_ENABLED, "disabled");
        assertInvalid(ProductionSetting.RATE_LIMIT_ENABLED, "false");
        assertInvalid(ProductionSetting.RATE_LIMIT_ENABLED, "enabled");
        assertInvalid(ProductionSetting.RATE_LIMIT_ADMIN_BYPASS, "true");
    }

    private void assertInvalid(ProductionSetting setting, String value) {
        var assertion = assertThatThrownBy(() -> policy.validate(
                configuration(Set.of("prod"), setting, value)))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining(setting.name());
        if (value != null && !value.isEmpty()) assertion.hasMessageNotContaining(value);
    }

    private ProductionConfiguration validConfiguration() {
        return new ProductionConfiguration(Set.of("prod"), validValues());
    }

    private ProductionConfiguration configuration(
            Set<String> profiles,
            ProductionSetting setting,
            String value
    ) {
        EnumMap<ProductionSetting, String> values = validValues();
        values.put(setting, value);
        return new ProductionConfiguration(profiles, values);
    }

    private EnumMap<ProductionSetting, String> validValues() {
        EnumMap<ProductionSetting, String> values = new EnumMap<>(ProductionSetting.class);
        values.put(ProductionSetting.DEEPSEEK_API_KEY, "provider-" + "A1b2C3d4".repeat(4));
        values.put(ProductionSetting.DEEPSEEK_BASE_URL, "https://api.deepseek.com/v1");
        values.put(ProductionSetting.JWT_SECRET, "Aa1!Bb2@".repeat(10));
        values.put(ProductionSetting.DB_USERNAME, "moncv_application");
        values.put(ProductionSetting.DB_PASSWORD, "Db9!" + "secure".repeat(4));
        values.put(ProductionSetting.ALLOWED_ORIGINS, "https://cv.acme.org");
        values.put(ProductionSetting.PUBLIC_LINK_ENCRYPTION_KEY,
                encode("production-policy-key-32-bytes!!".getBytes(StandardCharsets.US_ASCII)));
        values.put(ProductionSetting.PUBLIC_MEDIA_ALLOWED_ORIGINS, "https://cv.acme.org");
        values.put(ProductionSetting.GOOGLE_CLIENT_ID,
                "1234567890-abcdef.apps.googleusercontent.com");
        values.put(ProductionSetting.AI_FALLBACK_ENABLED, "false");
        values.put(ProductionSetting.RATE_LIMIT_ENABLED, "true");
        values.put(ProductionSetting.RATE_LIMIT_ADMIN_BYPASS, "false");
        return values;
    }

    private String encode(byte[] value) {
        return Base64.getEncoder().encodeToString(value);
    }
}
