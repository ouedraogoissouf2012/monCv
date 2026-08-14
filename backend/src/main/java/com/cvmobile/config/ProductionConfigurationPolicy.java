package com.cvmobile.config;

import org.springframework.stereotype.Component;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Base64;
import java.util.EnumSet;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Component
final class ProductionConfigurationPolicy {
    private static final Pattern DB_USERNAME = Pattern.compile("[A-Za-z_][A-Za-z0-9_-]{2,62}");
    private static final Pattern GOOGLE_CLIENT_ID = Pattern.compile(
            "[A-Za-z0-9-]{10,}\\.apps\\.googleusercontent\\.com");
    private static final Pattern HOSTNAME = Pattern.compile(
            "[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
                    + "(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+");
    private static final Pattern EMAIL = Pattern.compile(
            "[A-Za-z0-9._%+-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
                    + "(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+");
    // Plancher volontairement bas : le secret SMTP est fourni par le provider
    // (App Password 16c, cle API...) ; on rejette surtout le vide/placeholder/trivial.
    private static final int MAIL_PASSWORD_MIN_LENGTH = 8;
    private static final int MIN_PORT = 1;
    private static final int MAX_PORT = 65535;
    private static final Set<String> PLACEHOLDER_VALUES = Set.of(
            "change_me", "change-me", "changeme", "dummy", "password",
            "placeholder", "postgres", "secret", "tbd", "todo");
    private static final Set<String> PLACEHOLDER_PREFIXES = Set.of(
            "<", "change_me_", "change-me-", "deepseek_key_", "dev-compose-only-",
            "integrationtest-", "moncv-dev-only-", "replace_", "replace-",
            "testonly-", "your-", "your_");
    private static final byte[] LOCAL_PUBLIC_KEY =
            "0123456789abcdef0123456789abcdef".getBytes(StandardCharsets.US_ASCII);

    void validate(ProductionConfiguration configuration) {
        if (!configuration.isProduction()) return;
        EnumSet<ProductionSetting> invalid = EnumSet.noneOf(ProductionSetting.class);
        if (!configuration.activeProfiles().equals(Set.of("prod"))) {
            invalid.add(ProductionSetting.ACTIVE_PROFILES);
        }
        require(invalid, ProductionSetting.DEEPSEEK_API_KEY,
                validSecret(configuration.value(ProductionSetting.DEEPSEEK_API_KEY), 16));
        require(invalid, ProductionSetting.JWT_SECRET,
                validSecret(configuration.value(ProductionSetting.JWT_SECRET), 64));
        require(invalid, ProductionSetting.DB_PASSWORD,
                validSecret(configuration.value(ProductionSetting.DB_PASSWORD), 16));
        require(invalid, ProductionSetting.DB_USERNAME,
                validDatabaseUser(configuration.value(ProductionSetting.DB_USERNAME)));
        require(invalid, ProductionSetting.GOOGLE_CLIENT_ID,
                validGoogleClient(configuration.value(ProductionSetting.GOOGLE_CLIENT_ID)));
        require(invalid, ProductionSetting.ALLOWED_ORIGINS,
                validOrigins(configuration.value(ProductionSetting.ALLOWED_ORIGINS)));
        require(invalid, ProductionSetting.PUBLIC_MEDIA_ALLOWED_ORIGINS,
                validOrigins(configuration.value(ProductionSetting.PUBLIC_MEDIA_ALLOWED_ORIGINS)));
        require(invalid, ProductionSetting.PUBLIC_LINK_ENCRYPTION_KEY,
                validEncryptionKey(configuration.value(ProductionSetting.PUBLIC_LINK_ENCRYPTION_KEY)));
        require(invalid, ProductionSetting.DEEPSEEK_BASE_URL,
                validHttpsUri(configuration.value(ProductionSetting.DEEPSEEK_BASE_URL), false));
        require(invalid, ProductionSetting.AI_FALLBACK_ENABLED,
                exactBoolean(configuration.value(ProductionSetting.AI_FALLBACK_ENABLED), false));
        require(invalid, ProductionSetting.RATE_LIMIT_ENABLED,
                exactBoolean(configuration.value(ProductionSetting.RATE_LIMIT_ENABLED), true));
        require(invalid, ProductionSetting.RATE_LIMIT_ADMIN_BYPASS,
                exactBoolean(configuration.value(ProductionSetting.RATE_LIMIT_ADMIN_BYPASS), false));
        validateMail(configuration, invalid);
        if (!invalid.isEmpty()) {
            String names = invalid.stream().map(Enum::name).sorted()
                    .collect(Collectors.joining(", "));
            throw new IllegalStateException("Invalid production configuration: [" + names + "]");
        }
    }

    private void require(
            EnumSet<ProductionSetting> invalid,
            ProductionSetting setting,
            boolean valid
    ) {
        if (!valid) invalid.add(setting);
    }

