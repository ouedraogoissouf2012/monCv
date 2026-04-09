-- Index pour accelerer les requetes de comptage de variantes par CV parent
CREATE INDEX idx_cvs_parent_cv_id ON cvs(parent_cv_id);
