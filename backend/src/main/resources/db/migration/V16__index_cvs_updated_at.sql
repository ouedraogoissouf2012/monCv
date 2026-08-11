-- Index pour le cron de rappels de CV inactifs (M-5).
-- findStaleWithUser filtre sur cvs.updated_at ; sans index, chaque execution
-- quotidienne fait un seq scan complet de la table cvs (cout lineaire a sa
-- taille). Cet index rend le filtre par date logarithmique.
CREATE INDEX IF NOT EXISTS idx_cvs_updated_at ON cvs (updated_at);
