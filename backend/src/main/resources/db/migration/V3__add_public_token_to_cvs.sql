-- ============================================================
-- V3 - Ajout du token de partage public sur les CV
-- ============================================================

ALTER TABLE cvs ADD COLUMN IF NOT EXISTS public_token VARCHAR(64) UNIQUE;

CREATE UNIQUE INDEX IF NOT EXISTS idx_cvs_public_token ON cvs(public_token) WHERE public_token IS NOT NULL;
