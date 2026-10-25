-- PostgreSQL database dump for staff_track_hr_system
-- Cleaned for pgAdmin 4 import

-- Set session parameters
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Create extensions
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;
COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';

-- Create enums
CREATE TYPE public.request_status_enum AS ENUM (
    'pending',
    'approved',
    'denied',
    'cancelled',
    'withdrawn'
);

-- Create functions
CREATE FUNCTION public.soft_delete_audit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    END IF;
    RETURN NEW;
END;
$$;

CREATE FUNCTION public.update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Set table defaults
SET default_tablespace = '';
SET default_table_access_method = heap;

-- Create tables
CREATE TABLE public.announcement_departments (
    announcement_id uuid NOT NULL,
    department_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL
);

CREATE TABLE public.announcements (
    announcement_id uuid NOT NULL,
    title character varying(200) NOT NULL,
    message text NOT NULL,
    type character varying(50) NOT NULL,
    target_audience character varying(100) NOT NULL,
    target_department_id uuid,
    target_role_id uuid,
    is_active boolean,
    expires_at timestamp with time zone,
    attachment_url text,
    created_by uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid
);

CREATE TABLE public.attendance_logs (
    attendance_log_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    check_in_time timestamp with time zone,
    check_out_time timestamp with time zone,
    location public.geography(Point,4326),
    accuracy numeric(6,2),
    device_id character varying(100),
    offline_flag boolean DEFAULT false,
    sync_time timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    shift_type character varying(50) DEFAULT NULL::character varying,
    work_hours numeric(5,2) DEFAULT NULL::numeric,
    CONSTRAINT attendance_logs_accuracy_check CHECK ((accuracy >= (0)::numeric))
);

COMMENT ON COLUMN public.attendance_logs.shift_type IS 'The shift type (Day Shift/Night Shift) based on check-in time';
COMMENT ON COLUMN public.attendance_logs.work_hours IS 'Pre-calculated work hours in decimal format';

CREATE TABLE public.audit_logs (
    audit_id uuid DEFAULT public.uuid_generate_v4() CONSTRAINT audit_logs_audit_log_id_not_null NOT NULL,
    actor_id uuid,
    action character varying(100) NOT NULL,
    entity_type character varying(50),
    entity_id uuid,
    old_value jsonb,
    new_value jsonb,
    ip_address inet,
    user_agent text,
    occurred_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    entity character varying(100),
    details jsonb,
    "timestamp" timestamp with time zone
);

CREATE TABLE public.departments (
    department_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(150) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid
);

CREATE TABLE public.designations (
    designation_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(150) NOT NULL,
    description text,
    department_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid
);

CREATE TABLE public.email_verifications (
    verification_id uuid NOT NULL,
    email character varying(255) NOT NULL,
    otp_code character varying(6) NOT NULL,
    purpose character varying(20) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    is_used boolean,
    attempts integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE TABLE public.employee_files (
    employee_file_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    file_type character varying(50) NOT NULL,
    file_url text NOT NULL,
    original_filename character varying(255),
    upload_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid
);

CREATE TABLE public.grades (
    grade_id uuid NOT NULL,
    name character varying(50) NOT NULL,
    annual_leave_days integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid
);

CREATE TABLE public.holidays (
    holiday_id uuid NOT NULL,
    name character varying(200) NOT NULL,
    date date NOT NULL,
    description text,
    type character varying(50) NOT NULL,
    category character varying(20) NOT NULL,
    source character varying(100),
    country_code character varying(2),
    is_recurring boolean,
    created_by uuid,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid
);

CREATE TABLE public.leave_balances (
    leave_balance_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    leave_type character varying(50) NOT NULL,
    allocated_days numeric(5,2) DEFAULT 0 NOT NULL,
    used_days numeric(5,2) DEFAULT 0 NOT NULL,
    bonus_days numeric(5,2) DEFAULT 0 NOT NULL,
    remaining_days numeric(5,2) GENERATED ALWAYS AS (((allocated_days + bonus_days) - used_days)) STORED,
    year integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    CONSTRAINT leave_balances_allocated_days_check CHECK ((allocated_days >= (0)::numeric)),
    CONSTRAINT leave_balances_bonus_days_check CHECK ((bonus_days >= (0)::numeric)),
    CONSTRAINT leave_balances_used_days_check CHECK ((used_days >= (0)::numeric)),
    CONSTRAINT leave_balances_year_check CHECK ((year >= 2000))
);

CREATE TABLE public.notification_preferences (
    preference_id uuid NOT NULL,
    user_id uuid NOT NULL,
    category character varying(50) NOT NULL,
    email_enabled boolean,
    push_enabled boolean,
    in_app_enabled boolean,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE TABLE public.notifications (
    notification_id uuid NOT NULL,
    user_id uuid NOT NULL,
    title character varying(200) NOT NULL,
    message text NOT NULL,
    type character varying(50) NOT NULL,
    is_read boolean,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid
);

CREATE TABLE public.pending_registrations (
    pending_registration_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    employee_number character varying(50) NOT NULL,
    national_id character varying(50),
    first_name character varying(100),
    surname character varying(100),
    other_names character varying(150),
    suffix character varying(20),
    date_of_birth date,
    gender character varying(10),
    home_of_origin character varying(150),
    traditional_authority character varying(100),
    district character varying(100),
    current_address text,
    contact_number character varying(30),
    email character varying(255),
    marital_status character varying(20),
    spouse_name character varying(150),
    spouse_contact character varying(30),
    date_of_employment date,
    designation character varying(150),
    department_id uuid,
    is_head_of_department boolean DEFAULT false,
    phone character varying(30),
    selfie_url text,
    status character varying(30) DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    CONSTRAINT pending_registrations_gender_check CHECK (((gender)::text = ANY ((ARRAY['male'::character varying, 'female'::character varying, 'other'::character varying])::text[]))),
    CONSTRAINT pending_registrations_marital_status_check CHECK (((marital_status)::text = ANY ((ARRAY['single'::character varying, 'married'::character varying, 'divorced'::character varying, 'widowed'::character varying])::text[]))),
    CONSTRAINT pending_registrations_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying])::text[])))
);

