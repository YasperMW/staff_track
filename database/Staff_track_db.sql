--
-- PostgreSQL database dump
--

\restrict mBIpgDCm6GuDfgBxjhgGxSvVIquvZtpf5oie9Goqy6Lf5wnvsuafHJ4atUk1hZH

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-03-09 14:33:18

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

--
-- TOC entry 6241 (class 1262 OID 50064)
-- Name: st_johns_hr_system; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE st_johns_hr_system WITH TEMPLATE = template0 ENCODING = 'UTF8' ;


\unrestrict mBIpgDCm6GuDfgBxjhgGxSvVIquvZtpf5oie9Goqy6Lf5wnvsuafHJ4atUk1hZH
\connect st_johns_hr_system
\restrict mBIpgDCm6GuDfgBxjhgGxSvVIquvZtpf5oie9Goqy6Lf5wnvsuafHJ4atUk1hZH

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

--
-- TOC entry 3 (class 3079 OID 51541)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 6242 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- TOC entry 2 (class 3079 OID 51530)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 6243 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 1683 (class 1247 OID 52800)
-- Name: request_status_enum; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.request_status_enum AS ENUM (
    'pending',
    'approved',
    'denied',
    'cancelled',
    'withdrawn'
);


--
-- TOC entry 989 (class 1255 OID 52985)
-- Name: soft_delete_audit(); Type: FUNCTION; Schema: public; Owner: -
--

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


--
-- TOC entry 780 (class 1255 OID 52960)
-- Name: update_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 241 (class 1259 OID 61390)
-- Name: announcement_departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.announcement_departments (
    announcement_id uuid NOT NULL,
    department_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL
);


--
-- TOC entry 240 (class 1259 OID 61331)
-- Name: announcements; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 229 (class 1259 OID 52745)
-- Name: attendance_logs; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 6244 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN attendance_logs.shift_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.attendance_logs.shift_type IS 'The shift type (Day Shift/Night Shift) based on check-in time';


--
-- TOC entry 6245 (class 0 OID 0)
-- Dependencies: 229
-- Name: COLUMN attendance_logs.work_hours; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.attendance_logs.work_hours IS 'Pre-calculated work hours in decimal format';


--
-- TOC entry 234 (class 1259 OID 52909)
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 236 (class 1259 OID 53061)
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    department_id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(150) NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid
);


--
-- TOC entry 237 (class 1259 OID 53082)
-- Name: designations; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 239 (class 1259 OID 61309)
-- Name: email_verifications; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 233 (class 1259 OID 52883)
-- Name: employee_files; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 245 (class 1259 OID 61470)
-- Name: grades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grades (
    grade_id uuid NOT NULL,
    name character varying(50) NOT NULL,
    annual_leave_days integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid
);


--
-- TOC entry 242 (class 1259 OID 61408)
-- Name: holidays; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 228 (class 1259 OID 52708)
-- Name: leave_balances; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 244 (class 1259 OID 61453)
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 238 (class 1259 OID 53117)
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 235 (class 1259 OID 52928)
-- Name: pending_registrations; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 232 (class 1259 OID 52847)
-- Name: request_approvals; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 6246 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.hod_recommended_from; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.hod_recommended_from IS 'HOD recommended start date for leave';


--
-- TOC entry 6247 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.hod_recommended_to; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.hod_recommended_to IS 'HOD recommended end date for leave';


--
-- TOC entry 6248 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.hod_not_recommended_reason; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.hod_not_recommended_reason IS 'HOD reason for not recommending leave';


--
-- TOC entry 6249 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.hr_annual_entitlement; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.hr_annual_entitlement IS 'HR annual leave entitlement';


--
-- TOC entry 6250 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.hr_entitlement_taken_from; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.hr_entitlement_taken_from IS 'HR entitlement taken from date';


--
-- TOC entry 6251 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.hr_entitlement_taken_to; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.hr_entitlement_taken_to IS 'HR entitlement taken to date';


--
-- TOC entry 6252 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.hr_last_leave_from; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.hr_last_leave_from IS 'HR last leave from date';


--
-- TOC entry 6253 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.hr_last_leave_to; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.hr_last_leave_to IS 'HR last leave to date';


--
-- TOC entry 6254 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.hr_last_leave_days; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.hr_last_leave_days IS 'HR last leave days taken';


--
-- TOC entry 6255 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.hr_balance_if_approved; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.hr_balance_if_approved IS 'HR leave balance if approved';


--
-- TOC entry 6256 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.hr_leave_grant_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.hr_leave_grant_status IS 'HR leave grant status';


--
-- TOC entry 6257 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.admin_granted_from; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.admin_granted_from IS 'Admin granted leave from date';


--
-- TOC entry 6258 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.admin_granted_to; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.admin_granted_to IS 'Admin granted leave to date';


--
-- TOC entry 6259 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.admin_total_days_approved; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.admin_total_days_approved IS 'Admin total days approved';


--
-- TOC entry 6260 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.accountant_funds_available; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.accountant_funds_available IS 'Accountant confirmation of funds availability';


--
-- TOC entry 6261 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.accountant_signed_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.accountant_signed_date IS 'Accountant signed date';


--
-- TOC entry 6262 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.hod_trip_recommendation; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.hod_trip_recommendation IS 'HOD trip recommendation';


--
-- TOC entry 6263 (class 0 OID 0)
-- Dependencies: 232
-- Name: COLUMN request_approvals.admin_trip_approval_details; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.request_approvals.admin_trip_approval_details IS 'Admin trip approval details';


--
-- TOC entry 231 (class 1259 OID 52811)
-- Name: requests; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 6264 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN requests.travel_date; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.requests.travel_date IS 'Date of travel for duty station requests';


--
-- TOC entry 6265 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN requests.travel_place; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.requests.travel_place IS 'Destination for duty station requests';


--
-- TOC entry 6266 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN requests.leave_grant_required; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.requests.leave_grant_required IS 'Whether the request requires a leave grant';


--
-- TOC entry 6267 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN requests.contact_address; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.requests.contact_address IS 'Contact address during leave/trip';


--
-- TOC entry 6268 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN requests.reason_for_leaving; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.requests.reason_for_leaving IS 'Reason for leaving duty station';


--
-- TOC entry 6269 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN requests.cost_accommodation; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.requests.cost_accommodation IS 'Cost of accommodation for duty station trips';


--
-- TOC entry 6270 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN requests.cost_breakfast; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.requests.cost_breakfast IS 'Cost of breakfast for duty station trips';


--
-- TOC entry 6271 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN requests.cost_lunch; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.requests.cost_lunch IS 'Cost of lunch for duty station trips';


--
-- TOC entry 6272 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN requests.cost_supper; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.requests.cost_supper IS 'Cost of supper for duty station trips';


--
-- TOC entry 6273 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN requests.cost_public_transport; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.requests.cost_public_transport IS 'Cost of public transport for duty station trips';


--
-- TOC entry 6274 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN requests.cost_fuel_lubricants; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.requests.cost_fuel_lubricants IS 'Cost of fuel and lubricants for duty station trips';


--
-- TOC entry 6275 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN requests.cost_total; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.requests.cost_total IS 'Total cost for duty station trips';


--
-- TOC entry 226 (class 1259 OID 52623)
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    role_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    CONSTRAINT chk_role_name_not_empty CHECK ((TRIM(BOTH FROM name) <> ''::text))
);


