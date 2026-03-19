-- ============================================================
-- V1 - Schéma initial de la base de données CV Mobile
-- ============================================================

-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS users (
    id          BIGSERIAL PRIMARY KEY,
    email       VARCHAR(255) NOT NULL UNIQUE,
    password    VARCHAR(255) NOT NULL,
    nom         VARCHAR(100),
    prenom      VARCHAR(100),
    role        VARCHAR(20)  NOT NULL DEFAULT 'USER',
    created_at  TIMESTAMP,
    updated_at  TIMESTAMP
);

-- Table des CVs (avec PersonalInfo embarquée)
CREATE TABLE IF NOT EXISTS cvs (
    id                   BIGSERIAL PRIMARY KEY,
    titre                VARCHAR(255) NOT NULL,
    user_id              BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- PersonalInfo (embedded)
    nom                  VARCHAR(100),
    prenom               VARCHAR(100),
    email                VARCHAR(255),
    telephone            VARCHAR(30),
    adresse              VARCHAR(255),
    ville                VARCHAR(100),
    code_postal          VARCHAR(20),
    pays                 VARCHAR(100),
    photo_url            VARCHAR(500),
    linked_in            VARCHAR(255),
    portfolio            VARCHAR(255),
    titre_poste          VARCHAR(255),
    resume_professionnel TEXT,

    created_at  TIMESTAMP,
    updated_at  TIMESTAMP
);

-- Table des formations
CREATE TABLE IF NOT EXISTS educations (
    id             BIGSERIAL PRIMARY KEY,
    cv_id          BIGINT NOT NULL REFERENCES cvs(id) ON DELETE CASCADE,
    etablissement  VARCHAR(255),
    diplome        VARCHAR(255),
    domaine        VARCHAR(255),
    date_debut     DATE,
    date_fin       DATE,
    description    VARCHAR(1000)
);

-- Table des expériences professionnelles
CREATE TABLE IF NOT EXISTS experiences (
    id           BIGSERIAL PRIMARY KEY,
    cv_id        BIGINT NOT NULL REFERENCES cvs(id) ON DELETE CASCADE,
    entreprise   VARCHAR(255),
    poste        VARCHAR(255),
    lieu         VARCHAR(255),
    date_debut   DATE,
    date_fin     DATE,
    description  VARCHAR(2000),
    actuel       BOOLEAN NOT NULL DEFAULT FALSE
);

-- Table des compétences
CREATE TABLE IF NOT EXISTS skills (
    id        BIGSERIAL PRIMARY KEY,
    cv_id     BIGINT NOT NULL REFERENCES cvs(id) ON DELETE CASCADE,
    nom       VARCHAR(255),
    niveau    INTEGER CHECK (niveau BETWEEN 1 AND 5),
    categorie VARCHAR(100)
);

-- Table des langues
CREATE TABLE IF NOT EXISTS languages (
    id      BIGSERIAL PRIMARY KEY,
    cv_id   BIGINT NOT NULL REFERENCES cvs(id) ON DELETE CASCADE,
    langue  VARCHAR(100),
    niveau  VARCHAR(10) CHECK (niveau IN ('A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'NATIF'))
);

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_cvs_user_id      ON cvs(user_id);
CREATE INDEX IF NOT EXISTS idx_educations_cv_id  ON educations(cv_id);
CREATE INDEX IF NOT EXISTS idx_experiences_cv_id ON experiences(cv_id);
CREATE INDEX IF NOT EXISTS idx_skills_cv_id      ON skills(cv_id);
CREATE INDEX IF NOT EXISTS idx_languages_cv_id   ON languages(cv_id);