CREATE TABLE public.request_approvals (
    request_approval_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    request_id uuid NOT NULL,
    approver_id uuid NOT NULL,
    level integer NOT NULL,
    action character varying(10) NOT NULL,
    comment text,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP CONSTRAINT request_approvals_approved_at_not_null NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    hod_recommended_from date,
    hod_recommended_to date,
    hod_not_recommended_reason text,
    hr_annual_entitlement numeric(5,2),
    hr_entitlement_taken_from date,
    hr_entitlement_taken_to date,
    hr_last_leave_from date,
    hr_last_leave_to date,
    hr_last_leave_days numeric(5,2),
    hr_balance_if_approved numeric(5,2),
    hr_leave_grant_status character varying(30),
    admin_granted_from date,
    admin_granted_to date,
    admin_total_days_approved numeric(5,2),
    accountant_funds_available boolean,
    accountant_signed_date date,
    hod_trip_recommendation text,
    admin_trip_approval_details text,
    CONSTRAINT chk_deny_requires_comment CHECK ((((action)::text <> 'deny'::text) OR ((comment IS NOT NULL) AND (TRIM(BOTH FROM comment) <> ''::text)))),
    CONSTRAINT request_approvals_action_check CHECK (((action)::text = ANY ((ARRAY['approve'::character varying, 'deny'::character varying])::text[]))),
    CONSTRAINT request_approvals_level_check CHECK (((level >= 1) AND (level <= 5)))
);

-- Comments for request_approvals table
COMMENT ON COLUMN public.request_approvals.hod_recommended_from IS 'HOD recommended start date for leave';
COMMENT ON COLUMN public.request_approvals.hod_recommended_to IS 'HOD recommended end date for leave';
COMMENT ON COLUMN public.request_approvals.hod_not_recommended_reason IS 'HOD reason for not recommending leave';
COMMENT ON COLUMN public.request_approvals.hr_annual_entitlement IS 'HR annual leave entitlement';
COMMENT ON COLUMN public.request_approvals.hr_entitlement_taken_from IS 'HR entitlement taken from date';
COMMENT ON COLUMN public.request_approvals.hr_entitlement_taken_to IS 'HR entitlement taken to date';
COMMENT ON COLUMN public.request_approvals.hr_last_leave_from IS 'HR last leave from date';
COMMENT ON COLUMN public.request_approvals.hr_last_leave_to IS 'HR last leave to date';
COMMENT ON COLUMN public.request_approvals.hr_last_leave_days IS 'HR last leave days taken';
COMMENT ON COLUMN public.request_approvals.hr_balance_if_approved IS 'HR leave balance if approved';
COMMENT ON COLUMN public.request_approvals.hr_leave_grant_status IS 'HR leave grant status';
COMMENT ON COLUMN public.request_approvals.admin_granted_from IS 'Admin granted leave from date';
COMMENT ON COLUMN public.request_approvals.admin_granted_to IS 'Admin granted leave to date';
COMMENT ON COLUMN public.request_approvals.admin_total_days_approved IS 'Admin total days approved';
COMMENT ON COLUMN public.request_approvals.accountant_funds_available IS 'Accountant confirmation of funds availability';
COMMENT ON COLUMN public.request_approvals.accountant_signed_date IS 'Accountant signed date';
COMMENT ON COLUMN public.request_approvals.hod_trip_recommendation IS 'HOD trip recommendation';
COMMENT ON COLUMN public.request_approvals.admin_trip_approval_details IS 'Admin trip approval details';

