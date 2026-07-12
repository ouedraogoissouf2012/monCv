CREATE TABLE notification_preferences (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    stale_cv_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    cv_views_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    ai_tips_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE device_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(512) NOT NULL UNIQUE,
    platform VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_device_tokens_user_id ON device_tokens(user_id);

CREATE TABLE notification_deliveries (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    cv_id BIGINT REFERENCES cvs(id) ON DELETE CASCADE,
    notification_type VARCHAR(40) NOT NULL,
    deduplication_key VARCHAR(160) NOT NULL UNIQUE,
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_notification_deliveries_user_id ON notification_deliveries(user_id);
