CREATE TABLE refresh_token (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid        NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
    family_id   uuid        NOT NULL,
    token_hash  varchar(64) NOT NULL UNIQUE,
    expires_at  timestamptz NOT NULL,
    revoked_at  timestamptz,
    replaced_by uuid REFERENCES refresh_token (id),
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ix_refresh_token_user ON refresh_token (user_id);
CREATE INDEX ix_refresh_token_family ON refresh_token (family_id);
