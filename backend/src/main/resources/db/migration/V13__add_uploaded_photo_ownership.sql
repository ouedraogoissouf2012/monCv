CREATE TABLE uploaded_photos (
    filename   VARCHAR(64) PRIMARY KEY,
    user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_uploaded_photos_user_id ON uploaded_photos(user_id);

WITH photo_references AS (
    SELECT user_id,
           substring(photo_url FROM
               '/api/uploads/photos/([0-9A-Fa-f-]{36}\.[A-Za-z]+)') AS filename
    FROM cvs
    WHERE photo_url IS NOT NULL
), unique_photos AS (
    SELECT filename, MIN(user_id) AS user_id
    FROM photo_references
    WHERE filename ~ '^[0-9A-Fa-f-]{36}\.(jpg|jpeg|png|webp)$'
    GROUP BY filename
)
INSERT INTO uploaded_photos(filename, user_id)
SELECT filename, user_id
FROM unique_photos;