--
-- TOC entry 243 (class 1259 OID 61434)
-- Name: user_fcm_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_fcm_tokens (
    token_id uuid NOT NULL,
    user_id uuid NOT NULL,
    fcm_token text NOT NULL,
    device_id character varying(100),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- TOC entry 227 (class 1259 OID 52655)
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 6276 (class 0 OID 0)
-- Dependencies: 227
-- Name: COLUMN users.grade_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.users.grade_id IS 'Reference to the grade table for employee grade information';


--
-- TOC entry 230 (class 1259 OID 52772)
-- Name: work_reports; Type: TABLE; Schema: public; Owner: -
--

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


--
-- TOC entry 6231 (class 0 OID 61390)
-- Dependencies: 241
-- Data for Name: announcement_departments; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 6230 (class 0 OID 61331)
-- Dependencies: 240
-- Data for Name: announcements; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.announcements (announcement_id, title, message, type, target_audience, target_department_id, target_role_id, is_active, expires_at, attachment_url, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('981089b6-3dcb-425e-bf06-cd08f58fba08', 'Holiday', 'asdasdad', 'general', 'All Staff', NULL, NULL, true, '2026-03-03 00:00:00+02', NULL, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 07:18:57.490797+02', '2026-03-02 07:18:57.490797+02', NULL, NULL);
INSERT INTO public.announcements (announcement_id, title, message, type, target_audience, target_department_id, target_role_id, is_active, expires_at, attachment_url, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('01314e2e-1a7d-421d-a3f4-30ed4e84edee', 'asdfghjk', 'asdfghjk', 'general', 'All Staff', NULL, NULL, true, NULL, NULL, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 07:19:39.868772+02', '2026-03-02 07:19:39.868772+02', NULL, NULL);
INSERT INTO public.announcements (announcement_id, title, message, type, target_audience, target_department_id, target_role_id, is_active, expires_at, attachment_url, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('ba394cd9-12a7-4f76-bfcb-7b6b6ce291eb', 'testing', 'testing', 'general', 'Medical, Nursing, IT', NULL, NULL, true, NULL, NULL, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 07:30:55.406572+02', '2026-03-02 07:30:55.406572+02', NULL, NULL);


--
-- TOC entry 6219 (class 0 OID 52745)
-- Dependencies: 229
-- Data for Name: attendance_logs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('b024aff9-2f3e-4d61-9315-46e58790edef', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-02-19 13:08:22.826467+02', NULL, NULL, NULL, NULL, false, NULL, '2026-02-19 13:08:22.826467+02', '2026-02-26 08:15:35.160756+02', NULL, NULL, 'Day Shift', NULL);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('e79c04aa-9987-4f49-8aa7-e03baf4d5974', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-02-24 08:40:04.957727+02', NULL, NULL, NULL, NULL, false, NULL, '2026-02-24 08:40:04.957727+02', '2026-02-26 08:15:35.160756+02', NULL, NULL, 'Day Shift', NULL);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('fe8c55bd-7883-4bb2-b592-78be478869f0', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', '2026-02-24 12:46:35.868274+02', NULL, NULL, NULL, NULL, false, NULL, '2026-02-24 12:46:35.868274+02', '2026-02-26 08:15:35.160756+02', NULL, NULL, 'Day Shift', NULL);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('151fe920-d78e-4913-a527-33eb8d70e337', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-02-26 11:07:35.761374+02', NULL, '0101000020E6100000D42B6519E28041406666666666C62EC0', 10.50, 'test-device-123', false, NULL, '2026-02-26 11:07:35.761374+02', '2026-02-26 11:07:35.761374+02', NULL, NULL, 'Day Shift', NULL);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('72fe8b6a-dffd-42e3-a386-f57636195f8c', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-02-26 11:07:21.481501+02', '2026-02-26 11:08:39.376697+02', '0101000020E6100000D42B6519E28041406666666666C62EC0', 10.50, 'test-device-123', false, NULL, '2026-02-26 11:07:21.481501+02', '2026-02-26 11:08:39.374915+02', NULL, NULL, 'Day Shift', 0.02);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('11185bd4-e7c6-47c8-950d-199bbe11452d', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', '2026-03-05 21:57:54.607223+02', '2026-03-05 21:59:06.43345+02', '0101000020E6100000E8305F5E800341400C923EADA2E726C0', NULL, NULL, false, NULL, '2026-03-05 21:57:54.607223+02', '2026-03-05 21:59:06.419573+02', NULL, NULL, 'Night Shift', 0.02);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('4cf79a18-4899-48a5-847b-3be9026a0301', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-06 20:07:23.932966+02', NULL, '0101000020E6100000E8305F5E800341400C923EADA2E726C0', NULL, NULL, false, NULL, '2026-03-06 20:07:23.932966+02', '2026-03-06 20:07:23.932966+02', NULL, NULL, 'Night Shift', NULL);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('7f774cd0-8e8b-471d-b7ac-0ff23201f9f4', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', '2026-03-07 21:49:51.538302+02', NULL, '0101000020E6100000E8305F5E800341400C923EADA2E726C0', NULL, NULL, false, NULL, '2026-03-07 21:49:51.538302+02', '2026-03-07 21:49:51.538302+02', NULL, NULL, 'Night Shift', NULL);
INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES ('2d2cec59-4702-420a-aeb9-13745c7fbdd8', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-07 21:52:24.382131+02', NULL, '0101000020E6100000E8305F5E800341400C923EADA2E726C0', NULL, NULL, false, NULL, '2026-03-07 21:52:24.382131+02', '2026-03-07 21:52:24.382131+02', NULL, NULL, 'Night Shift', NULL);


--
-- TOC entry 6224 (class 0 OID 52909)
-- Dependencies: 234
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('7b74d33d-2c51-4620-9b60-f59c3ac7c894', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_out', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-05 21:57:04.639363+02', 'attendance', '{"work_hours": 0.12561389694444444, "attendance_log_id": "d6ee992a-b586-4173-b8d1-a8b1954a52a9"}', '2026-03-05 21:57:04.650453+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('5bf9e6f8-ad79-4d27-911a-8ff3cb472707', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_in', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-05 21:57:54.619129+02', 'attendance', '{"attendance_log_id": "11185bd4-e7c6-47c8-950d-199bbe11452d"}', '2026-03-05 21:57:54.622156+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('75b417c3-7764-4754-be38-88fb08c8f107', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_out', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-05 21:59:06.443682+02', 'attendance', '{"work_hours": 0.019951729722222224, "attendance_log_id": "11185bd4-e7c6-47c8-950d-199bbe11452d"}', '2026-03-05 21:59:06.446829+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('d330a42b-e9e1-4af6-9944-f7e1e2499b7a', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', 'check_in', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-06 20:07:23.972794+02', 'attendance', '{"attendance_log_id": "4cf79a18-4899-48a5-847b-3be9026a0301"}', '2026-03-06 20:07:23.994204+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('3cb68dc9-78b0-4a0b-8352-c27878f17c14', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_in', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-07 20:38:16.877362+02', 'attendance', '{"attendance_log_id": "423fc1d6-74bf-4a93-a70d-5571460e8407"}', '2026-03-07 20:38:16.880248+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('7de8e5f7-0ca2-46cd-b744-33514c762609', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_out', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-07 20:45:55.86973+02', 'attendance', '{"work_hours": 0.1274987125, "attendance_log_id": "423fc1d6-74bf-4a93-a70d-5571460e8407"}', '2026-03-07 20:45:55.874531+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('fb58c66a-03a3-41ab-b72d-d4a795776bb1', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_in', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-07 20:49:41.425381+02', 'attendance', '{"attendance_log_id": "08bfe0cf-9788-4416-bab3-a0559309e920"}', '2026-03-07 20:49:41.429241+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('68650329-7a8d-454b-b15f-6f3e80667446', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_in', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-07 21:49:51.57162+02', 'attendance', '{"attendance_log_id": "7f774cd0-8e8b-471d-b7ac-0ff23201f9f4"}', '2026-03-07 21:49:51.580533+02');
INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES ('5ecc10df-09c1-40bf-9914-f4d6e6ee8f00', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', 'check_in', NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-07 21:52:24.396644+02', 'attendance', '{"attendance_log_id": "2d2cec59-4702-420a-aeb9-13745c7fbdd8"}', '2026-03-07 21:52:24.399928+02');


--
-- TOC entry 6226 (class 0 OID 53061)
-- Dependencies: 236
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('8f2c6616-9702-4c17-b4fc-ef8737c96493', 'Emergency Department', 'Provides immediate medical care for acute illnesses and injuries', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', 'Intensive Care Unit (ICU)', 'Provides critical care for seriously ill patients', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('fdc59d81-4f99-456b-99ab-67549128563b', 'Operating Room (OR)', 'Surgical procedures and operations', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('8de34a57-a843-4f93-bb3c-b7293b0ee599', 'Medical-Surgical Unit', 'General medical and surgical patient care', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('31e5ee6f-f076-4106-9e4e-5fc45090fdf0', 'Obstetrics and Gynecology (OB/GYN)', 'Women''s health and childbirth services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('e9563043-70d4-4e5f-af94-ae4284cb79f0', 'Pediatrics', 'Medical care for infants, children, and adolescents', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('42298cff-98f2-4507-8dea-533d7829c667', 'Radiology', 'Medical imaging and diagnostic services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', 'Laboratory', 'Clinical laboratory testing and analysis', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('ccc19504-7d7c-4b52-b2b2-53b63d7660c4', 'Pharmacy', 'Medication dispensing and pharmaceutical care', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('373f5cca-4360-4d30-82e7-a6c16f99da00', 'Physical Therapy', 'Rehabilitation and physical therapy services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('69d1c38d-2d74-4299-817b-517abda58b0f', 'Administration', 'Hospital management and administrative services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('04ebbbce-d888-480d-a1a2-4599109e2d46', 'Finance', 'Financial management and accounting services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('c6615015-4728-473e-a14c-40686e9d597f', 'Human Resources', 'Employee management and HR services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('b277017f-5f87-439b-8433-33707796c2b7', 'Information Technology (IT)', 'Technology infrastructure and IT support', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES ('f2a3c406-0416-4e33-b5aa-7388187b7e9b', 'Marketing and Communications', 'Hospital marketing and public relations', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);


--
-- TOC entry 6227 (class 0 OID 53082)
-- Dependencies: 237
-- Data for Name: designations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('c972b69e-125a-403e-9658-4b11bfeaf966', 'Emergency Physician', 'Physician specializing in emergency medicine', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('1bda7019-d49e-4faa-ba43-08c3f1df779b', 'Emergency Nurse', 'Nurse specializing in emergency care', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('491fc91e-c243-494a-87e4-5141debc6726', 'Paramedic', 'Emergency medical services provider', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('a94bd811-f2c3-4477-9d81-a4078c2ca1fd', 'ER Technician', 'Emergency room technician', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('9c4ceea1-e98d-4ff8-bbb9-214746578645', 'Triage Nurse', 'Nurse responsible for patient assessment and prioritization', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('11383de0-9f62-4ad5-8098-746fe800bb5b', 'Emergency Medical Director', 'Director of emergency medical services', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('16ac60a7-c17e-4b0c-8174-399adf0821e3', 'Trauma Surgeon', 'Surgeon specializing in trauma care', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('7dfd4129-1b2b-481c-80ad-798d2beaf8e4', 'Emergency Department Manager', 'Manager of emergency department operations', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('baf47104-8ffe-4cb8-8cdb-3d034379ff28', 'ICU Physician', 'Physician specializing in critical care', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('2d2457f9-8068-48d1-92ff-fa5768f46ebf', 'Critical Care Nurse', 'Nurse specializing in intensive care', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('78f6e82b-2965-44a9-a50d-66be74771a0a', 'Respiratory Therapist', 'Therapist specializing in respiratory care', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('2281dcdd-5f27-4cd9-9d32-46530dabda6b', 'ICU Manager', 'Manager of intensive care unit', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('ee918036-ad43-4472-b148-b8c696086ce1', 'Critical Care Specialist', 'Specialist in critical care medicine', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('993f3c06-e2f1-48f0-b53b-e1050e81a7ab', 'ICU Technician', 'Technician supporting ICU operations', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('cc859923-22ae-43f7-beb4-d8f5bdd49ebc', 'Pulmonologist', 'Physician specializing in lung diseases', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('22047dea-725d-4e34-8d68-7a30d58dd7db', 'Intensivist', 'Physician specializing in intensive care', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('50c88390-a56e-4449-9a9c-8110dd4ea0ea', 'Surgeon', 'Physician who performs surgical procedures', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('4e5f92e4-fc21-4b75-902a-d4466dcac180', 'Anesthesiologist', 'Physician specializing in anesthesia', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('fed4c1ff-1847-4cd2-ba43-f5de51400b66', 'OR Nurse', 'Nurse assisting in surgical procedures', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('6dd62f17-1fc4-4a33-b78c-b59620f6617a', 'Surgical Technician', 'Technician assisting surgeons', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('c4192d8e-8b3f-4714-9c01-58951f13f007', 'OR Manager', 'Manager of operating room operations', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('f3571f02-ea79-4299-9a44-744893c2282e', 'Perioperative Nurse', 'Nurse specializing in perioperative care', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('a6e81002-255a-44c7-b2f8-725dccb0a60a', 'Surgical Assistant', 'Assistant to surgical team', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('d23197b1-8e63-41e1-80f7-beab8e0dee2a', 'Circulating Nurse', 'Nurse managing operating room flow', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('0a199eaf-567a-4ad4-b2cf-39da1279bccc', 'Staff Nurse', 'Registered nurse providing general patient care', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('841c74fc-c60e-4801-b17f-3a8c8974f0dc', 'Charge Nurse', 'Nurse responsible for unit management', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('470ade43-9e0c-4a6a-a36a-d169b0adad1b', 'Medical-Surgical Nurse', 'Nurse specializing in medical-surgical care', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('7a7e44a8-b540-4964-8bf4-43fa4b662d47', 'Unit Manager', 'Manager of medical-surgical unit', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('39f49ff0-a054-40b4-b95f-f4d89178888d', 'Patient Care Technician', 'Technician assisting with patient care', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('9f904a20-9c18-4d3d-ad6a-ba1492d4c08d', 'Medication Nurse', 'Nurse responsible for medication administration', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('8c24de82-183d-4d5e-b5fe-5f1eb3d5c848', 'Wound Care Nurse', 'Nurse specializing in wound management', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('b984c582-064a-48d2-a87c-fbd6b206c188', 'Case Manager', 'Professional managing patient care coordination', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('fc156203-535e-4d1b-808c-474b1e074ffc', 'OB/GYN Physician', 'Physician specializing in women''s health', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('4c3f78ef-340f-43fc-a1de-ab77a795dfcb', 'Labor and Delivery Nurse', 'Nurse specializing in childbirth care', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('62dda02e-d495-4c85-b297-1eaa3e6ad400', 'Midwife', 'Healthcare professional specializing in childbirth', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('57d4d4d1-e2d3-4312-8915-52f23c06c35c', 'Neonatal Nurse', 'Nurse specializing in newborn care', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('a3cd00f2-a7ce-4d68-8c3e-56ca7f05164b', 'OB Technician', 'Technician assisting in obstetric procedures', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('43b0895c-22d9-49cf-9def-1ae9281d1160', 'Lactation Consultant', 'Specialist in breastfeeding support', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('41232ac8-762c-4af6-9631-9a3cfca9c9a8', 'Gynecological Nurse', 'Nurse specializing in gynecological care', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('3b7f2655-0037-442c-b1c7-c09ba022fcc7', 'Women''s Health Nurse Practitioner', 'Nurse practitioner specializing in women''s health', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('48c83b58-9a0b-4937-bc81-cbcc6192cc5e', 'Pediatrician', 'Physician specializing in child healthcare', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('e853b387-99bf-4788-943b-654210c36afb', 'Pediatric Nurse', 'Nurse specializing in pediatric care', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('e2302de4-f609-4052-bdf8-dcba9f3a8f84', 'Child Life Specialist', 'Specialist supporting children in healthcare', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('5a463cc0-0da7-415c-b812-8816d0e6674f', 'Pediatric Nurse Practitioner', 'Nurse practitioner specializing in pediatrics', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('a77ac9ea-465c-490e-9362-d2ab65da22c0', 'Pediatric Resident', 'Physician in pediatric training', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('12b62337-1ac6-4adc-bde5-f7167509e8f3', 'Pediatric Medical Assistant', 'Medical assistant specializing in pediatrics', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('b660d10b-1a78-4fc3-93fd-90d2cb040b86', 'Developmental Pediatrician', 'Physician specializing in child development', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('9df814b6-c7e7-4924-b9d6-c59aa90f13d4', 'Pediatric Surgeon', 'Surgeon specializing in pediatric surgery', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('a5a4b857-6b9a-47b5-b1cd-8289bea77563', 'Radiologist', 'Physician specializing in medical imaging', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('2b57f7b1-2f8a-4be9-83b4-5e4d63096163', 'Radiology Technician', 'Technician operating medical imaging equipment', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('86500c97-f4b6-47f0-adc4-e19b854985fc', 'X-Ray Technician', 'Technician operating X-ray equipment', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('cdb557c1-4acb-48ea-ab7a-5568672113ad', 'MRI Technician', 'Technician operating MRI equipment', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('958ed11c-fef3-4cac-940d-761788d34071', 'CT Technician', 'Technician operating CT scanner', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('762047ae-0aea-405f-82f2-f52b33f5d6ef', 'Ultrasound Technician', 'Technician operating ultrasound equipment', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('dbced688-7945-4081-99be-ce73a240d719', 'Interventional Radiologist', 'Radiologist performing interventional procedures', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('ae337b22-cbf9-4a70-a876-f0e1855af8c9', 'Radiology Manager', 'Manager of radiology department', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('94cc6364-b173-447d-b519-1739d7afd729', 'Medical Laboratory Scientist', 'Professional performing laboratory tests', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('fc0fd1c1-450e-4572-9c0c-9020a98db030', 'Lab Technician', 'Technician assisting in laboratory operations', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('4b455a51-e0f3-4d0b-a634-48b53fa8ce28', 'Phlebotomist', 'Professional who draws blood for testing', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('8bfedf9d-1b68-4536-ae9b-c841729e6fbb', 'Lab Manager', 'Manager of laboratory operations', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('f611fb32-91d3-44d5-81b9-368ea7952976', 'Clinical Pathologist', 'Physician specializing in laboratory medicine', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('b7f9484d-8673-49d6-a759-d0f1f8ec5706', 'Medical Technologist', 'Technologist performing complex lab tests', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('583d134e-3e1a-4323-8110-1a78dd4db263', 'Cytotechnologist', 'Technologist studying cells for disease', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('9d80cfdf-79a0-484f-9022-8a727f10ba83', 'Histology Technician', 'Technician preparing tissue samples', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('2de1bfb4-ad35-48d5-b8c8-4b9e3617c51b', 'Pharmacist', 'Professional dispensing medications', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('9217f8c4-13c6-48ed-aa94-0b2addc37e8f', 'Pharmacy Technician', 'Technician assisting pharmacists', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('99ea63ff-59fc-46ce-bf90-ffe8390e215e', 'Clinical Pharmacist', 'Pharmacist working with clinical teams', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('ae6a06ff-6912-4b8f-bf35-e4859fe650f8', 'Pharmacy Manager', 'Manager of pharmacy operations', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('7ccdb8ab-dac0-4208-a6f3-cea3e6d75435', 'Compounding Pharmacist', 'Pharmacist preparing customized medications', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('f88d2149-5281-42d7-81ca-2ee2f0a8bed8', 'Oncology Pharmacist', 'Pharmacist specializing in cancer medications', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('e484ab15-90ff-4dc5-a10c-56eb89eb91b2', 'Pharmacy Buyer', 'Professional purchasing medications', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES ('dc3ed1d4-f8ee-4842-9d22-18471b402199', 'Informatics Pharmacist', 'Pharmacist specializing in pharmacy informatics', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
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


--
-- TOC entry 6229 (class 0 OID 61309)
-- Dependencies: 239
-- Data for Name: email_verifications; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.email_verifications (verification_id, email, otp_code, purpose, expires_at, is_used, attempts, created_at, updated_at) VALUES ('e2e1771b-35e0-4204-af3a-dfdbfeccc6dd', 'yankhochisale4@gmail.com', '717504', 'registration', '2026-02-24 06:44:02.721227+02', true, 0, '2026-02-24 06:34:02.721227+02', '2026-02-24 06:34:02.721227+02');
INSERT INTO public.email_verifications (verification_id, email, otp_code, purpose, expires_at, is_used, attempts, created_at, updated_at) VALUES ('0ccdacac-0e41-4397-ba43-a9fdd9ea3a63', 'yankhochisale4@gmail.com', '762754', 'registration', '2026-02-24 06:47:21.239062+02', true, 0, '2026-02-24 06:37:21.239062+02', '2026-02-24 06:38:11.798771+02');
INSERT INTO public.email_verifications (verification_id, email, otp_code, purpose, expires_at, is_used, attempts, created_at, updated_at) VALUES ('851b4372-3a33-40b1-a56e-c86310f4cfdb', 'cis-011-21@must.ac.mw', '718243', 'registration', '2026-02-24 10:54:58.86864+02', true, 0, '2026-02-24 10:44:58.86864+02', '2026-02-24 10:45:28.485198+02');


--
-- TOC entry 6223 (class 0 OID 52883)
-- Dependencies: 233
-- Data for Name: employee_files; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.employee_files (employee_file_id, user_id, file_type, file_url, original_filename, upload_date, created_at, deleted_at, deleted_by) VALUES ('0dfa5a6d-6ae5-475f-ba7d-ece43285aca4', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', 'payslip', 'http://0.0.0.0:8000/uploads/employee_files/a146d69d-5a31-4305-bc9d-82258bcb9981.png', NULL, '2026-03-05 07:08:27.110744+02', '2026-03-05 09:08:27.115243+02', NULL, NULL);


--
-- TOC entry 6235 (class 0 OID 61470)
-- Dependencies: 245
-- Data for Name: grades; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.grades (grade_id, name, annual_leave_days, created_at, updated_at, deleted_at, deleted_by) VALUES ('385c3adb-2efa-49e8-be46-f2432055dc01', 'Grade A', 30, '2026-03-05 18:12:21.009858+02', '2026-03-05 18:12:21.009858+02', NULL, NULL);
INSERT INTO public.grades (grade_id, name, annual_leave_days, created_at, updated_at, deleted_at, deleted_by) VALUES ('0ab214a5-a0cb-42f5-b96d-e1c31b41da86', 'Grade B', 28, '2026-03-05 18:12:21.009858+02', '2026-03-05 18:12:21.009858+02', NULL, NULL);
INSERT INTO public.grades (grade_id, name, annual_leave_days, created_at, updated_at, deleted_at, deleted_by) VALUES ('2619c1a2-1324-4ff1-9797-77918409c57e', 'Grade C', 25, '2026-03-05 18:12:21.009858+02', '2026-03-05 18:12:21.009858+02', NULL, NULL);
INSERT INTO public.grades (grade_id, name, annual_leave_days, created_at, updated_at, deleted_at, deleted_by) VALUES ('6146c040-bb4c-4a70-9ada-7727d3794664', 'Grade D', 21, '2026-03-05 18:12:21.009858+02', '2026-03-05 18:12:21.009858+02', NULL, NULL);
INSERT INTO public.grades (grade_id, name, annual_leave_days, created_at, updated_at, deleted_at, deleted_by) VALUES ('83ebcd88-559f-4150-87a5-cfa681c148cd', 'Grade E', 18, '2026-03-05 18:12:21.009858+02', '2026-03-05 18:12:21.009858+02', NULL, NULL);


--
-- TOC entry 6232 (class 0 OID 61408)
-- Dependencies: 242
-- Data for Name: holidays; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.holidays (holiday_id, name, date, description, type, category, source, country_code, is_recurring, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('25082a67-a444-46ad-9181-44f062a1df63', 'ash', '2026-03-03', 'asdfghjk', 'Institutional Holiday', 'institutional', 'manual', 'MW', false, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:08:03.93446+02', '2026-03-02 08:24:01.097879+02', '2026-03-02 08:24:01.097879+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47');
INSERT INTO public.holidays (holiday_id, name, date, description, type, category, source, country_code, is_recurring, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('cb0435ae-4c3d-47d0-b680-921e9a356a6f', 'testing', '2026-03-04', 'test 2', 'Institutional Holiday', 'institutional', 'manual', 'MW', false, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:16:22.162834+02', '2026-03-02 08:24:31.45783+02', '2026-03-02 08:24:31.45783+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47');
INSERT INTO public.holidays (holiday_id, name, date, description, type, category, source, country_code, is_recurring, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('5ebab23e-3d11-4308-aa10-fed829f750f3', 'testing', '2026-03-04', 'test 2', 'Institutional Holiday', 'institutional', 'manual', 'MW', false, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:16:26.298139+02', '2026-03-02 08:30:57.248916+02', '2026-03-02 08:30:57.248916+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47');
INSERT INTO public.holidays (holiday_id, name, date, description, type, category, source, country_code, is_recurring, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('4f4b1e01-84b0-4ce2-9a86-9cb58852775e', 'test 3', '2026-03-05', 'testing 3', 'Institutional Holiday', 'institutional', 'manual', 'MW', false, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:19:29.280819+02', '2026-03-02 08:36:09.584385+02', '2026-03-02 08:36:09.584385+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47');
INSERT INTO public.holidays (holiday_id, name, date, description, type, category, source, country_code, is_recurring, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('97e30f20-18a4-4b94-b966-8b27b3b7b224', 'test', '2026-03-12', 'ad', 'Institutional Holiday', 'institutional', 'manual', 'MW', true, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:35:59.41296+02', '2026-03-02 08:42:55.292843+02', '2026-03-02 08:42:55.292843+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47');
INSERT INTO public.holidays (holiday_id, name, date, description, type, category, source, country_code, is_recurring, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES ('f413c875-ebd6-4acd-b7fc-f38954bd7974', 'is it working', '2026-03-04', 'maybe', 'Institutional Holiday', 'institutional', 'manual', 'MW', true, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 09:22:25.68131+02', '2026-03-02 09:22:25.68131+02', NULL, NULL);


--
-- TOC entry 6218 (class 0 OID 52708)
-- Dependencies: 228
-- Data for Name: leave_balances; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 6234 (class 0 OID 61453)
-- Dependencies: 244
-- Data for Name: notification_preferences; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 6228 (class 0 OID 53117)
-- Dependencies: 238
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

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


--
-- TOC entry 6225 (class 0 OID 52928)
-- Dependencies: 235
-- Data for Name: pending_registrations; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 6222 (class 0 OID 52847)
-- Dependencies: 232
-- Data for Name: request_approvals; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.request_approvals (request_approval_id, request_id, approver_id, level, action, comment, "timestamp", deleted_at, deleted_by, hod_recommended_from, hod_recommended_to, hod_not_recommended_reason, hr_annual_entitlement, hr_entitlement_taken_from, hr_entitlement_taken_to, hr_last_leave_from, hr_last_leave_to, hr_last_leave_days, hr_balance_if_approved, hr_leave_grant_status, admin_granted_from, admin_granted_to, admin_total_days_approved, accountant_funds_available, accountant_signed_date, hod_trip_recommendation, admin_trip_approval_details) VALUES ('72969686-ebec-4f54-a04d-04b1e04e3b00', '57a42317-f705-4930-a31d-06a5c5070315', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', 1, 'approve', '', '2026-03-06 05:05:21.002739+02', NULL, NULL, '2026-03-04', '2026-03-13', 'understaff', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--
-- TOC entry 6221 (class 0 OID 52811)
-- Dependencies: 231
-- Data for Name: requests; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.requests (request_id, user_id, type, reason, start_date, end_date, status, current_approver_id, approval_level, approval_comments, created_at, updated_at, deleted_at, deleted_by, travel_date, travel_place, leave_grant_required, contact_address, reason_for_leaving, cost_accommodation, cost_breakfast, cost_lunch, cost_supper, cost_public_transport, cost_fuel_lubricants, cost_total) VALUES ('a6a4cf58-3756-4c0a-8e88-32aeea1d81b1', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'Leave Duty Station', NULL, '2026-03-27', '2026-03-27', 'pending', NULL, 1, NULL, '2026-03-05 17:00:59.770568+02', '2026-03-05 17:00:59.770568+02', NULL, NULL, '2026-03-27', 'lilongwe', false, '', 'tired', 5000.00, 5000.00, NULL, NULL, NULL, NULL, 10000.00);
INSERT INTO public.requests (request_id, user_id, type, reason, start_date, end_date, status, current_approver_id, approval_level, approval_comments, created_at, updated_at, deleted_at, deleted_by, travel_date, travel_place, leave_grant_required, contact_address, reason_for_leaving, cost_accommodation, cost_breakfast, cost_lunch, cost_supper, cost_public_transport, cost_fuel_lubricants, cost_total) VALUES ('57a42317-f705-4930-a31d-06a5c5070315', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'Annual Leave', NULL, '2026-03-04', '2026-03-13', 'pending', NULL, 2, NULL, '2026-03-05 16:52:33.219321+02', '2026-03-06 07:05:20.993147+02', NULL, NULL, NULL, '', true, 'yt', '', NULL, NULL, NULL, NULL, NULL, NULL, 0.00);


--
-- TOC entry 6216 (class 0 OID 52623)
-- Dependencies: 226
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('970f339b-6bb2-4851-a9fc-1b2b89a67b21', 'System Admin', '2026-02-15 12:17:51.57479+02', '2026-02-15 12:17:51.57479+02', NULL, NULL);
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('454a835f-9574-4505-8d14-b89669070fe0', 'HR Admin', '2026-02-17 13:25:49.32529+02', '2026-02-17 13:25:49.32529+02', NULL, NULL);
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('6156a9f6-3140-4478-ac3f-7e69da317a53', 'Head of Department', '2026-02-17 14:03:15.453374+02', '2026-02-17 14:03:15.453374+02', NULL, NULL);
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('163e52d9-6e62-433e-87b6-be851acd4bdb', 'HR', '2026-02-17 14:03:15.453374+02', '2026-02-17 14:03:15.453374+02', NULL, NULL);
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('634bbbf2-4e99-4f48-adb3-f8880809826b', 'Accountant', '2026-02-17 14:03:15.454493+02', '2026-02-17 14:03:15.454493+02', NULL, NULL);
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('92e74f72-6245-49c0-9c18-6d1e8e54df18', 'Principal Hospital Administrator', '2026-02-17 14:03:15.455+02', '2026-02-17 14:03:15.455+02', NULL, NULL);
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('536128db-f948-4f3a-bcdb-46b0438d7af7', 'System Administrator', '2026-02-17 14:03:15.455+02', '2026-02-17 14:03:15.455+02', NULL, NULL);
INSERT INTO public.roles (role_id, name, created_at, updated_at, deleted_at, deleted_by) VALUES ('585f3343-9234-47ff-8c6c-021a7b3ca84f', 'Staff', '2026-02-17 14:03:15.455+02', '2026-02-17 14:03:15.455+02', NULL, NULL);


--
-- TOC entry 5859 (class 0 OID 51860)
-- Dependencies: 222
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 6233 (class 0 OID 61434)
-- Dependencies: 243
-- Data for Name: user_fcm_tokens; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 6217 (class 0 OID 52655)
-- Dependencies: 227
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users (user_id, employee_number, national_id, first_name, surname, other_names, suffix, date_of_birth, gender, home_of_origin, traditional_authority, district, current_address, contact_number, email, marital_status, spouse_name, spouse_contact, date_of_employment, department_id, is_head_of_department, phone, password_hash, role_id, status, profile_photo_url, blacklisted_at, blacklisted_reason, registration_timestamp, selfie_verified, last_login_at, created_at, updated_at, deleted_at, deleted_by, designation_id, grade_id) VALUES ('b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'EMP2', 'NAT2', 'Maxwell', 'Chisale', 'Yankho', 'MR', '2001-02-04', 'male', 'Mitundu', 'Chiseka', 'Lilongwe', 'st johns', NULL, 'cis-011-21@must.ac.mw', 'single', '', '', '2025-02-02', 'b277017f-5f87-439b-8433-33707796c2b7', false, '0883271664', '$2b$12$8h83NsXhzmBUpB3ktyYrLuV7KMx5sW1DZ8n/qTES7deWf8oyuBE16', '585f3343-9234-47ff-8c6c-021a7b3ca84f', 'active', NULL, NULL, NULL, '2026-02-19 08:27:53.217735+02', false, '2026-03-07 18:37:53.927935+02', '2026-02-19 08:27:53.217735+02', '2026-03-07 20:37:53.567819+02', NULL, NULL, '13e409b4-ccaa-49e8-9fce-c05c67bd7ce6', '83ebcd88-559f-4150-87a5-cfa681c148cd');
INSERT INTO public.users (user_id, employee_number, national_id, first_name, surname, other_names, suffix, date_of_birth, gender, home_of_origin, traditional_authority, district, current_address, contact_number, email, marital_status, spouse_name, spouse_contact, date_of_employment, department_id, is_head_of_department, phone, password_hash, role_id, status, profile_photo_url, blacklisted_at, blacklisted_reason, registration_timestamp, selfie_verified, last_login_at, created_at, updated_at, deleted_at, deleted_by, designation_id, grade_id) VALUES ('ae7fafd7-72ed-428e-9ef3-debc44e02d47', 'Emp1', 'NATIONAL1', 'Yankho', 'Chisale', 'Maxwell', 'Mr', '2001-02-23', 'male', 'Mitundu', 'Chiseka', 'Lilongwe', 'St johns', NULL, 'yankhochisale4@gmail.com', 'single', '', '', '2025-02-01', 'b277017f-5f87-439b-8433-33707796c2b7', false, '0997823454', '$2b$12$ezXx85RHfj/JwHd29YoOuuC52Pdk57bRcyFpGBUNREKHoP/dUXPqa', '970f339b-6bb2-4851-a9fc-1b2b89a67b21', 'active', NULL, NULL, NULL, '2026-02-17 15:59:21.048198+02', false, '2026-03-08 20:57:41.406237+02', '2026-02-17 15:59:21.048198+02', '2026-03-08 22:57:40.822842+02', NULL, NULL, '13e409b4-ccaa-49e8-9fce-c05c67bd7ce6', '0ab214a5-a0cb-42f5-b96d-e1c31b41da86');


--
-- TOC entry 6220 (class 0 OID 52772)
-- Dependencies: 230
-- Data for Name: work_reports; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 5995 (class 2606 OID 61397)
-- Name: announcement_departments announcement_departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcement_departments
    ADD CONSTRAINT announcement_departments_pkey PRIMARY KEY (announcement_id, department_id);


--
-- TOC entry 5993 (class 2606 OID 61345)
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (announcement_id);


--
-- TOC entry 5954 (class 2606 OID 52760)
-- Name: attendance_logs attendance_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_logs
    ADD CONSTRAINT attendance_logs_pkey PRIMARY KEY (attendance_log_id);


--
-- TOC entry 5969 (class 2606 OID 61469)
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (audit_id);


--
-- TOC entry 5977 (class 2606 OID 53076)
-- Name: departments departments_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_name_key UNIQUE (name);


--
-- TOC entry 5979 (class 2606 OID 53074)
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id);


--
-- TOC entry 5982 (class 2606 OID 53098)
-- Name: designations designations_department_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.designations
    ADD CONSTRAINT designations_department_id_name_key UNIQUE (department_id, name);


--
-- TOC entry 5984 (class 2606 OID 53096)
-- Name: designations designations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.designations
    ADD CONSTRAINT designations_pkey PRIMARY KEY (designation_id);


--
-- TOC entry 5990 (class 2606 OID 61320)
-- Name: email_verifications email_verifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_verifications
    ADD CONSTRAINT email_verifications_pkey PRIMARY KEY (verification_id);


--
-- TOC entry 5967 (class 2606 OID 52898)
-- Name: employee_files employee_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_files
    ADD CONSTRAINT employee_files_pkey PRIMARY KEY (employee_file_id);


--
-- TOC entry 6007 (class 2606 OID 61481)
-- Name: grades grades_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_name_key UNIQUE (name);


--
-- TOC entry 6009 (class 2606 OID 61479)
-- Name: grades grades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_pkey PRIMARY KEY (grade_id);


--
-- TOC entry 5997 (class 2606 OID 61421)
-- Name: holidays holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (holiday_id);


--
-- TOC entry 5950 (class 2606 OID 52732)
-- Name: leave_balances leave_balances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_pkey PRIMARY KEY (leave_balance_id);


--
-- TOC entry 6005 (class 2606 OID 61462)
-- Name: notification_preferences notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (preference_id);


--
-- TOC entry 5988 (class 2606 OID 53130)
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);


--
-- TOC entry 5973 (class 2606 OID 52949)
-- Name: pending_registrations pending_registrations_employee_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pending_registrations
    ADD CONSTRAINT pending_registrations_employee_number_key UNIQUE (employee_number);


--
-- TOC entry 5975 (class 2606 OID 52947)
-- Name: pending_registrations pending_registrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pending_registrations
    ADD CONSTRAINT pending_registrations_pkey PRIMARY KEY (pending_registration_id);


--
-- TOC entry 5963 (class 2606 OID 52864)
-- Name: request_approvals request_approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_approvals
    ADD CONSTRAINT request_approvals_pkey PRIMARY KEY (request_approval_id);


--
-- TOC entry 5961 (class 2606 OID 52831)
-- Name: requests requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT requests_pkey PRIMARY KEY (request_id);


--
-- TOC entry 5934 (class 2606 OID 52637)
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- TOC entry 5936 (class 2606 OID 52635)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- TOC entry 5965 (class 2606 OID 52866)
-- Name: request_approvals unique_approval_per_level; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_approvals
    ADD CONSTRAINT unique_approval_per_level UNIQUE (request_id, level);


--
-- TOC entry 5952 (class 2606 OID 52734)
-- Name: leave_balances unique_user_leave_year; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT unique_user_leave_year UNIQUE (user_id, leave_type, year);


--
-- TOC entry 6001 (class 2606 OID 61447)
-- Name: user_fcm_tokens user_fcm_tokens_fcm_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_fcm_tokens
    ADD CONSTRAINT user_fcm_tokens_fcm_token_key UNIQUE (fcm_token);


--
-- TOC entry 6003 (class 2606 OID 61445)
-- Name: user_fcm_tokens user_fcm_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_fcm_tokens
    ADD CONSTRAINT user_fcm_tokens_pkey PRIMARY KEY (token_id);


--
-- TOC entry 5938 (class 2606 OID 52688)
-- Name: users users_contact_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_contact_number_key UNIQUE (contact_number);


--
-- TOC entry 5940 (class 2606 OID 52690)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 5942 (class 2606 OID 52684)
-- Name: users users_employee_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_employee_number_key UNIQUE (employee_number);


--
-- TOC entry 5944 (class 2606 OID 52686)
-- Name: users users_national_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_national_id_key UNIQUE (national_id);


--
-- TOC entry 5946 (class 2606 OID 52692)
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- TOC entry 5948 (class 2606 OID 52682)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 5958 (class 2606 OID 52788)
-- Name: work_reports work_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_reports
    ADD CONSTRAINT work_reports_pkey PRIMARY KEY (work_report_id);


--
-- TOC entry 5955 (class 1259 OID 52771)
-- Name: idx_attendance_location_gist; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_attendance_location_gist ON public.attendance_logs USING gist (location);


--
-- TOC entry 5956 (class 1259 OID 61330)
-- Name: idx_attendance_shift_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_attendance_shift_type ON public.attendance_logs USING btree (shift_type);


--
-- TOC entry 5970 (class 1259 OID 52926)
-- Name: idx_audit_actor_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_actor_time ON public.audit_logs USING btree (actor_id, occurred_at);


--
-- TOC entry 5971 (class 1259 OID 52927)
-- Name: idx_audit_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_entity ON public.audit_logs USING btree (entity_type, entity_id);


--
-- TOC entry 5980 (class 1259 OID 53109)
-- Name: idx_departments_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_departments_name ON public.departments USING btree (name);


--
-- TOC entry 5985 (class 1259 OID 53110)
-- Name: idx_designations_department_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_designations_department_id ON public.designations USING btree (department_id);


--
-- TOC entry 5986 (class 1259 OID 53111)
-- Name: idx_designations_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_designations_name ON public.designations USING btree (name);


--
-- TOC entry 5998 (class 1259 OID 61432)
-- Name: idx_holidays_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_holidays_category ON public.holidays USING btree (category);


--
-- TOC entry 5999 (class 1259 OID 61433)
-- Name: idx_holidays_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_holidays_source ON public.holidays USING btree (source);


--
-- TOC entry 5959 (class 1259 OID 52882)
-- Name: idx_requests_pending_approver; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_requests_pending_approver ON public.requests USING btree (current_approver_id) WHERE ((status = 'pending'::public.request_status_enum) AND (deleted_at IS NULL));


--
-- TOC entry 5991 (class 1259 OID 61321)
-- Name: ix_email_verifications_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_email_verifications_email ON public.email_verifications USING btree (email);


--
-- TOC entry 6053 (class 2620 OID 52990)
-- Name: attendance_logs trg_attendance_logs_soft_delete_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_attendance_logs_soft_delete_audit BEFORE UPDATE ON public.attendance_logs FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();


--
-- TOC entry 6054 (class 2620 OID 52965)
-- Name: attendance_logs trg_attendance_logs_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_attendance_logs_update_timestamp BEFORE UPDATE ON public.attendance_logs FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- TOC entry 6060 (class 2620 OID 52994)
-- Name: employee_files trg_employee_files_soft_delete_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_employee_files_soft_delete_audit BEFORE UPDATE ON public.employee_files FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();


--
-- TOC entry 6061 (class 2620 OID 52968)
-- Name: employee_files trg_employee_files_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_employee_files_update_timestamp BEFORE UPDATE ON public.employee_files FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- TOC entry 6051 (class 2620 OID 52989)
-- Name: leave_balances trg_leave_balances_soft_delete_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_leave_balances_soft_delete_audit BEFORE UPDATE ON public.leave_balances FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();


--
-- TOC entry 6052 (class 2620 OID 52964)
-- Name: leave_balances trg_leave_balances_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_leave_balances_update_timestamp BEFORE UPDATE ON public.leave_balances FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- TOC entry 6062 (class 2620 OID 52995)
-- Name: pending_registrations trg_pending_registrations_soft_delete_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_pending_registrations_soft_delete_audit BEFORE UPDATE ON public.pending_registrations FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();


--
-- TOC entry 6063 (class 2620 OID 52969)
-- Name: pending_registrations trg_pending_registrations_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_pending_registrations_update_timestamp BEFORE UPDATE ON public.pending_registrations FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- TOC entry 6059 (class 2620 OID 52993)
-- Name: request_approvals trg_request_approvals_soft_delete_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_request_approvals_soft_delete_audit BEFORE UPDATE ON public.request_approvals FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();


--
-- TOC entry 6057 (class 2620 OID 52992)
-- Name: requests trg_requests_soft_delete_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_requests_soft_delete_audit BEFORE UPDATE ON public.requests FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();


--
-- TOC entry 6058 (class 2620 OID 52967)
-- Name: requests trg_requests_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_requests_update_timestamp BEFORE UPDATE ON public.requests FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- TOC entry 6047 (class 2620 OID 52987)
-- Name: roles trg_roles_soft_delete_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_roles_soft_delete_audit BEFORE UPDATE ON public.roles FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();


--
-- TOC entry 6048 (class 2620 OID 52962)
-- Name: roles trg_roles_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_roles_update_timestamp BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- TOC entry 6049 (class 2620 OID 52986)
-- Name: users trg_users_soft_delete_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_users_soft_delete_audit BEFORE UPDATE ON public.users FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();


--
-- TOC entry 6050 (class 2620 OID 52961)
-- Name: users trg_users_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_users_update_timestamp BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- TOC entry 6055 (class 2620 OID 52991)
-- Name: work_reports trg_work_reports_soft_delete_audit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_work_reports_soft_delete_audit BEFORE UPDATE ON public.work_reports FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();


--
-- TOC entry 6056 (class 2620 OID 52966)
-- Name: work_reports trg_work_reports_update_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_work_reports_update_timestamp BEFORE UPDATE ON public.work_reports FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- TOC entry 6040 (class 2606 OID 61398)
-- Name: announcement_departments announcement_departments_announcement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcement_departments
    ADD CONSTRAINT announcement_departments_announcement_id_fkey FOREIGN KEY (announcement_id) REFERENCES public.announcements(announcement_id);


--
-- TOC entry 6041 (class 2606 OID 61403)
-- Name: announcement_departments announcement_departments_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcement_departments
    ADD CONSTRAINT announcement_departments_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id);


--
-- TOC entry 6036 (class 2606 OID 61356)
-- Name: announcements announcements_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- TOC entry 6037 (class 2606 OID 61361)
-- Name: announcements announcements_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id);


--
-- TOC entry 6038 (class 2606 OID 61346)
-- Name: announcements announcements_target_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_target_department_id_fkey FOREIGN KEY (target_department_id) REFERENCES public.departments(department_id);


--
-- TOC entry 6039 (class 2606 OID 61351)
-- Name: announcements announcements_target_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_target_role_id_fkey FOREIGN KEY (target_role_id) REFERENCES public.roles(role_id);


--
-- TOC entry 6017 (class 2606 OID 52766)
-- Name: attendance_logs attendance_logs_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_logs
    ADD CONSTRAINT attendance_logs_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- TOC entry 6018 (class 2606 OID 52761)
-- Name: attendance_logs attendance_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_logs
    ADD CONSTRAINT attendance_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 6029 (class 2606 OID 52921)
-- Name: audit_logs audit_logs_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- TOC entry 6031 (class 2606 OID 53077)
-- Name: departments departments_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id);


--
-- TOC entry 6032 (class 2606 OID 53104)
-- Name: designations designations_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.designations
    ADD CONSTRAINT designations_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id);


--
-- TOC entry 6033 (class 2606 OID 53099)
-- Name: designations designations_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.designations
    ADD CONSTRAINT designations_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id) ON DELETE CASCADE;


--
-- TOC entry 6027 (class 2606 OID 52904)
-- Name: employee_files employee_files_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_files
    ADD CONSTRAINT employee_files_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- TOC entry 6028 (class 2606 OID 52899)
-- Name: employee_files employee_files_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.employee_files
    ADD CONSTRAINT employee_files_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 6010 (class 2606 OID 52970)
-- Name: roles fk_roles_deleted_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT fk_roles_deleted_by FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- TOC entry 6046 (class 2606 OID 61482)
-- Name: grades grades_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id);


--
-- TOC entry 6042 (class 2606 OID 61422)
-- Name: holidays holidays_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id);


--
-- TOC entry 6043 (class 2606 OID 61427)
-- Name: holidays holidays_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id);


--
-- TOC entry 6015 (class 2606 OID 52740)
-- Name: leave_balances leave_balances_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- TOC entry 6016 (class 2606 OID 52735)
-- Name: leave_balances leave_balances_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leave_balances
    ADD CONSTRAINT leave_balances_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 6045 (class 2606 OID 61463)
-- Name: notification_preferences notification_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_preferences
    ADD CONSTRAINT notification_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 6034 (class 2606 OID 53136)
-- Name: notifications notifications_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id);


--
-- TOC entry 6035 (class 2606 OID 53131)
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 6030 (class 2606 OID 52955)
-- Name: pending_registrations pending_registrations_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pending_registrations
    ADD CONSTRAINT pending_registrations_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- TOC entry 6024 (class 2606 OID 52872)
-- Name: request_approvals request_approvals_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_approvals
    ADD CONSTRAINT request_approvals_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(user_id) ON DELETE RESTRICT;


--
-- TOC entry 6025 (class 2606 OID 52877)
-- Name: request_approvals request_approvals_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_approvals
    ADD CONSTRAINT request_approvals_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- TOC entry 6026 (class 2606 OID 52867)
-- Name: request_approvals request_approvals_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.request_approvals
    ADD CONSTRAINT request_approvals_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.requests(request_id) ON DELETE CASCADE;


--
-- TOC entry 6021 (class 2606 OID 52837)
-- Name: requests requests_current_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT requests_current_approver_id_fkey FOREIGN KEY (current_approver_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- TOC entry 6022 (class 2606 OID 52842)
-- Name: requests requests_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT requests_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- TOC entry 6023 (class 2606 OID 52832)
-- Name: requests requests_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.requests
    ADD CONSTRAINT requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- TOC entry 6044 (class 2606 OID 61448)
-- Name: user_fcm_tokens user_fcm_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_fcm_tokens
    ADD CONSTRAINT user_fcm_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 6011 (class 2606 OID 52703)
-- Name: users users_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- TOC entry 6012 (class 2606 OID 53112)
-- Name: users users_designation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_designation_id_fkey FOREIGN KEY (designation_id) REFERENCES public.designations(designation_id);


--
-- TOC entry 6013 (class 2606 OID 61497)
-- Name: users users_grade_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_grade_id_fkey FOREIGN KEY (grade_id) REFERENCES public.grades(grade_id);


--
-- TOC entry 6014 (class 2606 OID 52698)
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON DELETE RESTRICT;


--
-- TOC entry 6019 (class 2606 OID 52794)
-- Name: work_reports work_reports_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_reports
    ADD CONSTRAINT work_reports_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- TOC entry 6020 (class 2606 OID 52789)
-- Name: work_reports work_reports_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_reports
    ADD CONSTRAINT work_reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


-- Completed on 2026-03-09 14:33:19

--
-- PostgreSQL database dump complete
--

\unrestrict mBIpgDCm6GuDfgBxjhgGxSvVIquvZtpf5oie9Goqy6Lf5wnvsuafHJ4atUk1hZH

