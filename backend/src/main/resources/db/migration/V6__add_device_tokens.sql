-- Table des tokens FCM pour les notifications push
CREATE TABLE device_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    platform VARCHAR(20) NOT NULL DEFAULT 'ANDROID',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_device_token UNIQUE (token)
);

CREATE INDEX idx_device_tokens_user_id ON device_tokens(user_id);