    /**
     * Le mail est optionnel : desactive (defaut sur), on ne valide rien et l'app
     * retombe sur {@code LoggingPasswordResetEmailSender}. Active
     * ({@code MAIL_ENABLED=true}), les creds SMTP deviennent requises, sinon
     * l'{@code SmtpPasswordResetEmailSender} echouerait silencieusement a chaque envoi.
     */
    private void validateMail(
            ProductionConfiguration configuration,
            EnumSet<ProductionSetting> invalid
    ) {
        String enabled = configuration.value(ProductionSetting.MAIL_ENABLED);
        if (enabled != null && !isBoolean(enabled)) {
            // Valeur ininterpretable : impossible de decider s'il faut exiger les creds.
            invalid.add(ProductionSetting.MAIL_ENABLED);
            return;
        }
        if (!isTrue(enabled)) return;
        require(invalid, ProductionSetting.MAIL_HOST,
                validHost(configuration.value(ProductionSetting.MAIL_HOST)));
        require(invalid, ProductionSetting.MAIL_PORT,
                validPort(configuration.value(ProductionSetting.MAIL_PORT)));
        require(invalid, ProductionSetting.MAIL_USERNAME,
                validRequiredValue(configuration.value(ProductionSetting.MAIL_USERNAME)));
        require(invalid, ProductionSetting.MAIL_PASSWORD,
                validMailSecret(configuration.value(ProductionSetting.MAIL_PASSWORD)));
        require(invalid, ProductionSetting.MAIL_FROM,
                validEmail(configuration.value(ProductionSetting.MAIL_FROM)));
    }

    private boolean validSecret(String value, int minimumLength) {
        return value != null && value.equals(value.strip())
                && value.length() >= minimumLength && !isPlaceholder(value)
                && value.codePoints().distinct().count() >= 8;
    }

    private boolean validDatabaseUser(String value) {
        return value != null && value.equals(value.strip())
                && DB_USERNAME.matcher(value).matches() && !isPlaceholder(value);
    }

    private boolean validGoogleClient(String value) {
        return value != null && value.equals(value.strip())
                && GOOGLE_CLIENT_ID.matcher(value).matches() && !isPlaceholder(value);
    }

    private boolean isPlaceholder(String value) {
        String normalized = value.strip().toLowerCase(Locale.ROOT);
        return normalized.isEmpty() || PLACEHOLDER_VALUES.contains(normalized)
                || PLACEHOLDER_PREFIXES.stream().anyMatch(normalized::startsWith);
    }

    private boolean validOrigins(String value) {
        if (value == null || value.isBlank()) return false;
        return Arrays.stream(value.split(",", -1))
                .map(String::strip)
                .allMatch(origin -> validHttpsUri(origin, true));
    }

    private boolean validHttpsUri(String value, boolean originOnly) {
        if (value == null || value.isBlank() || !value.equals(value.strip())
                || value.contains("*")) return false;
        try {
            URI uri = URI.create(value);
            String host = uri.getHost();
            if (!uri.isAbsolute() || !"https".equalsIgnoreCase(uri.getScheme())
                    || host == null || uri.getUserInfo() != null
                    || uri.getRawQuery() != null || uri.getRawFragment() != null
                    || uri.getRawAuthority() == null || uri.getRawAuthority().endsWith(":")
                    || uri.getPort() == 0 || uri.getPort() > 65535
                    || reservedHost(host) || !uri.normalize().equals(uri)) return false;
            String path = uri.getRawPath();
            return !originOnly || path == null || path.isEmpty();
        } catch (IllegalArgumentException exception) {
            return false;
        }
    }

    private boolean reservedHost(String host) {
        String normalized = host.toLowerCase(Locale.ROOT).replace("[", "").replace("]", "");
        if (normalized.endsWith(".")) normalized = normalized.substring(0, normalized.length() - 1);
        return normalized.equals("localhost") || normalized.endsWith(".localhost")
                || normalized.startsWith("127.")
                || normalized.equals("::1") || normalized.equals("example.com")
                || normalized.endsWith(".example.com") || normalized.endsWith(".example")
                || normalized.endsWith(".invalid") || normalized.endsWith(".test");
    }

    private boolean validEncryptionKey(String value) {
        if (value == null || !value.equals(value.strip()) || isPlaceholder(value)) return false;
        try {
            byte[] decoded = Base64.getDecoder().decode(value);
            if (decoded.length != 32 || Arrays.equals(decoded, LOCAL_PUBLIC_KEY)) return false;
            return Arrays.stream(toUnsigned(decoded)).distinct().count() >= 12;
        } catch (IllegalArgumentException exception) {
            return false;
        }
    }

    private int[] toUnsigned(byte[] value) {
        int[] unsigned = new int[value.length];
        for (int index = 0; index < value.length; index++) unsigned[index] = value[index] & 0xff;
        return unsigned;
    }

    private boolean exactBoolean(String value, boolean expected) {
        return value != null && value.equals(value.strip())
                && Boolean.toString(expected).equalsIgnoreCase(value);
    }

    private boolean isBoolean(String value) {
        return exactBoolean(value, true) || exactBoolean(value, false);
    }

    private boolean isTrue(String value) {
        return exactBoolean(value, true);
    }

    private boolean validHost(String value) {
        return value != null && value.equals(value.strip()) && !isPlaceholder(value)
                && HOSTNAME.matcher(value).matches() && !reservedHost(value);
    }

    private boolean validPort(String value) {
        if (value == null || !value.equals(value.strip())) return false;
        try {
            int port = Integer.parseInt(value);
            return port >= MIN_PORT && port <= MAX_PORT;
        } catch (NumberFormatException exception) {
            return false;
        }
    }

    private boolean validRequiredValue(String value) {
        return value != null && value.equals(value.strip())
                && !value.isBlank() && !isPlaceholder(value);
    }

    private boolean validMailSecret(String value) {
        return value != null && value.equals(value.strip())
                && value.length() >= MAIL_PASSWORD_MIN_LENGTH && !isPlaceholder(value);
    }

    private boolean validEmail(String value) {
        if (value == null || !value.equals(value.strip()) || isPlaceholder(value)
                || !EMAIL.matcher(value).matches()) {
            return false;
        }
        return !reservedHost(value.substring(value.indexOf('@') + 1));
    }
}
