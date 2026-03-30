-- ============================================================
-- V2 - Ajout des tables certifications et projets
-- ============================================================

CREATE TABLE IF NOT EXISTS certifications (
    id               BIGSERIAL PRIMARY KEY,
    cv_id            BIGINT NOT NULL REFERENCES cvs(id) ON DELETE CASCADE,
    nom              VARCHAR(255),
    organisme        VARCHAR(255),
    date_obtention   DATE,
    date_expiration  DATE,
    credential_url   VARCHAR(500)
);

CREATE TABLE IF NOT EXISTS projects (
    id           BIGSERIAL PRIMARY KEY,
    cv_id        BIGINT NOT NULL REFERENCES cvs(id) ON DELETE CASCADE,
    nom          VARCHAR(255),
    description  VARCHAR(1000),
    technologies VARCHAR(500),
    lien         VARCHAR(500),
    date_debut   DATE,
    date_fin     DATE
);

CREATE INDEX IF NOT EXISTS idx_certifications_cv_id ON certifications(cv_id);
CREATE INDEX IF NOT EXISTS idx_projects_cv_id       ON projects(cv_id);
