CREATE TABLE job_applications (
    id              BIGSERIAL PRIMARY KEY,
    user_id         BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    cv_id           BIGINT REFERENCES cvs(id) ON DELETE SET NULL,
    company         VARCHAR(200) NOT NULL,
    position        VARCHAR(200) NOT NULL,
    offer_url       VARCHAR(500),
    status          VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    sent_date       DATE,
    next_follow_up  DATE,
    notes           TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_job_application_status CHECK (
        status IN ('DRAFT', 'SENT', 'INTERVIEW', 'TECHNICAL_TEST', 'OFFER', 'REJECTED', 'ARCHIVED')
    )
);

CREATE INDEX idx_job_applications_user_id ON job_applications(user_id);
CREATE INDEX idx_job_applications_user_status ON job_applications(user_id, status);
CREATE INDEX idx_job_applications_follow_up ON job_applications(next_follow_up);
