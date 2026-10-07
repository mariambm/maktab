-- Append-only record of important changes. Never stores passwords or tokens.
CREATE TABLE audit_log (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id uuid         NOT NULL REFERENCES organisation (id),
    user_id         uuid REFERENCES app_user (id),
    action          varchar(60)  NOT NULL,
    entity_type     varchar(60)  NOT NULL,
    entity_id       uuid,
    occurred_at     timestamptz  NOT NULL DEFAULT now(),
    old_value       jsonb,
    new_value       jsonb,
    ip_address      varchar(45)
);

CREATE INDEX ix_audit_log_entity ON audit_log (entity_type, entity_id);
CREATE INDEX ix_audit_log_occurred_at ON audit_log (occurred_at);
CREATE INDEX ix_audit_log_user ON audit_log (user_id);
