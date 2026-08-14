package com.cvmobile.config;

enum ProductionSetting {
    ACTIVE_PROFILES("spring.profiles.active", false),
    DEEPSEEK_API_KEY("ai.deepseek.api-key", true),
    DEEPSEEK_BASE_URL("ai.deepseek.base-url", false),
    JWT_SECRET("jwt.secret", true),
    DB_USERNAME("spring.datasource.username", true),
    DB_PASSWORD("spring.datasource.password", true),
    ALLOWED_ORIGINS("cors.allowed-origins", true),
    PUBLIC_LINK_ENCRYPTION_KEY("security.public-portfolio.encryption-key", true),
    PUBLIC_MEDIA_ALLOWED_ORIGINS("security.public-portfolio.allowed-media-origins", true),
    GOOGLE_CLIENT_ID("google.auth.client-id", true),
    AI_FALLBACK_ENABLED("ai.fallback.enabled", false),
    RATE_LIMIT_ENABLED("security.rate-limit.enabled", false),
    RATE_LIMIT_ADMIN_BYPASS("security.rate-limit.admin-bypass", false),
    // Envoi SMTP du reset password (issue #487). Non suivi au demarrage (banniere) :
    // le mail est optionnel et desactive par defaut. Valide seulement si MAIL_ENABLED=true.
    MAIL_ENABLED("mail.enabled", false),
    MAIL_HOST("spring.mail.host", false),
    MAIL_PORT("spring.mail.port", false),
    MAIL_USERNAME("spring.mail.username", false),
    MAIL_PASSWORD("spring.mail.password", false),
    MAIL_FROM("mail.from", false);

    private final String propertyName;
    private final boolean trackedAtStartup;

    ProductionSetting(String propertyName, boolean trackedAtStartup) {
        this.propertyName = propertyName;
        this.trackedAtStartup = trackedAtStartup;
    }

    String propertyName() {
        return propertyName;
    }

    boolean trackedAtStartup() {
        return trackedAtStartup;
    }
}
