-- Compteur de vues rapide sur la table cvs
ALTER TABLE cvs ADD COLUMN view_count INTEGER NOT NULL DEFAULT 0;

-- Table de suivi detaille des vues (anti-doublon par IP hashee)
CREATE TABLE cv_views (
    id BIGSERIAL PRIMARY KEY,
    cv_id BIGINT NOT NULL REFERENCES cvs(id) ON DELETE CASCADE,
    ip_hash VARCHAR(16) NOT NULL,
    viewed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_cv_views_cv_id ON cv_views(cv_id);
CREATE INDEX idx_cv_views_dedup ON cv_views(cv_id, ip_hash, viewed_at);
