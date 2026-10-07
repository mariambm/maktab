-- Extensions used across the schema.
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS citext;    -- case-insensitive email
CREATE EXTENSION IF NOT EXISTS pg_trgm;   -- name search (used from Phase 2)

CREATE TABLE organisation (
    id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name                     varchar(200) NOT NULL,
    time_zone                varchar(64)  NOT NULL DEFAULT 'Europe/Amsterdam',
    currency                 varchar(3)   NOT NULL DEFAULT 'EUR' CHECK (currency ~ '^[A-Z]{3}$'),
    attendance_threshold_pct smallint     NOT NULL DEFAULT 80
        CHECK (attendance_threshold_pct BETWEEN 0 AND 100),
    created_at               timestamptz  NOT NULL DEFAULT now(),
    updated_at               timestamptz  NOT NULL DEFAULT now(),
    version                  bigint       NOT NULL DEFAULT 0
);

-- Maktab runs as a single organisation for now; organisation_id columns keep
-- the schema ready for multiple mosques later.
INSERT INTO organisation (id, name) VALUES ('00000000-0000-0000-0000-000000000001', 'Maktab');
