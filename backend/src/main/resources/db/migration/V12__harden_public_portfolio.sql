ALTER TABLE cvs ADD COLUMN IF NOT EXISTS public_token_hash VARCHAR(64);

ALTER TABLE cvs ALTER COLUMN public_token TYPE VARCHAR(160);

CREATE UNIQUE INDEX IF NOT EXISTS idx_cvs_public_token_hash
    ON cvs(public_token_hash)
    WHERE public_token_hash IS NOT NULL;

-- La deduplication des vues est maintenant atomique dans Redis et ne conserve
-- plus de pseudonymes d'adresses IP en base relationnelle.
DROP TABLE IF EXISTS cv_views;
