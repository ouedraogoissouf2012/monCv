-- Support des variantes CV (adapte a une offre d'emploi)
ALTER TABLE cvs ADD COLUMN parent_cv_id BIGINT REFERENCES cvs(id) ON DELETE SET NULL;
ALTER TABLE cvs ADD COLUMN variante_label VARCHAR(200);
