-- ============================================================
-- V5 - Persistance de la personnalisation visuelle des CV
-- ============================================================

ALTER TABLE cvs ADD COLUMN IF NOT EXISTS style_template_id VARCHAR(50) NOT NULL DEFAULT 'moderne';
ALTER TABLE cvs ADD COLUMN IF NOT EXISTS style_primary_color BIGINT NOT NULL DEFAULT 4280648683;
ALTER TABLE cvs ADD COLUMN IF NOT EXISTS style_font_family VARCHAR(100) NOT NULL DEFAULT 'Roboto';
