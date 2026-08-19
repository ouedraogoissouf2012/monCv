ALTER TABLE cvs ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_cvs_user_deleted_at
    ON cvs (user_id, deleted_at);
