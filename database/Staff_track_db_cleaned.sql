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
        INSERT INTO audit_logs (actor_id, action, entity_type, entity_id, old_value, new_value, occurred_at)
        VALUES (NEW.deleted_by, 'soft_delete', TG_RELNAME, OLD.*::text::jsonb::jsonb, OLD.*::text::jsonb, NEW.*::text::jsonb, CURRENT_TIMESTAMP);
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
INSERT INTO public.announcements (announcement_id, title, message, type, target_audience, target_department_id, target_role_id, is_active, expires_at, attachment_url, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('981089b6-3dcb-425e-bf06-cd08f58fba08', 'Holiday', 'asdasdad', 'general', 'All Staff', NULL, NULL, true, '2026-03-03 00:00:00+02', NULL, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 07:18:57.490797+02', '2026-03-02 07:18:57.490797+02', NULL, NULL);
INSERT INTO public.announcements (announcement_id, title, message, type, target_audience, target_department_id, target_role_id, is_active, expires_at, attachment_url, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('01314e2e-1a7d-421d-a3f4-30ed4e84edee', 'asdfghjk', 'asdfghjk', 'general', 'All Staff', NULL, NULL, true, NULL, NULL, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 07:19:39.868772+02', '2026-03-02 07:19:39.868772+02', NULL, NULL);
INSERT INTO public.announcements (announcement_id, title, message, type, target_audience, target_department_id, target_role_id, is_active, expires_at, attachment_url, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('ba394cd9-12a7-4f76-bfcb-7b6b6ce291eb', 'testing', 'testing', 'general', 'Medical, Nursing, IT', NULL, NULL, true, NULL, NULL, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 07:30:55.406572+02', '2026-03-02 07:30:55.406572+02', NULL, NULL);

-- Insert attendance logs data
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('b024aff9-2f3e-4d61-9315-46e58790edef', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-02-19 13:08:22.826467+02', NULL, NULL, NULL, NULL, false, NULL, '2026-02-19 13:08:22.826467+02', '2026-02-26 08:15:35.160756+02', NULL, NULL, 'Day Shift', NULL);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('e79c04aa-9987-4f49-8aa7-e03baf4d5974', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-02-24 08:40:04.957727+02', NULL, NULL, NULL, NULL, false, NULL, '2026-02-24 08:40:04.957727+02', '2026-02-26 08:15:35.160756+02', NULL, NULL, 'Day Shift', NULL);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('fe8c55bd-7883-4bb2-b592-78be478869f0', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', '2026-02-24 12:46:35.868274+02', NULL, NULL, NULL, NULL, false, NULL, '2026-02-24 12:46:35.868274+02', '2026-02-26 08:15:35.160756+02', NULL, NULL, 'Day Shift', NULL);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('151fe920-d78e-4913-a527-33eb8d70e337', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-02-26 11:07:35.761374+02', NULL, '0101000020E6100000D42B6519E28041406666666666C62EC0', 10.50, 'test-device-123', false, NULL, '2026-02-26 11:07:35.761374+02', '2026-02-26 11:07:35.761374+02', NULL, NULL, 'Day Shift', NULL);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('72fe8b6a-dffd-42e3-a386-f57636195f8c', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-02-26 11:07:21.481501+02', '2026-02-26 11:08:39.376697+02', '0101000020E6100000D42B6519E28041406666666666C62EC0', 10.50, 'test-device-123', false, NULL, '2026-02-26 11:07:21.481501+02', '2026-02-26 11:08:39.374915+02', NULL, NULL, 'Day Shift', 0.02);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('11185bd4-e7c6-47c8-950d-199bbe11452d', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', '2026-03-05 21:57:54.607223+02', '2026-03-05 21:59:06.43345+02', '0101000020E6100000E8305F5E800341400C923EADA2E726C0', NULL, NULL, false, NULL, '2026-03-05 21:57:54.607223+02', '2026-03-05 21:59:06.419573+02', NULL, NULL, 'Night Shift', 0.02);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('4cf79a18-4899-48a5-847b-3be9026a0301', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-06 20:07:23.932966+02', NULL, '0101000020E6100000E8305F5E800341400C923EADA2E726C0', NULL, NULL, false, NULL, '2026-03-06 20:07:23.932966+02', '2026-03-06 20:07:23.932966+02', NULL, NULL, 'Night Shift', NULL);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('7f774cd0-8e8b-471d-b7ac-0ff23201f9f4', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', '2026-03-07 21:49:51.538302+02', NULL, '0101000020E6100000E8305F5E800341400C923EADA2E726C0', NULL, NULL, false, NULL, '2026-03-07 21:49:51.538302+02', '2026-03-07 21:49:51.538302+02', NULL, NULL, 'Night Shift', NULL);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('2d2cec59-4702-420a-aeb9-13745c7fbdd8', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-07 21:52:24.382131+02', NULL, '0101000020E6100000E8305F5E800341400C923EADA2E726C0', NULL, NULL, false, NULL, '2026-03-07 21:52:24.382131+02', '2026-03-07 21:52:24.382131+02', NULL, NULL, 'Night Shift', NULL);

-- Insert audit logs data
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('7b74d33d-2c51-4620-9b60-f59c3ac7c894', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_out', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-05 21:57:04.639363+02', 'attendance', '{"work_hours": 0.12561389694444444, "attendance_log_id": "d6ee992a-b586-4173-b8d1-a8b1954a52a9"}', '2026-03-05 21:57:04.650453+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('5bf9e6f8-ad79-4d27-911a-8ff3cb472707', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_in', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-05 21:57:54.619129+02', 'attendance', '{"attendance_log_id": "11185bd4-e7c6-47c8-950d-199bbe11452d"}', '2026-03-05 21:57:54.622156+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('75b417c3-7764-4754-be38-88fb08c8f107', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_out', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-05 21:59:06.443682+02', 'attendance', '{"work_hours": 0.019951729722222224, "attendance_log_id": "11185bd4-e7c6-47c8-950d-199bbe11452d"}', '2026-03-05 21:59:06.446829+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('d330a42b-e9e1-4af6-9944-f7e1e2499b7a', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', 'check_in', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-06 20:07:23.972794+02', 'attendance', '{"attendance_log_id": "4cf79a18-4899-48a5-847b-3be9026a0301"}', '2026-03-06 20:07:23.994204+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('3cb68dc9-78b0-4a0b-8352-c27878f17c14', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_in', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-07 20:38:16.877362+02', 'attendance', '{"attendance_log_id": "423fc1d6-74bf-4a93-a70d-5571460e8407"}', '2026-03-07 20:38:16.880248+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('7de8e5f7-0ca2-46cd-b744-33514c762609', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_out', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-07 20:45:55.86973+02', 'attendance', '{"work_hours": 0.1274987125, "attendance_log_id": "423fc1d6-74bf-4a93-a70d-5571460e8407"}', '2026-03-07 20:45:55.874531+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('fb58c66a-03a3-41ab-b72d-d4a795776bb1', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_in', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-07 20:49:41.425381+02', 'attendance', '{"attendance_log_id": "08bfe0cf-9788-4416-bab3-a0559309e920"}', '2026-03-07 20:49:41.429241+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('68650329-7a8d-454b-b15f-6f3e80667446', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_in', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-07 21:49:51.57162+02', 'attendance', '{"attendance_log_id": "7f774cd0-8e8b-471d-b7ac-0ff23201f9f4"}', '2026-03-07 21:49:51.580533+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('5ecc10df-09c1-40bf-9914-f4d6e6ee8f00', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', 'check_in', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-07 21:52:24.396644+02', 'attendance', '{"attendance_log_id": "2d2cec59-4702-420a-aeb9-13745c7fbdd8"}', '2026-03-07 21:52:24.399928+02');

-- Insert complete designations data
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('50f690bd-a603-4578-b346-0f92d489ed5a', 'Physical Therapist', 'Therapist providing rehabilitation services', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('7821971b-9345-4947-9086-68fda9a7e859', 'Physical Therapy Assistant', 'Assistant to physical therapist', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('c180af1a-f8c9-4a07-b4a5-fccba9e6911c', 'Rehabilitation Manager', 'Manager of rehabilitation services', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('deaa3dff-c304-4717-96a6-badd7170c518', 'Sports Medicine Specialist', 'Specialist in sports-related injuries', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('6df705e2-b18f-40c9-b46c-4444c30e6ce6', 'Occupational Therapist', 'Therapist helping with daily living skills', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('ab864b52-72a4-4dfc-bd23-4d5909afc0eb', 'Therapy Technician', 'Technician assisting therapists', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('f5ce8a2a-796d-4113-9d9d-dcfaf2cccb82', 'Rehabilitation Aide', 'Aide assisting in rehabilitation', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('6d92e83c-5d4d-448a-a045-5e9672884fc6', 'Hand Therapist', 'Therapist specializing in hand rehabilitation', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('6ed54ed3-6ec3-43f4-a9d5-a3a9bc82311b', 'Hospital Administrator', 'Senior hospital management position', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('c32e50e6-48ed-4a7a-930f-456fb2805a4d', 'Chief Executive Officer', 'CEO of the hospital', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('71d82498-8d83-42af-b1c9-61acbfe3ba11', 'Chief Operating Officer', 'COO of the hospital', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('e6dbcabf-bd93-4364-8b90-b5a2f4fde0cf', 'Administrative Director', 'Director of administrative services', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('21cbb342-a039-47f4-8a1b-1ee2d8b7f585', 'Department Head', 'Head of a specific department', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('337116e5-d293-4f91-bb78-545946f236a1', 'Administrative Assistant', 'Assistant providing administrative support', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('a36b6c6d-1aa0-4e6a-9cc8-a66ec08e7a4b', 'Executive Assistant', 'Assistant to senior executives', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('84107c40-e043-43ab-82e9-8fda09720889', 'Hospital Manager', 'Manager of hospital operations', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('e56b899b-3c17-4333-b931-7b14107052aa', 'Chief Financial Officer', 'CFO of the hospital', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('3a8e15bc-5dc8-49ff-b20d-f5f75484456c', 'Accountant', 'Professional managing financial records', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('08b4c831-30e5-4801-adca-2e6a6b472368', 'Financial Analyst', 'Professional analyzing financial data', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('d30b3f72-25e0-462e-972a-d7cff9fc9e14', 'Billing Specialist', 'Specialist handling medical billing', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('db5d55ea-8285-48ce-8958-7be410f16792', 'Revenue Cycle Manager', 'Manager of revenue cycle operations', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('ec069b65-98c4-46ce-9482-dbe70485e3ef', 'Accounts Payable Clerk', 'Clerk managing accounts payable', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('438f23fc-d765-44ac-b2f2-0fd299dd2a60', 'Payroll Manager', 'Manager of payroll operations', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('d49766d8-021b-4478-99fc-e46a252c510c', 'Financial Controller', 'Controller of financial operations', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('fa6da6c4-9843-4bd1-a2a6-fc3e44917404', 'HR Director', 'Director of human resources', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('96af833e-a052-4838-b36d-e1309ac06042', 'HR Manager', 'Manager of human resources department', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('8ef325e6-f7d1-4a97-a898-b4a787486ead', 'HR Generalist', 'Generalist providing HR support', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('e10503c2-5f60-4a3c-a0d4-6c069df29a1e', 'Recruiter', 'Professional responsible for hiring', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('59feed0a-2b2d-4c67-b149-0c348e6ff42d', 'Training Coordinator', 'Coordinator of employee training', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('2beef42b-c29e-4c6b-a056-6cc8994dcd53', 'Compensation Analyst', 'Analyst managing compensation programs', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('f4aaf9aa-83c1-4a50-81b8-2c2ea564fec3', 'Employee Relations Specialist', 'Specialist handling employee relations', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('b51588f6-94d1-471e-b451-7431d129d71b', 'HR Assistant', 'Assistant providing HR support', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('bedcc3c5-361c-41d9-b29b-fce92e6aac85', 'IT Director', 'Director of information technology', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('c9662e1d-8ab8-4e2e-8a7d-1f3d9485578a', 'System Administrator', 'Professional managing IT systems', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('afb91e8b-cae9-4491-899f-8cde3951ca62', 'Network Administrator', 'Professional managing network infrastructure', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('47931197-105c-4ebc-926a-a4d68e68dc73', 'Database Administrator', 'Professional managing databases', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('74a7d7f6-17a9-4b06-a5fb-b10818347b4d', 'IT Support Specialist', 'Professional providing IT support', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('2ee12051-d35d-4c01-bbb7-7eaf88687774', 'Software Developer', 'Developer creating software solutions', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('e4e25767-c253-40e5-8781-ac1219f14906', 'Security Analyst', 'Analyst managing IT security', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('7b4d6aef-2d35-4415-a82a-ba730eb81661', 'IT Project Manager', 'Manager of IT projects', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('36424165-6afb-4603-a237-379fa7e85209', 'Marketing Director', 'Director of marketing activities', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('90c8978c-beb4-442e-9f67-143406422b6b', 'Communications Manager', 'Manager of communications activities', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('9dec9c95-934f-4de3-be41-62644947829a', 'Public Relations Specialist', 'Specialist handling public relations', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('aa382bc0-bfa7-482d-a6f6-ad29ea8a5190', 'Marketing Coordinator', 'Coordinator of marketing activities', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('d7e53526-5dbd-4b3d-a51c-2ac5701b83d7', 'Content Creator', 'Creator of marketing content', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('d5ad0d11-7b54-4528-a649-db0844492ec6', 'Social Media Manager', 'Manager of social media presence', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('7247904e-64db-40ab-bb35-bfc84e9e19a9', 'Graphic Designer', 'Designer creating visual content', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('76469f20-a68f-441c-8002-41440b1d1d9b', 'Community Outreach Coordinator', 'Coordinator of community outreach', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('13e409b4-ccaa-49e8-9fce-c05c67bd7ce6', 'IT Manager', NULL, 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 15:59:20.660278+02', '2026-02-17 15:59:20.660278+02', NULL, NULL);

-- Insert email verifications data
INSERT INTO public.email_verifications (verification_id, email, otp_code, purpose, expires_at, is_used, attempts, created_at, updated_at) VALUES ('e2e1771b-35e0-4204-af3a-dfdbfeccc6dd', 'yankhochisale4@gmail.com', '717504', 'registration', '2026-02-24 06:44:02.721227+02', true, 0, '2026-02-24 06:34:02.721227+02', '2026-02-24 06:34:02.721227+02');
INSERT INTO public.email_verifications (verification_id, email, otp_code, purpose, expires_at, is_used, attempts, created_at, updated_at) VALUES ('0ccdacac-0e41-4397-ba43-a9fdd9ea3a63', 'yankhochisale4@gmail.com', '762754', 'registration', '2026-02-24 06:47:21.239062+02', true, 0, '2026-02-24 06:37:21.239062+02', '2026-02-24 06:38:11.798771+02');
INSERT INTO public.email_verifications (verification_id, email, otp_code, purpose, expires_at, is_used, attempts, created_at, updated_at) VALUES ('851b4372-3a33-40b1-a56e-c86310f4cfdb', 'cis-011-21@must.ac.mw', '718243', 'registration', '2026-02-24 10:54:58.86864+02', true, 0, '2026-02-24 10:44:58.86864+02', '2026-02-24 10:45:28.485198+02');

-- Insert employee files data
INSERT INTO public.employee_files (employee_file_id, user_id, file_type, file_url, original_filename, upload_date, created_at, deleted_at, deleted_by) VALUES ('0dfa5a6d-6ae5-475f-ba7d-ece43285aca4', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', 'payslip', 'http://0.0.0.0:8000/uploads/employee_files/a146d69d-5a31-4305-bc9d-82258bcb9981.png', NULL, '2026-03-05 07:08:27.110744+02', '2026-03-05 09:08:27.115243+02', NULL, NULL);

-- Insert grades data
INSERT INTO public.grades (grade_id, name, annual_leave_days, created_at, updated_at, deleted_at, deleted_by) VALUES ('385c3adb-2efa-49e8-be46-f2432055dc01', 'Grade A', 30, '2026-03-05 18:12:21.009858+02', '2026-03-05 18:12:21.009858+02', NULL, NULL);
INSERT INTO public.grades (grade_id, name, annual_leave_days, created_at, updated_at, deleted_at, deleted_by) VALUES ('0ab214a5-a0cb-42f5-b96d-e1c31b41da86', 'Grade B', 28, '2026-03-05 18:12:21.009858+02', '2026-03-05 18:12:21.009858+02', NULL, NULL);
INSERT INTO public.grades (grade_id, name, annual_leave_days, created_at, updated_at, deleted_at, deleted_by) VALUES ('2619c1a2-1324-4ff1-9797-77918409c57e', 'Grade C', 25, '2026-03-05 18:12:21.009858+02', '2026-03-05 18:12:21.009858+02', NULL, NULL);
INSERT INTO public.grades (grade_id, name, annual_leave_days, created_at, updated_at, deleted_at, deleted_by) VALUES ('6146c040-bb4c-4a70-9ada-7727d3794664', 'Grade D', 21, '2026-03-05 18:12:21.009858+02', '2026-03-05 18:12:21.009858+02', NULL, NULL);
INSERT INTO public.grades (grade_id, name, annual_leave_days, created_at, updated_at, deleted_at, deleted_by) VALUES ('83ebcd88-559f-4150-87a5-cfa681c148cd', 'Grade E', 18, '2026-03-05 18:12:21.009858+02', '2026-03-05 18:12:21.009858+02', NULL, NULL);

-- Insert holidays data
INSERT INTO public.holidays (holiday_id, name, date, description, type, category, source, country_code, is_recurring, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('25082a67-a444-46ad-9181-44f062a1df63', 'ash', '2026-03-03', 'asdfghjk', 'Institutional Holiday', 'institutional', 'manual', 'MW', false, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:08:03.93446+02', '2026-03-02 08:24:01.097879+02', '2026-03-02 08:24:01.097879+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47');
INSERT INTO public.holidays (holiday_id, name, date, description, type, category, source, country_code, is_recurring, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('cb0435ae-4c3d-47d0-b680-921e9a356a6f', 'testing', '2026-03-04', 'test 2', 'Institutional Holiday', 'institutional', 'manual', 'MW', false, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:16:22.162834+02', '2026-03-02 08:24:31.45783+02', '2026-03-02 08:24:31.45783+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47');
INSERT INTO public.holidays (holiday_id, name, date, description, type, category, source, country_code, is_recurring, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('5ebab23e-3d11-4308-aa10-fed829f750f3', 'testing', '2026-03-04', 'test 2', 'Institutional Holiday', 'institutional', 'manual', 'MW', false, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:16:26.298139+02', '2026-03-02 08:30:57.248916+02', '2026-03-02 08:30:57.248916+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47');
INSERT INTO public.holidays (holiday_id, name, date, description, type, category, source, country_code, is_recurring, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('4f4b1e01-84b0-4ce2-9a86-9cb58852775e', 'test 3', '2026-03-05', 'testing 3', 'Institutional Holiday', 'institutional', 'manual', 'MW', false, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:19:29.280819+02', '2026-03-02 08:36:09.584385+02', '2026-03-02 08:36:09.584385+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47');
INSERT INTO public.holidays (holiday_id, name, date, description, type, category, source, country_code, is_recurring, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('97e30f20-18a4-4b94-b966-8b27b3b7b224', 'test', '2026-03-12', 'ad', 'Institutional Holiday', 'institutional', 'manual', 'MW', true, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:35:59.41296+02', '2026-03-02 08:42:55.292843+02', '2026-03-02 08:42:55.292843+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47');
INSERT INTO public.holidays (holiday_id, name, date, description, type, category, source, country_code, is_recurring, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('f413c875-ebd6-4acd-b7fc-f38954bd7974', 'is it working', '2026-03-04', 'maybe', 'Institutional Holiday', 'institutional', 'manual', 'MW', true, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 09:22:25.68131+02', '2026-03-02 09:22:25.68131+02', NULL, NULL);

-- Insert notifications data
INSERT INTO public.notifications (notification_id, user_id, title, message, type, is_read, created_at, updated_at, deleted_at, deleted_by) VALUES ('7ddb4b5e-61ef-4cdb-846c-4bff077d16b1', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'Request Approved', 'Your Annual Leave request has been approved', 'request', false, '2026-03-06 05:05:21.002739+02', '2026-03-06 05:05:21.002739+02', NULL, NULL);
INSERT INTO public.notifications (notification_id, user_id, title, message, type, is_read, created_at, updated_at, deleted_at, deleted_by) VALUES ('0078e07d-55b9-4c3a-8a04-d02d7769b6b9', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'Geofence Violation Detected', 'Check-in location was 8152917m outside work area', 'security', false, '2026-03-07 20:38:16.820101+02', '2026-03-07 20:38:16.820101+02', NULL, NULL);
INSERT INTO public.notifications (notification_id, user_id, title, message, type, is_read, created_at, updated_at, deleted_at, deleted_by) VALUES ('e9ef276e-6b09-4ec9-aecd-f3b98de1ec91', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', '✅ Check-in Successful', 'You successfully checked in at 20:38 for Night Shift', 'attendance', false, '2026-03-07 20:38:16.820101+02', '2026-03-07 20:38:16.820101+02', NULL, NULL);
INSERT INTO public.notifications (notification_id, user_id, title, message, type, is_read, created_at, updated_at, deleted_at, deleted_by) VALUES ('5c0e09db-78b4-4bb2-afe1-e56ba8633d61', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'Geofence Violation Detected', 'Check-out location was 8152917m outside work area', 'security', false, '2026-03-07 20:45:55.815466+02', '2026-03-07 20:45:55.815466+02', NULL, NULL);
INSERT INTO public.notifications (notification_id, user_id, title, message, type, is_read, created_at, updated_at, deleted_at, deleted_by) VALUES ('fe376615-05c9-4df2-8fab-b77a5fa4ed7c', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', '✅ Check-out Successful', 'You successfully checked out at 20:45. Total hours worked: 0.1', 'attendance', false, '2026-03-07 20:45:55.815466+02', '2026-03-07 20:45:55.815466+02', NULL, NULL);
INSERT INTO public.notifications (notification_id, user_id, title, message, type, is_read, created_at, updated_at, deleted_at, deleted_by) VALUES ('0b8d92aa-3ef0-471f-8217-2885790f267a', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'Geofence Violation Detected', 'Check-in location was 8152917m outside work area', 'security', false, '2026-03-07 20:49:41.386002+02', '2026-03-07 20:49:41.386002+02', NULL, NULL);
INSERT INTO public.notifications (notification_id, user_id, title, message, type, is_read, created_at, updated_at, deleted_at, deleted_by) VALUES ('7e3f5193-7178-4e68-8f92-5cb4b5afd2eb', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', '✅ Check-in Successful', 'You successfully checked in at 20:49 for Night Shift', 'attendance', false, '2026-03-07 20:49:41.386002+02', '2026-03-07 20:49:41.386002+02', NULL, NULL);
INSERT INTO public.notifications (notification_id, user_id, title, message, type, is_read, created_at, updated_at, deleted_at, deleted_by) VALUES ('bb578019-8b25-4a93-bbd6-168c655211ff', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'Geofence Violation Detected', 'Check-in location was 8152917m outside work area', 'security', false, '2026-03-07 21:05:59.52938+02', '2026-03-07 21:05:59.52938+02', NULL, NULL);
INSERT INTO public.notifications (notification_id, user_id, title, message, type, is_read, created_at, updated_at, deleted_at, deleted_by) VALUES ('1e5b68b4-631b-40e3-b788-6cd44e4a0615', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', '✅ Check-in Successful', 'You successfully checked in at 21:49 for Night Shift', 'attendance', false, '2026-03-07 21:49:51.538302+02', '2026-03-07 21:49:51.538302+02', NULL, NULL);
INSERT INTO public.notifications (notification_id, user_id, title, message, type, is_read, created_at, updated_at, deleted_at, deleted_by) VALUES ('f421c80b-e06e-4928-87b8-7d6f09105442', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '✅ Check-in Successful', 'You successfully checked in at 21:52 for Night Shift', 'attendance', true, '2026-03-07 21:52:24.382131+02', '2026-03-07 21:52:43.586296+02', NULL, NULL);

-- Insert request approvals data
INSERT INTO public.request_approvals (request_approval_id, request_id, approver_id, level, action, comment, "timestamp", deleted_at, deleted_by, hod_recommended_from, hod_recommended_to, hod_not_recommended_reason, hr_annual_entitlement, hr_entitlement_taken_from, hr_entitlement_taken_to, hr_last_leave_from, hr_last_leave_to, hr_last_leave_days, hr_balance_if_approved, hr_leave_grant_status, admin_granted_from, admin_granted_to, admin_total_days_approved, accountant_funds_available, accountant_signed_date, hod_trip_recommendation, admin_trip_approval_details) VALUES ('72969686-ebec-4f54-a04d-04b1e04e3b00', '57a42317-f705-4930-a31d-06a5c5070315', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', 1, 'approve', '', '2026-03-06 05:05:21.002739+02', NULL, NULL, '2026-03-04', '2026-03-13', 'understaff', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- Insert requests data
INSERT INTO public.requests (request_id, user_id, type, reason, start_date, end_date, status, current_approver_id, approval_level, approval_comments, created_at, updated_at, deleted_at, deleted_by, travel_date, travel_place, leave_grant_required, contact_address, reason_for_leaving, cost_accommodation, cost_breakfast, cost_lunch, cost_supper, cost_public_transport, cost_fuel_lubricants, cost_total) VALUES ('a6a4cf58-3756-4c0a-8e88-32aeea1d81b1', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'Leave Duty Station', NULL, '2026-03-27', '2026-03-27', 'pending', NULL, 1, NULL, '2026-03-05 17:00:59.770568+02', '2026-03-05 17:00:59.770568+02', NULL, NULL, '2026-03-27', 'lilongwe', false, '', 'tired', 5000.00, 5000.00, NULL, NULL, NULL, NULL, 10000.00);
INSERT INTO public.requests (request_id, user_id, type, reason, start_date, end_date, status, current_approver_id, approval_level, approval_comments, created_at, updated_at, deleted_at, deleted_by, travel_date, travel_place, leave_grant_required, contact_address, reason_for_leaving, cost_accommodation, cost_breakfast, cost_lunch, cost_supper, cost_public_transport, cost_fuel_lubricants, cost_total) VALUES ('57a42317-f705-4930-a31d-06a5c5070315', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'Annual Leave', NULL, '2026-03-04', '2026-03-13', 'pending', NULL, 2, NULL, '2026-03-05 16:52:33.219321+02', '2026-03-06 07:05:20.993147+02', NULL, NULL, NULL, '', true, 'yt', '', NULL, NULL, NULL, NULL, NULL, NULL, 0.00);

-- Insert roles data
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('970f339b-6bb2-4851-a9fc-1b2b89a67b21', 'System Admin', '2026-02-15 12:17:51.57479+02', '2026-02-15 12:17:51.57479+02', NULL, NULL);
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('454a835f-9574-4505-8d14-b89669070fe0', 'HR Admin', '2026-02-17 13:25:49.32529+02', '2026-02-17 13:25:49.32529+02', NULL, NULL);
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('6156a9f6-3140-4478-ac3f-7e69da317a53', 'Head of Department', '2026-02-17 14:03:15.453374+02', '2026-02-17 14:03:15.453374+02', NULL, NULL);
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('163e52d9-6e62-433e-87b6-be851acd4bdb', 'HR', '2026-02-17 14:03:15.453374+02', '2026-02-17 14:03:15.453374+02', NULL, NULL);
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('634bbbf2-4e99-4f48-adb3-f8880809826b', 'Accountant', '2026-02-17 14:03:15.454493+02', '2026-02-17 14:03:15.454493+02', NULL, NULL);
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('92e74f72-6245-49c0-9c18-6d1e8e54df18', 'Principal Hospital Administrator', '2026-02-17 14:03:15.455+02', '2026-02-17 14:03:15.455+02', NULL, NULL);
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('536128db-f948-4f3a-bcdb-46b0438d7af7', 'System Administrator', '2026-02-17 14:03:15.455+02', '2026-02-17 14:03:15.455+02', NULL, NULL);
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('585f3343-9234-47ff-8c6c-021a7b3ca84f', 'Staff', '2026-02-17 14:03:15.455+02', '2026-02-17 14:03:15.455+02', NULL, NULL);

-- Insert users data
INSERT INTO public.users (user_id, employee_number, national_id, first_name, surname, other_names, suffix, date_of_birth, gender, home_of_origin, traditional_authority, district, current_address, contact_number, email, marital_status, spouse_name, spouse_contact, date_of_employment, department_id, is_head_of_department, phone, password_hash, role_id, status, profile_photo_url, blacklisted_at, blacklisted_reason, registration_timestamp, selfie_verified, last_login_at, created_at, updated_at, deleted_at, deleted_by, designation_id, grade_id) VALUES ('b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'EMP2', 'NAT2', 'Maxwell', 'Chisale', 'Yankho', 'MR', '2001-02-04', 'male', 'Mitundu', 'Chiseka', 'Lilongwe', 'st johns', NULL, 'cis-011-21@must.ac.mw', 'single', '', '', '2025-02-02', 'b277017f-5f87-439b-8433-33707796c2b7', false, '0883271664', '$2b$12$8h83NsXhzmBUpB3ktyYrLuV7KMx5sW1DZ8n/qTES7deWf8oyuBE16', '585f3343-9234-47ff-8c6c-021a7b3ca84f', 'active', NULL, NULL, NULL, '2026-02-19 08:27:53.217735+02', false, '2026-03-07 18:37:53.927935+02', '2026-02-19 08:27:53.217735+02', '2026-03-07 20:37:53.567819+02', NULL, NULL, '13e409b4-ccaa-49e8-9fce-c05c67bd7ce6', '83ebcd88-559f-4150-87a5-cfa681c148cd');
INSERT INTO public.users (user_id, employee_number, national_id, first_name, surname, other_names, suffix, date_of_birth, gender, home_of_origin, traditional_authority, district, current_address, contact_number, email, marital_status, spouse_name, spouse_contact, date_of_employment, department_id, is_head_of_department, phone, password_hash, role_id, status, profile_photo_url, blacklisted_at, blacklisted_reason, registration_timestamp, selfie_verified, last_login_at, created_at, updated_at, deleted_at, deleted_by, designation_id, grade_id) VALUES ('ae7fafd7-72ed-428e-9ef3-debc44e02d47', 'Emp1', 'NATIONAL1', 'Yankho', 'Chisale', 'Maxwell', 'Mr', '2001-02-23', 'male', 'Mitundu', 'Chiseka', 'Lilongwe', 'St johns', NULL, 'yankhochisale4@gmail.com', 'single', '', '', '2025-02-01', 'b277017f-5f87-439b-8433-33707796c2b7', false, '0997823454', '$2b$12$ezXx85RHfj/JwHd29YoOuuC52Pdk57bRcyFpGBUNREKHoP/dUXPqa', '970f339b-6bb2-4851-a9fc-1b2b89a67b21', 'active', NULL, NULL, NULL, '2026-02-17 15:59:21.048198+02', false, '2026-03-08 20:57:41.406237+02', '2026-02-17 15:59:21.048198+02', '2026-03-08 22:57:40.822842+02', NULL, NULL, '13e409b4-ccaa-49e8-9fce-c05c67bd7ce6', '0ab214a5-a0cb-42f5-b96d-e1c31b41da86');

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
