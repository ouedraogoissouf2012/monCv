-- Agrandir les colonnes texte pour supporter le contenu genere par l'IA
-- Le resume professionnel et les descriptions peuvent depasser 255 caracteres

ALTER TABLE cvs ALTER COLUMN resume_professionnel TYPE TEXT;
ALTER TABLE cvs ALTER COLUMN titre_poste TYPE VARCHAR(500);

ALTER TABLE experiences ALTER COLUMN description TYPE TEXT;
ALTER TABLE experiences ALTER COLUMN poste TYPE VARCHAR(500);

ALTER TABLE educations ALTER COLUMN description TYPE TEXT;

ALTER TABLE projects ALTER COLUMN description TYPE TEXT;

ALTER TABLE certifications ALTER COLUMN nom TYPE VARCHAR(500);
