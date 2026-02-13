-- Enable UUID extension 
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- =============================================================================
-- Lookup / Master Tables
-- =============================================================================

CREATE TABLE roles (
    role_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name          VARCHAR(100) NOT NULL UNIQUE,
    description   TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at    TIMESTAMPTZ,
    deleted_by    UUID REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_role_name_not_empty CHECK (TRIM(name) <> '')
);

CREATE TABLE departments (
    department_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name          VARCHAR(150) NOT NULL UNIQUE,
    description   TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at    TIMESTAMPTZ,
    deleted_by    UUID REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_department_name_not_empty CHECK (TRIM(name) <> '')
);

-- =============================================================================
-- Users & Employee Core
-- =============================================================================

CREATE TABLE users (
    user_id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_number     VARCHAR(50)  NOT NULL UNIQUE,
    national_id         VARCHAR(50)  UNIQUE,
    first_name          VARCHAR(100) NOT NULL,
    surname             VARCHAR(100) NOT NULL,
    other_names         VARCHAR(150),                    -- optional middle / additional names
    email               VARCHAR(255) UNIQUE,
    phone               VARCHAR(30)  UNIQUE,
    password_hash       TEXT         NOT NULL,
    role_id             UUID         NOT NULL REFERENCES roles(role_id) ON DELETE RESTRICT,
    department_id       UUID         REFERENCES departments(department_id) ON DELETE SET NULL,
    status              VARCHAR(30)  NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'active', 'suspended', 'blacklisted', 'terminated')),
    profile_photo_url   TEXT,
    blacklisted_at      TIMESTAMPTZ,
    blacklisted_reason  TEXT,
    registration_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    selfie_verified     BOOLEAN      DEFAULT FALSE,
    last_login_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMPTZ,
    deleted_by          UUID REFERENCES users(user_id) ON DELETE SET NULL,

    CONSTRAINT chk_employee_number_not_empty CHECK (TRIM(employee_number) <> ''),
    CONSTRAINT chk_names_not_empty CHECK (TRIM(first_name) <> '' AND TRIM(surname) <> '')
);

-- =============================================================================
-- Leave Balances
-- =============================================================================

CREATE TABLE leave_balances (
    leave_balance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id          UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    leave_type       VARCHAR(50) NOT NULL,
    allocated_days   NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (allocated_days >= 0),
    used_days        NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (used_days >= 0),
    bonus_days       NUMERIC(5,2) NOT NULL DEFAULT 0 CHECK (bonus_days >= 0),
    remaining_days   NUMERIC(5,2) GENERATED ALWAYS AS (allocated_days + bonus_days - used_days) STORED,
    year             INTEGER NOT NULL CHECK (year >= 2000),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at       TIMESTAMPTZ,
    deleted_by       UUID REFERENCES users(user_id) ON DELETE SET NULL,

    CONSTRAINT unique_user_leave_year UNIQUE (user_id, leave_type, year)
);

-- =============================================================================
-- Attendance & Reports
-- =============================================================================

CREATE TABLE attendance_logs (
    attendance_log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    check_in_time     TIMESTAMPTZ,
    check_out_time    TIMESTAMPTZ,
    location          geography(POINT, 4326),   -- Core change: single column for lon/lat (WGS84)
    accuracy          NUMERIC(6,2) CHECK (accuracy >= 0),  -- GPS accuracy in meters
    device_id         VARCHAR(100),
    offline_flag      BOOLEAN DEFAULT FALSE,
    sync_time         TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at        TIMESTAMPTZ,
    deleted_by        UUID REFERENCES users(user_id) ON DELETE SET NULL
);

-- Spatial index for fast geofence / distance queries (very important!)
CREATE INDEX idx_attendance_location_gist ON attendance_logs USING GIST (location);



CREATE TABLE work_reports (
    work_report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    report_text    TEXT NOT NULL,
    attachments    JSONB,                           -- e.g. [{"url": "...", "name": "..."}]
    shift_date     DATE NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at     TIMESTAMPTZ,
    deleted_by     UUID REFERENCES users(user_id) ON DELETE SET NULL,

    CONSTRAINT chk_report_text_not_empty CHECK (TRIM(report_text) <> '')
);

-- =============================================================================
-- Requests & Approvals
-- =============================================================================

CREATE TYPE request_status_enum AS ENUM ('pending', 'approved', 'denied', 'cancelled', 'withdrawn');

