-- PostgreSQL database dump - Cleaned for DBeaver compatibility
-- Original dump from pgAdmin 4 on Windows

-- Set session configuration
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



DROP DATABASE IF EXISTS st_johns_hr_system;
--
-- TOC entry 6168 (class 1262 OID 50064)
-- Name: st_johns_hr_system; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE st_johns_hr_system WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_Malawi.1252';


ALTER DATABASE st_johns_hr_system OWNER TO postgres;

-- Create extensions (these must be created by superuser)
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Create custom type
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
    CONSTRAINT attendance_logs_accuracy_check CHECK ((accuracy >= (0)::numeric))
);

CREATE TABLE public.audit_logs (
    audit_log_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    actor_id uuid,
    action character varying(100) NOT NULL,
    entity_type character varying(50),
    entity_id uuid,
    old_value jsonb,
    new_value jsonb,
    ip_address inet,
    user_agent text,
    occurred_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
    approved_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    CONSTRAINT chk_deny_requires_comment CHECK ((((action)::text <> 'deny'::text) OR ((comment IS NOT NULL) AND (TRIM(BOTH FROM comment) <> ''::text)))),
    CONSTRAINT request_approvals_action_check CHECK (((action)::text = ANY ((ARRAY['approve'::character varying, 'deny'::character varying])::text[]))),
    CONSTRAINT request_approvals_level_check CHECK (((level >= 1) AND (level <= 5)))
);

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
    CONSTRAINT requests_approval_level_check CHECK (((approval_level >= 1) AND (approval_level <= 5)))
);

CREATE TABLE public.roles (
    role_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    CONSTRAINT chk_role_name_not_empty CHECK ((TRIM(BOTH FROM name) <> ''::text))
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
    CONSTRAINT chk_employee_number_not_empty CHECK ((TRIM(BOTH FROM employee_number) <> ''::text)),
    CONSTRAINT chk_names_not_empty CHECK (((TRIM(BOTH FROM first_name) <> ''::text) AND (TRIM(BOTH FROM surname) <> ''::text))),
    CONSTRAINT users_gender_check CHECK (((gender)::text = ANY ((ARRAY['male'::character varying, 'female'::character varying, 'other'::character varying])::text[]))),
    CONSTRAINT users_marital_status_check CHECK (((marital_status)::text = ANY ((ARRAY['single'::character varying, 'married'::character varying, 'divorced'::character varying, 'widowed'::character varying])::text[]))),
    CONSTRAINT users_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'active'::character varying, 'suspended'::character varying, 'blacklisted'::character varying, 'terminated'::character varying])::text[])))
);

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

--- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.departments VALUES ('8f2c6616-9702-4c17-b4fc-ef8737c96493', 'Emergency Department', 'Provides immediate medical care for acute illnesses and injuries', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments VALUES ('a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', 'Intensive Care Unit (ICU)', 'Provides critical care for seriously ill patients', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments VALUES ('fdc59d81-4f99-456b-99ab-67549128563b', 'Operating Room (OR)', 'Surgical procedures and operations', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments VALUES ('8de34a57-a843-4f93-bb3c-b7293b0ee599', 'Medical-Surgical Unit', 'General medical and surgical patient care', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments VALUES ('31e5ee6f-f076-4106-9e4e-5fc45090fdf0', 'Obstetrics and Gynecology (OB/GYN)', 'Women''s health and childbirth services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments VALUES ('e9563043-70d4-4e5f-af94-ae4284cb79f0', 'Pediatrics', 'Medical care for infants, children, and adolescents', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments VALUES ('42298cff-98f2-4507-8dea-533d7829c667', 'Radiology', 'Medical imaging and diagnostic services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments VALUES ('7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', 'Laboratory', 'Clinical laboratory testing and analysis', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments VALUES ('ccc19504-7d7c-4b52-b2b2-53b63d7660c4', 'Pharmacy', 'Medication dispensing and pharmaceutical care', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments VALUES ('373f5cca-4360-4d30-82e7-a6c16f99da00', 'Physical Therapy', 'Rehabilitation and physical therapy services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments VALUES ('69d1c38d-2d74-4299-817b-517abda58b0f', 'Administration', 'Hospital management and administrative services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments VALUES ('04ebbbce-d888-480d-a1a2-4599109e2d46', 'Finance', 'Financial management and accounting services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments VALUES ('c6615015-4728-473e-a14c-40686e9d597f', 'Human Resources', 'Employee management and HR services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments VALUES ('b277017f-5f87-439b-8433-33707796c2b7', 'Information Technology (IT)', 'Technology infrastructure and IT support', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.departments VALUES ('f2a3c406-0416-4e33-b5aa-7388187b7e9b', 'Marketing and Communications', 'Hospital marketing and public relations', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);


--
-- TOC entry 6161 (class 0 OID 53082)
-- Dependencies: 237
-- Data for Name: designations; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.designations VALUES ('c972b69e-125a-403e-9658-4b11bfeaf966', 'Emergency Physician', 'Physician specializing in emergency medicine', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('1bda7019-d49e-4faa-ba43-08c3f1df779b', 'Emergency Nurse', 'Nurse specializing in emergency care', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('491fc91e-c243-494a-87e4-5141debc6726', 'Paramedic', 'Emergency medical services provider', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('a94bd811-f2c3-4477-9d81-a4078c2ca1fd', 'ER Technician', 'Emergency room technician', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('9c4ceea1-e98d-4ff8-bbb9-214746578645', 'Triage Nurse', 'Nurse responsible for patient assessment and prioritization', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('11383de0-9f62-4ad5-8098-746fe800bb5b', 'Emergency Medical Director', 'Director of emergency medical services', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('16ac60a7-c17e-4b0c-8174-399adf0821e3', 'Trauma Surgeon', 'Surgeon specializing in trauma care', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('7dfd4129-1b2b-481c-80ad-798d2beaf8e4', 'Emergency Department Manager', 'Manager of emergency department operations', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('baf47104-8ffe-4cb8-8cdb-3d034379ff28', 'ICU Physician', 'Physician specializing in critical care', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('2d2457f9-8068-48d1-92ff-fa5768f46ebf', 'Critical Care Nurse', 'Nurse specializing in intensive care', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('78f6e82b-2965-44a9-a50d-66be74771a0a', 'Respiratory Therapist', 'Therapist specializing in respiratory care', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('2281dcdd-5f27-4cd9-9d32-46530dabda6b', 'ICU Manager', 'Manager of intensive care unit', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('ee918036-ad43-4472-b148-b8c696086ce1', 'Critical Care Specialist', 'Specialist in critical care medicine', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('993f3c06-e2f1-48f0-b53b-e1050e81a7ab', 'ICU Technician', 'Technician supporting ICU operations', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('cc859923-22ae-43f7-beb4-d8f5bdd49ebc', 'Pulmonologist', 'Physician specializing in lung diseases', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('22047dea-725d-4e34-8d68-7a30d58dd7db', 'Intensivist', 'Physician specializing in intensive care', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('50c88390-a56e-4449-9a9c-8110dd4ea0ea', 'Surgeon', 'Physician who performs surgical procedures', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('4e5f92e4-fc21-4b75-902a-d4466dcac180', 'Anesthesiologist', 'Physician specializing in anesthesia', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('fed4c1ff-1847-4cd2-ba43-f5de51400b66', 'OR Nurse', 'Nurse assisting in surgical procedures', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('6dd62f17-1fc4-4a33-b78c-b59620f6617a', 'Surgical Technician', 'Technician assisting surgeons', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('c4192d8e-8b3f-4714-9c01-58951f13f007', 'OR Manager', 'Manager of operating room operations', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('f3571f02-ea79-4299-9a44-744893c2282e', 'Perioperative Nurse', 'Nurse specializing in perioperative care', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('a6e81002-255a-44c7-b2f8-725dccb0a60a', 'Surgical Assistant', 'Assistant to surgical team', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('d23197b1-8e63-41e1-80f7-beab8e0dee2a', 'Circulating Nurse', 'Nurse managing operating room flow', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('0a199eaf-567a-4ad4-b2cf-39da1279bccc', 'Staff Nurse', 'Registered nurse providing general patient care', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('841c74fc-c60e-4801-b17f-3a8c8974f0dc', 'Charge Nurse', 'Nurse responsible for unit management', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('470ade43-9e0c-4a6a-a36a-d169b0adad1b', 'Medical-Surgical Nurse', 'Nurse specializing in medical-surgical care', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('7a7e44a8-b540-4964-8bf4-43fa4b662d47', 'Unit Manager', 'Manager of medical-surgical unit', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('39f49ff0-a054-40b4-b95f-f4d89178888d', 'Patient Care Technician', 'Technician assisting with patient care', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('9f904a20-9c18-4d3d-ad6a-ba1492d4c08d', 'Medication Nurse', 'Nurse responsible for medication administration', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('8c24de82-183d-4d5e-b5fe-5f1eb3d5c848', 'Wound Care Nurse', 'Nurse specializing in wound management', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('b984c582-064a-48d2-a87c-fbd6b206c188', 'Case Manager', 'Professional managing patient care coordination', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('fc156203-535e-4d1b-808c-474b1e074ffc', 'OB/GYN Physician', 'Physician specializing in women''s health', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('4c3f78ef-340f-43fc-a1de-ab77a795dfcb', 'Labor and Delivery Nurse', 'Nurse specializing in childbirth care', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('62dda02e-d495-4c85-b297-1eaa3e6ad400', 'Midwife', 'Healthcare professional specializing in childbirth', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('57d4d4d1-e2d3-4312-8915-52f23c06c35c', 'Neonatal Nurse', 'Nurse specializing in newborn care', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('a3cd00f2-a7ce-4d68-8c3e-56ca7f05164b', 'OB Technician', 'Technician assisting in obstetric procedures', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('43b0895c-22d9-49cf-9def-1ae9281d1160', 'Lactation Consultant', 'Specialist in breastfeeding support', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('41232ac8-762c-4af6-9631-9a3cfca9c9a8', 'Gynecological Nurse', 'Nurse specializing in gynecological care', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('3b7f2655-0037-442c-b1c7-c09ba022fcc7', 'Women''s Health Nurse Practitioner', 'Nurse practitioner specializing in women''s health', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('48c83b58-9a0b-4937-bc81-cbcc6192cc5e', 'Pediatrician', 'Physician specializing in child healthcare', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('e853b387-99bf-4788-943b-654210c36afb', 'Pediatric Nurse', 'Nurse specializing in pediatric care', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('e2302de4-f609-4052-bdf8-dcba9f3a8f84', 'Child Life Specialist', 'Specialist supporting children in healthcare', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('5a463cc0-0da7-415c-b812-8816d0e6674f', 'Pediatric Nurse Practitioner', 'Nurse practitioner specializing in pediatrics', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('a77ac9ea-465c-490e-9362-d2ab65da22c0', 'Pediatric Resident', 'Physician in pediatric training', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('12b62337-1ac6-4adc-bde5-f7167509e8f3', 'Pediatric Medical Assistant', 'Medical assistant specializing in pediatrics', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('b660d10b-1a78-4fc3-93fd-90d2cb040b86', 'Developmental Pediatrician', 'Physician specializing in child development', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('9df814b6-c7e7-4924-b9d6-c59aa90f13d4', 'Pediatric Surgeon', 'Surgeon specializing in pediatric surgery', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('a5a4b857-6b9a-47b5-b1cd-8289bea77563', 'Radiologist', 'Physician specializing in medical imaging', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('2b57f7b1-2f8a-4be9-83b4-5e4d63096163', 'Radiology Technician', 'Technician operating medical imaging equipment', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('86500c97-f4b6-47f0-adc4-e19b854985fc', 'X-Ray Technician', 'Technician operating X-ray equipment', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('cdb557c1-4acb-48ea-ab7a-5568672113ad', 'MRI Technician', 'Technician operating MRI equipment', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('958ed11c-fef3-4cac-940d-761788d34071', 'CT Technician', 'Technician operating CT scanner', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('762047ae-0aea-405f-82f2-f52b33f5d6ef', 'Ultrasound Technician', 'Technician operating ultrasound equipment', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('dbced688-7945-4081-99be-ce73a240d719', 'Interventional Radiologist', 'Radiologist performing interventional procedures', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('ae337b22-cbf9-4a70-a876-f0e1855af8c9', 'Radiology Manager', 'Manager of radiology department', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('94cc6364-b173-447d-b519-1739d7afd729', 'Medical Laboratory Scientist', 'Professional performing laboratory tests', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('fc0fd1c1-450e-4572-9c0c-9020a98db030', 'Lab Technician', 'Technician assisting in laboratory operations', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('4b455a51-e0f3-4d0b-a634-48b53fa8ce28', 'Phlebotomist', 'Professional who draws blood for testing', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('8bfedf9d-1b68-4536-ae9b-c841729e6fbb', 'Lab Manager', 'Manager of laboratory operations', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('f611fb32-91d3-44d5-81b9-368ea7952976', 'Clinical Pathologist', 'Physician specializing in laboratory medicine', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('b7f9484d-8673-49d6-a759-d0f1f8ec5706', 'Medical Technologist', 'Technologist performing complex lab tests', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('583d134e-3e1a-4323-8110-1a78dd4db263', 'Cytotechnologist', 'Technologist studying cells for disease', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('9d80cfdf-79a0-484f-9022-8a727f10ba83', 'Histology Technician', 'Technician preparing tissue samples', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('2de1bfb4-ad35-48d5-b8c8-4b9e3617c51b', 'Pharmacist', 'Professional dispensing medications', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('9217f8c4-13c6-48ed-aa94-0b2addc37e8f', 'Pharmacy Technician', 'Technician assisting pharmacists', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('99ea63ff-59fc-46ce-bf90-ffe8390e215e', 'Clinical Pharmacist', 'Pharmacist working with clinical teams', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('ae6a06ff-6912-4b8f-bf35-e4859fe650f8', 'Pharmacy Manager', 'Manager of pharmacy operations', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('7ccdb8ab-dac0-4208-a6f3-cea3e6d75435', 'Compounding Pharmacist', 'Pharmacist preparing customized medications', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('f88d2149-5281-42d7-81ca-2ee2f0a8bed8', 'Oncology Pharmacist', 'Pharmacist specializing in cancer medications', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('e484ab15-90ff-4dc5-a10c-56eb89eb91b2', 'Pharmacy Buyer', 'Professional purchasing medications', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('dc3ed1d4-f8ee-4842-9d22-18471b402199', 'Informatics Pharmacist', 'Pharmacist specializing in pharmacy informatics', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('50f690bd-a603-4578-b346-0f92d489ed5a', 'Physical Therapist', 'Therapist providing rehabilitation services', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('7821971b-9345-4947-9086-68fda9a7e859', 'Physical Therapy Assistant', 'Assistant to physical therapist', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('c180af1a-f8c9-4a07-b4a5-fccba9e6911c', 'Rehabilitation Manager', 'Manager of rehabilitation services', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('deaa3dff-c304-4717-96a6-badd7170c518', 'Sports Medicine Specialist', 'Specialist in sports-related injuries', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('6df705e2-b18f-40c9-b46c-4444c30e6ce6', 'Occupational Therapist', 'Therapist helping with daily living skills', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('ab864b52-72a4-4dfc-bd23-4d5909afc0eb', 'Therapy Technician', 'Technician assisting therapists', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('f5ce8a2a-796d-4113-9d9d-dcfaf2cccb82', 'Rehabilitation Aide', 'Aide assisting in rehabilitation', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('6d92e83c-5d4d-448a-a045-5e9672884fc6', 'Hand Therapist', 'Therapist specializing in hand rehabilitation', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('6ed54ed3-6ec3-43f4-a9d5-a3a9bc82311b', 'Hospital Administrator', 'Senior hospital management position', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('c32e50e6-48ed-4a7a-930f-456fb2805a4d', 'Chief Executive Officer', 'CEO of the hospital', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('71d82498-8d83-42af-b1c9-61acbfe3ba11', 'Chief Operating Officer', 'COO of the hospital', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('e6dbcabf-bd93-4364-8b90-b5a2f4fde0cf', 'Administrative Director', 'Director of administrative services', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('21cbb342-a039-47f4-8a1b-1ee2d8b7f585', 'Department Head', 'Head of a specific department', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('337116e5-d293-4f91-bb78-545946f236a1', 'Administrative Assistant', 'Assistant providing administrative support', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('a36b6c6d-1aa0-4e6a-9cc8-a66ec08e7a4b', 'Executive Assistant', 'Assistant to senior executives', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('84107c40-e043-43ab-82e9-8fda09720889', 'Hospital Manager', 'Manager of hospital operations', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('e56b899b-3c17-4333-b931-7b14107052aa', 'Chief Financial Officer', 'CFO of the hospital', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('3a8e15bc-5dc8-49ff-b20d-f5f75484456c', 'Accountant', 'Professional managing financial records', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('08b4c831-30e5-4801-adca-2e6a6b472368', 'Financial Analyst', 'Professional analyzing financial data', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('d30b3f72-25e0-462e-972a-d7cff9fc9e14', 'Billing Specialist', 'Specialist handling medical billing', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('db5d55ea-8285-48ce-8958-7be410f16792', 'Revenue Cycle Manager', 'Manager of revenue cycle operations', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('ec069b65-98c4-46ce-9482-dbe70485e3ef', 'Accounts Payable Clerk', 'Clerk managing accounts payable', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('438f23fc-d765-44ac-b2f2-0fd299dd2a60', 'Payroll Manager', 'Manager of payroll operations', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('d49766d8-021b-4478-99fc-e46a252c510c', 'Financial Controller', 'Controller of financial operations', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('fa6da6c4-9843-4bd1-a2a6-fc3e44917404', 'HR Director', 'Director of human resources', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('96af833e-a052-4838-b36d-e1309ac06042', 'HR Manager', 'Manager of human resources department', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('8ef325e6-f7d1-4a97-a898-b4a787486ead', 'HR Generalist', 'Generalist providing HR support', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('e10503c2-5f60-4a3c-a0d4-6c069df29a1e', 'Recruiter', 'Professional responsible for hiring', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('59feed0a-2b2d-4c67-b149-0c348e6ff42d', 'Training Coordinator', 'Coordinator of employee training', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('2beef42b-c29e-4c6b-a056-6cc8994dcd53', 'Compensation Analyst', 'Analyst managing compensation programs', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('f4aaf9aa-83c1-4a50-81b8-2c2ea564fec3', 'Employee Relations Specialist', 'Specialist handling employee relations', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('b51588f6-94d1-471e-b451-7431d129d71b', 'HR Assistant', 'Assistant providing HR support', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('bedcc3c5-361c-41d9-b29b-fce92e6aac85', 'IT Director', 'Director of information technology', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('c9662e1d-8ab8-4e2e-8a7d-1f3d9485578a', 'System Administrator', 'Professional managing IT systems', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('afb91e8b-cae9-4491-899f-8cde3951ca62', 'Network Administrator', 'Professional managing network infrastructure', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('47931197-105c-4ebc-926a-a4d68e68dc73', 'Database Administrator', 'Professional managing databases', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('74a7d7f6-17a9-4b06-a5fb-b10818347b4d', 'IT Support Specialist', 'Professional providing IT support', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('2ee12051-d35d-4c01-bbb7-7eaf88687774', 'Software Developer', 'Developer creating software solutions', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('e4e25767-c253-40e5-8781-ac1219f14906', 'Security Analyst', 'Analyst managing IT security', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('7b4d6aef-2d35-4415-a82a-ba730eb81661', 'IT Project Manager', 'Manager of IT projects', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('36424165-6afb-4603-a237-379fa7e85209', 'Marketing Director', 'Director of marketing activities', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('90c8978c-beb4-442e-9f67-143406422b6b', 'Communications Manager', 'Manager of communications activities', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('9dec9c95-934f-4de3-be41-62644947829a', 'Public Relations Specialist', 'Specialist handling public relations', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('aa382bc0-bfa7-482d-a6f6-ad29ea8a5190', 'Marketing Coordinator', 'Coordinator of marketing activities', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('d7e53526-5dbd-4b3d-a51c-2ac5701b83d7', 'Content Creator', 'Creator of marketing content', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('d5ad0d11-7b54-4528-a649-db0844492ec6', 'Social Media Manager', 'Manager of social media presence', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('7247904e-64db-40ab-bb35-bfc84e9e19a9', 'Graphic Designer', 'Designer creating visual content', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('76469f20-a68f-441c-8002-41440b1d1d9b', 'Community Outreach Coordinator', 'Coordinator of community outreach', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
INSERT INTO public.designations VALUES ('13e409b4-ccaa-49e8-9fce-c05c67bd7ce6', 'IT Manager', NULL, 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 15:59:20.660278+02', '2026-02-17 15:59:20.660278+02', NULL, NULL);


--
-- TOC entry 6157 (class 0 OID 52883)
-- Dependencies: 233
-- Data for Name: employee_files; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6152 (class 0 OID 52708)
-- Dependencies: 228
-- Data for Name: leave_balances; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6162 (class 0 OID 53117)
-- Dependencies: 238
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6159 (class 0 OID 52928)
-- Dependencies: 235
-- Data for Name: pending_registrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6156 (class 0 OID 52847)
-- Dependencies: 232
-- Data for Name: request_approvals; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6155 (class 0 OID 52811)
-- Dependencies: 231
-- Data for Name: requests; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6150 (class 0 OID 52623)
-- Dependencies: 226
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.roles VALUES ('970f339b-6bb2-4851-a9fc-1b2b89a67b21', 'System Admin', '2026-02-15 12:17:51.57479+02', '2026-02-15 12:17:51.57479+02', NULL, NULL);
INSERT INTO public.roles VALUES ('454a835f-9574-4505-8d14-b89669070fe0', 'HR Admin', '2026-02-17 13:25:49.32529+02', '2026-02-17 13:25:49.32529+02', NULL, NULL);
INSERT INTO public.roles VALUES ('6156a9f6-3140-4478-ac3f-7e69da317a53', 'Head of Department', '2026-02-17 14:03:15.453374+02', '2026-02-17 14:03:15.453374+02', NULL, NULL);
INSERT INTO public.roles VALUES ('163e52d9-6e62-433e-87b6-be851acd4bdb', 'HR', '2026-02-17 14:03:15.453374+02', '2026-02-17 14:03:15.453374+02', NULL, NULL);
INSERT INTO public.roles VALUES ('634bbbf2-4e99-4f48-adb3-f8880809826b', 'Accountant', '2026-02-17 14:03:15.454493+02', '2026-02-17 14:03:15.454493+02', NULL, NULL);
INSERT INTO public.roles VALUES ('92e74f72-6245-49c0-9c18-6d1e8e54df18', 'Principal Hospital Administrator', '2026-02-17 14:03:15.455+02', '2026-02-17 14:03:15.455+02', NULL, NULL);
INSERT INTO public.roles VALUES ('536128db-f948-4f3a-bcdb-46b0438d7af7', 'System Administrator', '2026-02-17 14:03:15.455+02', '2026-02-17 14:03:15.455+02', NULL, NULL);
INSERT INTO public.roles VALUES ('585f3343-9234-47ff-8c6c-021a7b3ca84f', 'Staff', '2026-02-17 14:03:15.455+02', '2026-02-17 14:03:15.455+02', NULL, NULL);


--
-- TOC entry 5831 (class 0 OID 51860)
-- Dependencies: 222
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- TOC entry 6151 (class 0 OID 52655)
-- Dependencies: 227
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users VALUES ('b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'EMP2', 'NAT2', 'Maxwell', 'Chisale', 'Yankho', 'MR', '2001-02-04', 'male', 'Mitundu', 'Chiseka', 'Lilongwe', 'st johns', NULL, 'cis-011-21@must.ac.mw', 'single', '', '', '2025-02-02', 'b277017f-5f87-439b-8433-33707796c2b7', false, '0883271664', '$2b$12$8h83NsXhzmBUpB3ktyYrLuV7KMx5sW1DZ8n/qTES7deWf8oyuBE16', '585f3343-9234-47ff-8c6c-021a7b3ca84f', 'pending', NULL, NULL, NULL, '2026-02-19 08:27:53.217735+02', false, '2026-02-19 08:28:13.218345+02', '2026-02-19 08:27:53.217735+02', '2026-02-19 10:28:12.8841+02', NULL, NULL, '13e409b4-ccaa-49e8-9fce-c05c67bd7ce6');
INSERT INTO public.users VALUES ('ae7fafd7-72ed-428e-9ef3-debc44e02d47', 'Emp1', 'NATIONAL1', 'Yankho', 'Chisale', 'Maxwell', 'Mr', '2001-02-23', 'male', 'Mitundu', 'Chiseka', 'Lilongwe', 'St johns', NULL, 'yankhochisale4@gmail.com', 'single', '', '', '2025-02-01', NULL, false, '0997823454', '$2b$12$ezXx85RHfj/JwHd29YoOuuC52Pdk57bRcyFpGBUNREKHoP/dUXPqa', '970f339b-6bb2-4851-a9fc-1b2b89a67b21', 'pending', NULL, NULL, NULL, '2026-02-17 15:59:21.048198+02', false, '2026-02-19 11:07:38.382094+02', '2026-02-17 15:59:21.048198+02', '2026-02-19 13:07:37.349807+02', NULL, NULL, '13e409b4-ccaa-49e8-9fce-c05c67bd7ce6');


--
-- TOC entry 6154 (class 0 OID 52772)
-- Dependencies: 230
-- Data for Name: work_reports; Type: TABLE DATA; Schema: public; Owner: postgres
--




-- Create constraints (Primary Keys)
ALTER TABLE ONLY public.attendance_logs ADD CONSTRAINT attendance_logs_pkey PRIMARY KEY (attendance_log_id);
ALTER TABLE ONLY public.audit_logs ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (audit_log_id);
ALTER TABLE ONLY public.departments ADD CONSTRAINT departments_name_key UNIQUE (name);
ALTER TABLE ONLY public.departments ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id);
ALTER TABLE ONLY public.designations ADD CONSTRAINT designations_department_id_name_key UNIQUE (department_id, name);
ALTER TABLE ONLY public.designations ADD CONSTRAINT designations_pkey PRIMARY KEY (designation_id);
ALTER TABLE ONLY public.employee_files ADD CONSTRAINT employee_files_pkey PRIMARY KEY (employee_file_id);
ALTER TABLE ONLY public.leave_balances ADD CONSTRAINT leave_balances_pkey PRIMARY KEY (leave_balance_id);
ALTER TABLE ONLY public.notifications ADD CONSTRAINT notifications_pkey PRIMARY KEY (notification_id);
ALTER TABLE ONLY public.pending_registrations ADD CONSTRAINT pending_registrations_employee_number_key UNIQUE (employee_number);
ALTER TABLE ONLY public.pending_registrations ADD CONSTRAINT pending_registrations_pkey PRIMARY KEY (pending_registration_id);
ALTER TABLE ONLY public.request_approvals ADD CONSTRAINT request_approvals_pkey PRIMARY KEY (request_approval_id);
ALTER TABLE ONLY public.requests ADD CONSTRAINT requests_pkey PRIMARY KEY (request_id);
ALTER TABLE ONLY public.roles ADD CONSTRAINT roles_name_key UNIQUE (name);
ALTER TABLE ONLY public.roles ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);
ALTER TABLE ONLY public.users ADD CONSTRAINT users_contact_number_key UNIQUE (contact_number);
ALTER TABLE ONLY public.users ADD CONSTRAINT users_email_key UNIQUE (email);
ALTER TABLE ONLY public.users ADD CONSTRAINT users_employee_number_key UNIQUE (employee_number);
ALTER TABLE ONLY public.users ADD CONSTRAINT users_national_id_key UNIQUE (national_id);
ALTER TABLE ONLY public.users ADD CONSTRAINT users_phone_key UNIQUE (phone);
ALTER TABLE ONLY public.users ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);
ALTER TABLE ONLY public.work_reports ADD CONSTRAINT work_reports_pkey PRIMARY KEY (work_report_id);

-- Create indexes
CREATE INDEX idx_attendance_location_gist ON public.attendance_logs USING gist (location);
CREATE INDEX idx_audit_actor_time ON public.audit_logs USING btree (actor_id, occurred_at);
CREATE INDEX idx_audit_entity ON public.audit_logs USING btree (entity_type, entity_id);
CREATE INDEX idx_departments_name ON public.departments USING btree (name);
CREATE INDEX idx_designations_department_id ON public.designations USING btree (department_id);
CREATE INDEX idx_designations_name ON public.designations USING btree (name);
CREATE INDEX idx_requests_pending_approver ON public.requests USING btree (current_approver_id) WHERE ((status = 'pending'::public.request_status_enum) AND (deleted_at IS NULL));

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
CREATE TRIGGER trg_requests_soft_delete_audit BEFORE UPDATE ON public.requests FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();
CREATE TRIGGER trg_requests_update_timestamp BEFORE UPDATE ON public.requests FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE TRIGGER trg_roles_soft_delete_audit BEFORE UPDATE ON public.roles FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();
CREATE TRIGGER trg_roles_update_timestamp BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE TRIGGER trg_users_soft_delete_audit BEFORE UPDATE ON public.users FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();
CREATE TRIGGER trg_users_update_timestamp BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
CREATE TRIGGER trg_work_reports_soft_delete_audit BEFORE UPDATE ON public.work_reports FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();
CREATE TRIGGER trg_work_reports_update_timestamp BEFORE UPDATE ON public.work_reports FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();

-- Create foreign key constraints
ALTER TABLE public.attendance_logs ADD CONSTRAINT attendance_logs_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;
ALTER TABLE public.attendance_logs ADD CONSTRAINT attendance_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
ALTER TABLE public.audit_logs ADD CONSTRAINT audit_logs_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.users(user_id) ON DELETE SET NULL;
ALTER TABLE public.departments ADD CONSTRAINT departments_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id);
ALTER TABLE public.designations ADD CONSTRAINT designations_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id);
ALTER TABLE public.designations ADD CONSTRAINT designations_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(department_id) ON DELETE CASCADE;
ALTER TABLE public.employee_files ADD CONSTRAINT employee_files_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;
ALTER TABLE public.employee_files ADD CONSTRAINT employee_files_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
ALTER TABLE public.roles ADD CONSTRAINT fk_roles_deleted_by FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;
ALTER TABLE public.leave_balances ADD CONSTRAINT leave_balances_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;
ALTER TABLE public.leave_balances ADD CONSTRAINT leave_balances_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id);
ALTER TABLE public.notifications ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);
ALTER TABLE public.pending_registrations ADD CONSTRAINT pending_registrations_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;
ALTER TABLE public.request_approvals ADD CONSTRAINT request_approvals_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(user_id) ON DELETE RESTRICT;
ALTER TABLE public.request_approvals ADD CONSTRAINT request_approvals_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;
ALTER TABLE public.request_approvals ADD CONSTRAINT request_approvals_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.requests(request_id) ON DELETE CASCADE;
ALTER TABLE public.requests ADD CONSTRAINT requests_current_approver_id_fkey FOREIGN KEY (current_approver_id) REFERENCES public.users(user_id) ON DELETE SET NULL;
ALTER TABLE public.requests ADD CONSTRAINT requests_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;
ALTER TABLE public.requests ADD CONSTRAINT requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
ALTER TABLE public.users ADD CONSTRAINT users_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;
ALTER TABLE public.users ADD CONSTRAINT users_designation_id_fkey FOREIGN KEY (designation_id) REFERENCES public.designations(designation_id);
ALTER TABLE public.users ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON DELETE RESTRICT;
ALTER TABLE public.work_reports ADD CONSTRAINT work_reports_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(user_id) ON DELETE SET NULL;
ALTER TABLE public.work_reports ADD CONSTRAINT work_reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;

-- PostgreSQL database dump complete
