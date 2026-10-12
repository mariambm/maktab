-- Monthly fees. A payment period is one calendar month with the organisation's fee for it; opening a month gives
-- every student enrolled that month a payment row with the amount expected. Whether a row is paid, partly paid or
-- outstanding is worked out from the amounts on read and never stored.
CREATE TABLE payment_period (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id uuid          NOT NULL REFERENCES organisation (id),
    -- The first day of the month.
    month           date          NOT NULL CHECK (extract(day FROM month) = 1),
    monthly_fee     numeric(8,2)  NOT NULL CHECK (monthly_fee > 0),
    created_by      uuid          NOT NULL REFERENCES app_user (id),
    created_at      timestamptz   NOT NULL DEFAULT now(),
    updated_at      timestamptz   NOT NULL DEFAULT now(),
    version         bigint        NOT NULL DEFAULT 0,
    CONSTRAINT uq_payment_period_month UNIQUE (organisation_id, month)
);

CREATE TABLE payment (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_period_id  uuid          NOT NULL REFERENCES payment_period (id),
    student_id         uuid          NOT NULL REFERENCES student (id),
    -- Who pays for this student; the primary contact when the month is opened.
    parent_guardian_id uuid          REFERENCES parent_guardian (id),
    expected_amount    numeric(8,2)  NOT NULL CHECK (expected_amount > 0),
    amount_paid        numeric(8,2)  NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
    paid_on            date,
    payment_method     varchar(20)   CHECK (payment_method IN ('CASH', 'BANK_TRANSFER', 'CARD', 'OTHER')),
    note               varchar(500),
    updated_by         uuid          REFERENCES app_user (id),
    created_at         timestamptz   NOT NULL DEFAULT now(),
    updated_at         timestamptz   NOT NULL DEFAULT now(),
    version            bigint        NOT NULL DEFAULT 0,
    CONSTRAINT uq_payment_period_student UNIQUE (payment_period_id, student_id),
    CONSTRAINT ck_payment_not_more_than_expected CHECK (amount_paid <= expected_amount),
    -- Money received always has a date and a method; nothing received has neither.
    CONSTRAINT ck_payment_received_details CHECK (
        (amount_paid = 0 AND paid_on IS NULL AND payment_method IS NULL)
        OR (amount_paid > 0 AND paid_on IS NOT NULL AND payment_method IS NOT NULL))
);

CREATE INDEX ix_payment_student ON payment (student_id);