CREATE TABLE requests (
    request_id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    type                VARCHAR(50) NOT NULL,
    reason              TEXT,
    start_date          DATE NOT NULL,
    end_date            DATE,
    status              request_status_enum NOT NULL DEFAULT 'pending',
    current_approver_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    approval_level      INTEGER NOT NULL DEFAULT 1 CHECK (approval_level BETWEEN 1 AND 5),
    approval_comments   JSONB,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMPTZ,
    deleted_by          UUID REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE TABLE request_approvals (
    request_approval_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id          UUID NOT NULL REFERENCES requests(request_id) ON DELETE CASCADE,
    approver_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE RESTRICT,
    level               INTEGER NOT NULL CHECK (level BETWEEN 1 AND 5),
    action              VARCHAR(10) NOT NULL CHECK (action IN ('approve', 'deny')),
    comment             TEXT,
    approved_at         TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at          TIMESTAMPTZ,
    deleted_by          UUID REFERENCES users(user_id) ON DELETE SET NULL,

    CONSTRAINT unique_approval_per_level UNIQUE (request_id, level),
    CONSTRAINT chk_deny_requires_comment CHECK (action <> 'deny' OR (comment IS NOT NULL AND TRIM(comment) <> ''))
);

CREATE INDEX idx_requests_pending_approver ON requests (current_approver_id) 
    WHERE status = 'pending' AND deleted_at IS NULL;

-- =============================================================================
-- Files & Audit
-- =============================================================================

CREATE TABLE employee_files (
    employee_file_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id          UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    file_type        VARCHAR(50) NOT NULL,
    file_url         TEXT NOT NULL,
    original_filename VARCHAR(255),
    upload_date      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at       TIMESTAMPTZ,
    deleted_by       UUID REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE TABLE audit_logs (
    audit_log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id     UUID REFERENCES users(user_id) ON DELETE SET NULL,
    action       VARCHAR(100) NOT NULL,
    entity_type  VARCHAR(50),
    entity_id    UUID,
    old_value    JSONB,
    new_value    JSONB,
    ip_address   INET,
    user_agent   TEXT,
    occurred_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    -- No deleted_at/deleted_by for audit_logs as they should be immutable
);

CREATE INDEX idx_audit_actor_time ON audit_logs (actor_id, occurred_at);
CREATE INDEX idx_audit_entity ON audit_logs (entity_type, entity_id);

-- =============================================================================
-- Pending Self-Registrations (staging)
-- =============================================================================

CREATE TABLE pending_registrations (
    pending_registration_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_number         VARCHAR(50) NOT NULL UNIQUE,
    national_id             VARCHAR(50),
    first_name              VARCHAR(100),
    surname                 VARCHAR(100),
    other_names             VARCHAR(150),
    email                   VARCHAR(255),
    phone                   VARCHAR(30),
    selfie_url              TEXT,
    status                  VARCHAR(30) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at              TIMESTAMPTZ,
    deleted_by              UUID REFERENCES users(user_id) ON DELETE SET NULL
);

-- =============================================================================
-- Auto-update timestamp trigger (applied to most tables)
-- =============================================================================

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables that need updated_at
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'users', 'roles', 'departments', 'leave_balances',
        'attendance_logs', 'work_reports', 'requests',
        'employee_files', 'pending_registrations'
    ] LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS trg_%s_update_timestamp ON %I;
            CREATE TRIGGER trg_%s_update_timestamp
            BEFORE UPDATE ON %I
            FOR EACH ROW EXECUTE FUNCTION update_timestamp();
        ', tbl, tbl, tbl, tbl);
    END LOOP;
END $$;

-- =============================================================================
-- Soft-Delete Trigger (log deletions to audit_logs)
-- =============================================================================

CREATE OR REPLACE FUNCTION soft_delete_audit()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
        INSERT INTO audit_logs (actor_id, action, entity_type, entity_id, old_value, new_value, occurred_at)
        VALUES (NEW.deleted_by, 'soft_delete', TG_RELNAME, OLD.*::text::jsonb::jsonb, OLD.*::text::jsonb, NEW.*::text::jsonb, CURRENT_TIMESTAMP);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply soft-delete audit trigger to tables with deleted_at
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'users', 'roles', 'departments', 'leave_balances',
        'attendance_logs', 'work_reports', 'requests', 'request_approvals',
        'employee_files', 'pending_registrations'
    ] LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS trg_%s_soft_delete_audit ON %I;
            CREATE TRIGGER trg_%s_soft_delete_audit
            BEFORE UPDATE ON %I
            FOR EACH ROW WHEN (NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL)
            EXECUTE FUNCTION soft_delete_audit();
        ', tbl, tbl, tbl, tbl);
    END LOOP;
END $$;