CREATE TABLE public.requests (
    request_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    type character varying(50) NOT NULL,
    reason text,
    start_date date NOT NULL,
    end_date date,
    status public.request_status_enum DEFAULT 'pending'::public.request_status_enum NOT NULL,
    current_approver_id uuid,
    approval_level integer DEFAULT 1 NOT NULL,
    approval_comments jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    travel_date date,
    travel_place character varying(255),
    leave_grant_required boolean DEFAULT false,
    contact_address text,
    reason_for_leaving text,
    cost_accommodation numeric(12,2),
    cost_breakfast numeric(12,2),
    cost_lunch numeric(12,2),
    cost_supper numeric(12,2),
    cost_public_transport numeric(12,2),
    cost_fuel_lubricants numeric(12,2),
    cost_total numeric(12,2) DEFAULT 0.0,
    CONSTRAINT requests_approval_level_check CHECK (((approval_level >= 1) AND (approval_level <= 5)))
);

-- Comments for requests table
COMMENT ON COLUMN public.requests.travel_date IS 'Date of travel for duty station requests';
COMMENT ON COLUMN public.requests.travel_place IS 'Destination for duty station requests';
COMMENT ON COLUMN public.requests.leave_grant_required IS 'Whether the request requires a leave grant';
COMMENT ON COLUMN public.requests.contact_address IS 'Contact address during leave/trip';
COMMENT ON COLUMN public.requests.reason_for_leaving IS 'Reason for leaving duty station';
COMMENT ON COLUMN public.requests.cost_accommodation IS 'Cost of accommodation for duty station trips';
COMMENT ON COLUMN public.requests.cost_breakfast IS 'Cost of breakfast for duty station trips';
COMMENT ON COLUMN public.requests.cost_lunch IS 'Cost of lunch for duty station trips';
COMMENT ON COLUMN public.requests.cost_supper IS 'Cost of supper for duty station trips';
COMMENT ON COLUMN public.requests.cost_public_transport IS 'Cost of public transport for duty station trips';
COMMENT ON COLUMN public.requests.cost_fuel_lubricants IS 'Cost of fuel and lubricants for duty station trips';
COMMENT ON COLUMN public.requests.cost_total IS 'Total cost for duty station trips';

CREATE TABLE public.roles (
    role_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    CONSTRAINT chk_role_name_not_empty CHECK ((TRIM(BOTH FROM name) <> ''::text))
);

CREATE TABLE public.user_fcm_tokens (
    token_id uuid NOT NULL,
    user_id uuid NOT NULL,
    fcm_token text NOT NULL,
    device_id character varying(100),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);

CREATE TABLE public.users (
    user_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    employee_number character varying(50) NOT NULL,
    national_id character varying(50),
    first_name character varying(100) NOT NULL,
    surname character varying(100) NOT NULL,
    other_names character varying(150),
    suffix character varying(20),
    date_of_birth date,
    gender character varying(10),
    home_of_origin character varying(150),
    traditional_authority character varying(100),
    district character varying(100),
    current_address text,
    contact_number character varying(30),
    email character varying(255),
    marital_status character varying(20),
    spouse_name character varying(150),
    spouse_contact character varying(30),
    date_of_employment date,
    department_id uuid,
    is_head_of_department boolean DEFAULT false,
    phone character varying(30),
    password_hash text NOT NULL,
    role_id uuid NOT NULL,
    status character varying(30) DEFAULT 'pending'::character varying NOT NULL,
    profile_photo_url text,
    blacklisted_at timestamp with time zone,
    blacklisted_reason text,
    registration_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    selfie_verified boolean DEFAULT false,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    designation_id uuid,
    grade_id uuid,
    CONSTRAINT chk_employee_number_not_empty CHECK ((TRIM(BOTH FROM employee_number) <> ''::text)),
    CONSTRAINT chk_names_not_empty CHECK (((TRIM(BOTH FROM first_name) <> ''::text) AND (TRIM(BOTH FROM surname) <> ''::text))),
    CONSTRAINT users_gender_check CHECK (((gender)::text = ANY ((ARRAY['male'::character varying, 'female'::character varying, 'other'::character varying])::text[]))),
    CONSTRAINT users_marital_status_check CHECK (((marital_status)::text = ANY ((ARRAY['single'::character varying, 'married'::character varying, 'divorced'::character varying, 'widowed'::character varying])::text[]))),
    CONSTRAINT users_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'active'::character varying, 'suspended'::character varying, 'blacklisted'::character varying, 'terminated'::character varying])::text[])))
);

