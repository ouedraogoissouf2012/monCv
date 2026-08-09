-- Jetons de reinitialisation de mot de passe (issue #381).
-- Le jeton n'est JAMAIS stocke en clair : seule son empreinte SHA-256 (hex, 64
-- caracteres) est persistee. Usage unique (used_at) et duree de vie courte
-- (expires_at). Supprime avec l'utilisateur (ON DELETE CASCADE).
CREATE TABLE password_reset_token (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    used_at    TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_password_reset_token_user_id ON password_reset_token(user_id);