COMMENT ON COLUMN public.users.grade_id IS 'Reference to the grade table for employee grade information';

CREATE TABLE public.work_reports (
    work_report_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    report_text text NOT NULL,
    attachments jsonb,
    shift_date date NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    CONSTRAINT chk_report_text_not_empty CHECK ((TRIM(BOTH FROM report_text) <> ''::text))
);

-- Insert sample data (keeping existing data)

-- Insert attendance logs data

-- Insert audit logs data

-- Insert complete designations data

-- Insert email verifications data

-- Insert employee files data

-- Insert grades data

-- Insert holidays data

-- Insert notifications data

-- Insert request approvals data

-- Insert requests data

-- Insert roles data

-- Insert users data

-- Create all indexes
CREATE INDEX idx_attendance_logs_user_id ON public.attendance_logs(user_id);
CREATE INDEX idx_attendance_logs_check_in_time ON public.attendance_logs(check_in_time);
CREATE INDEX idx_attendance_location_gist ON public.attendance_logs USING gist (location);
CREATE INDEX idx_attendance_shift_type ON public.attendance_logs USING btree (shift_type);
CREATE INDEX idx_audit_logs_actor_id ON public.audit_logs(actor_id);
CREATE INDEX idx_audit_logs_occurred_at ON public.audit_logs(occurred_at);
CREATE INDEX idx_audit_actor_time ON public.audit_logs USING btree (actor_id, occurred_at);
CREATE INDEX idx_audit_entity ON public.audit_logs USING btree (entity_type, entity_id);
CREATE INDEX idx_users_employee_number ON public.users(employee_number);
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_departments_name ON public.departments USING btree (name);
CREATE INDEX idx_designations_department_id ON public.designations USING btree (department_id);
CREATE INDEX idx_designations_name ON public.designations USING btree (name);
CREATE INDEX idx_holidays_category ON public.holidays USING btree (category);
CREATE INDEX idx_holidays_source ON public.holidays USING btree (source);
CREATE INDEX idx_requests_user_id ON public.requests(user_id);
CREATE INDEX idx_requests_status ON public.requests(status);
CREATE INDEX idx_requests_pending_approver ON public.requests USING btree (current_approver_id) WHERE ((status = 'pending'::public.request_status_enum) AND (deleted_at IS NULL));
CREATE INDEX idx_leave_balances_user_id ON public.leave_balances(user_id);
CREATE INDEX idx_leave_balances_year ON public.leave_balances(year);
CREATE INDEX ix_email_verifications_email ON public.email_verifications USING btree (email);

-- Create primary key constraints
ALTER TABLE ONLY public.announcement_departments
    ADD CONSTRAINT announcement_departments_pkey PRIMARY KEY (announcement_id, department_id);

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (announcement_id);

ALTER TABLE ONLY public.attendance_logs
    ADD CONSTRAINT attendance_logs_pkey PRIMARY KEY (attendance_log_id);

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (audit_id);

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id),
    ADD CONSTRAINT departments_name_key UNIQUE (name);

ALTER TABLE ONLY public.designations
    ADD CONSTRAINT designations_pkey PRIMARY KEY (designation_id),
    ADD CONSTRAINT designations_department_id_name_key UNIQUE (department_id, name);

ALTER TABLE ONLY public.email_verifications
    ADD CONSTRAINT email_verifications_pkey PRIMARY KEY (verification_id);

ALTER TABLE ONLY public.employee_files
    ADD CONSTRAINT employee_files_pkey PRIMARY KEY (employee_file_id);

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_pkey PRIMARY KEY (grade_id),
    ADD CONSTRAINT grades_name_key UNIQUE (name);

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (holiday_id);

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_pkey PRIMARY KEY (leave_balance_id),
    ADD CONSTRAINT unique_user_leave_year UNIQUE (user_id, leave_type, year);

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (preference_id);

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);

ALTER TABLE ONLY public.pending_registrations
    ADD CONSTRAINT pending_registrations_pkey PRIMARY KEY (pending_registration_id),
    ADD CONSTRAINT pending_registrations_employee_number_key UNIQUE (employee_number);

ALTER TABLE ONLY public.request_approvals
    ADD CONSTRAINT request_approvals_pkey PRIMARY KEY (request_approval_id),
    ADD CONSTRAINT unique_approval_per_level UNIQUE (request_id, level);

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT requests_pkey PRIMARY KEY (request_id);

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id),
    ADD CONSTRAINT roles_name_key UNIQUE (name);

ALTER TABLE ONLY public.user_fcm_tokens
    ADD CONSTRAINT user_fcm_tokens_pkey PRIMARY KEY (token_id),
    ADD CONSTRAINT user_fcm_tokens_fcm_token_key UNIQUE (fcm_token);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id),
    ADD CONSTRAINT users_employee_number_key UNIQUE (employee_number),
    ADD CONSTRAINT users_national_id_key UNIQUE (national_id),
    ADD CONSTRAINT users_email_key UNIQUE (email),
    ADD CONSTRAINT users_contact_number_key UNIQUE (contact_number),
    ADD CONSTRAINT users_phone_key UNIQUE (phone);

ALTER TABLE ONLY public.work_reports
    ADD CONSTRAINT work_reports_pkey PRIMARY KEY (work_report_id);

-- Create triggers
CREATE TRIGGER trg_attendance_logs_soft_delete_audit BEFORE UPDATE ON public.attendance_logs FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();
CREATE TRIGGER trg_attendance_logs_update_timestamp BEFORE UPDATE ON public.attendance_logs FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE TRIGGER trg_employee_files_soft_delete_audit BEFORE UPDATE ON public.employee_files FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();
CREATE TRIGGER trg_employee_files_update_timestamp BEFORE UPDATE ON public.employee_files FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE TRIGGER trg_leave_balances_soft_delete_audit BEFORE UPDATE ON public.leave_balances FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();
CREATE TRIGGER trg_leave_balances_update_timestamp BEFORE UPDATE ON public.leave_balances FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE TRIGGER trg_pending_registrations_soft_delete_audit BEFORE UPDATE ON public.pending_registrations FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();
CREATE TRIGGER trg_pending_registrations_update_timestamp BEFORE UPDATE ON public.pending_registrations FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE TRIGGER trg_request_approvals_soft_delete_audit BEFORE UPDATE ON public.request_approvals FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();

-- Create foreign key constraints
ALTER TABLE ONLY public.announcement_departments
    ADD CONSTRAINT announcement_departments_announcement_id_fkey FOREIGN KEY (announcement_id) REFERENCES public.announcements(announcement_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.announcement_departments
    ADD CONSTRAINT announcement_departments_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.attendance_logs
    ADD CONSTRAINT attendance_logs_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.attendance_logs
    ADD CONSTRAINT attendance_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.designations
    ADD CONSTRAINT designations_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.designations
    ADD CONSTRAINT designations_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.employee_files
    ADD CONSTRAINT employee_files_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.employee_files
    ADD CONSTRAINT employee_files_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT fk_roles_deleted_by FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id);

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id);

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id);

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);

ALTER TABLE ONLY public.pending_registrations
    ADD CONSTRAINT pending_registrations_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.request_approvals
    ADD CONSTRAINT request_approvals_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(user_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.request_approvals
    ADD CONSTRAINT request_approvals_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.request_approvals
    ADD CONSTRAINT request_approvals_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.requests(request_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT requests_current_approver_id_fkey FOREIGN KEY (current_approver_id) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT requests_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_fcm_tokens
    ADD CONSTRAINT user_fcm_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_designation_id_fkey FOREIGN KEY (designation_id) REFERENCES public.designations(designation_id);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_grade_id_fkey FOREIGN KEY (grade_id) REFERENCES public.grades(grade_id);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.work_reports
    ADD CONSTRAINT work_reports_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.work_reports
    ADD CONSTRAINT work_reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;

-- PostgreSQL database dump complete
