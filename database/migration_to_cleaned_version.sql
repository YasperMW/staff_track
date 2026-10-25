-- Migration script to update existing database to cleaned version
-- This script adds missing tables, columns, and data without dropping existing database

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

-- Create extensions if they don't exist
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Create enums if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'request_status_enum') THEN
        CREATE TYPE public.request_status_enum AS ENUM (
            'pending',
            'approved',
            'denied',
            'cancelled',
            'withdrawn'
        );
    END IF;
END $$;

-- Create functions if they don't exist
CREATE OR REPLACE FUNCTION public.soft_delete_audit() RETURNS trigger
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

CREATE OR REPLACE FUNCTION public.update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Create missing tables
DO $$
BEGIN
    -- Check and create announcement_departments table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'announcement_departments' AND table_schema = 'public') THEN
        CREATE TABLE public.announcement_departments (
            announcement_id uuid NOT NULL,
            department_id uuid NOT NULL,
            created_at timestamp with time zone NOT NULL
        );
    END IF;

    -- Check and create announcements table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'announcements' AND table_schema = 'public') THEN
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
    END IF;

    -- Check and create attendance_logs table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance_logs' AND table_schema = 'public') THEN
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
    ELSE
        -- Check if required columns exist, add them if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'attendance_log_id' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN attendance_log_id uuid DEFAULT public.uuid_generate_v4() NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'user_id' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN user_id uuid NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'check_in_time' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN check_in_time timestamp with time zone;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'check_out_time' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN check_out_time timestamp with time zone;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'location' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN location public.geography(Point,4326);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'accuracy' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN accuracy numeric(6,2);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'device_id' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN device_id character varying(100);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'offline_flag' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN offline_flag boolean DEFAULT false;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'sync_time' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN sync_time timestamp with time zone;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'created_at' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'updated_at' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'deleted_at' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN deleted_at timestamp with time zone;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'deleted_by' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN deleted_by uuid;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'shift_type' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN shift_type character varying(50) DEFAULT NULL::character varying;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'work_hours' AND table_schema = 'public') THEN
            ALTER TABLE public.attendance_logs ADD COLUMN work_hours numeric(5,2) DEFAULT NULL::numeric;
        END IF;
    END IF;

    -- Check and create audit_logs table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs' AND table_schema = 'public') THEN
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
    ELSE
        -- Check if audit_id column exists, if not add it
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_logs' AND column_name = 'audit_id' AND table_schema = 'public') THEN
            ALTER TABLE public.audit_logs ADD COLUMN audit_id uuid DEFAULT public.uuid_generate_v4() NOT NULL;
        END IF;
        
        -- Check if other required columns exist, add them if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_logs' AND column_name = 'actor_id' AND table_schema = 'public') THEN
            ALTER TABLE public.audit_logs ADD COLUMN actor_id uuid;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_logs' AND column_name = 'action' AND table_schema = 'public') THEN
            ALTER TABLE public.audit_logs ADD COLUMN action character varying(100) NOT NULL DEFAULT '';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_logs' AND column_name = 'entity_type' AND table_schema = 'public') THEN
            ALTER TABLE public.audit_logs ADD COLUMN entity_type character varying(50);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_logs' AND column_name = 'entity_id' AND table_schema = 'public') THEN
            ALTER TABLE public.audit_logs ADD COLUMN entity_id uuid;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_logs' AND column_name = 'old_value' AND table_schema = 'public') THEN
            ALTER TABLE public.audit_logs ADD COLUMN old_value jsonb;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_logs' AND column_name = 'new_value' AND table_schema = 'public') THEN
            ALTER TABLE public.audit_logs ADD COLUMN new_value jsonb;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_logs' AND column_name = 'ip_address' AND table_schema = 'public') THEN
            ALTER TABLE public.audit_logs ADD COLUMN ip_address inet;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_logs' AND column_name = 'user_agent' AND table_schema = 'public') THEN
            ALTER TABLE public.audit_logs ADD COLUMN user_agent text;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_logs' AND column_name = 'occurred_at' AND table_schema = 'public') THEN
            ALTER TABLE public.audit_logs ADD COLUMN occurred_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_logs' AND column_name = 'entity' AND table_schema = 'public') THEN
            ALTER TABLE public.audit_logs ADD COLUMN entity character varying(100);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_logs' AND column_name = 'details' AND table_schema = 'public') THEN
            ALTER TABLE public.audit_logs ADD COLUMN details jsonb;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'audit_logs' AND column_name = 'timestamp' AND table_schema = 'public') THEN
            ALTER TABLE public.audit_logs ADD COLUMN "timestamp" timestamp with time zone;
        END IF;
    END IF;

    -- Check and create departments table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'departments' AND table_schema = 'public') THEN
        CREATE TABLE public.departments (
            department_id uuid DEFAULT gen_random_uuid() NOT NULL,
            name character varying(150) NOT NULL,
            description text,
            created_at timestamp with time zone DEFAULT now() NOT NULL,
            updated_at timestamp with time zone DEFAULT now() NOT NULL,
            deleted_at timestamp with time zone,
            deleted_by uuid
        );
    END IF;

    -- Check and create designations table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'designations' AND table_schema = 'public') THEN
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
    END IF;

    -- Check and create email_verifications table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'email_verifications' AND table_schema = 'public') THEN
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
    END IF;

    -- Check and create employee_files table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'employee_files' AND table_schema = 'public') THEN
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
    END IF;

    -- Check and create grades table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'grades' AND table_schema = 'public') THEN
        CREATE TABLE public.grades (
            grade_id uuid NOT NULL,
            name character varying(50) NOT NULL,
            annual_leave_days integer NOT NULL,
            created_at timestamp with time zone NOT NULL,
            updated_at timestamp with time zone NOT NULL,
            deleted_at timestamp with time zone,
            deleted_by uuid
        );
    END IF;

    -- Check and create holidays table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'holidays' AND table_schema = 'public') THEN
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
    END IF;

    -- Check and create leave_balances table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'leave_balances' AND table_schema = 'public') THEN
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
    END IF;

    -- Check and create notification_preferences table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notification_preferences' AND table_schema = 'public') THEN
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
    END IF;

    -- Check and create notifications table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications' AND table_schema = 'public') THEN
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
    END IF;

    -- Check and create pending_registrations table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pending_registrations' AND table_schema = 'public') THEN
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
    END IF;

    -- Check and create request_approvals table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'request_approvals' AND table_schema = 'public') THEN
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
    END IF;

    -- Check and create requests table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'requests' AND table_schema = 'public') THEN
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
    END IF;

    -- Check and create roles table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'roles' AND table_schema = 'public') THEN
        CREATE TABLE public.roles (
            role_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
            name character varying(100) NOT NULL,
            created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
            updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
            deleted_at timestamp with time zone,
            deleted_by uuid,
            CONSTRAINT chk_role_name_not_empty CHECK ((TRIM(BOTH FROM name) <> ''::text))
        );
    END IF;

    -- Check and create user_fcm_tokens table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_fcm_tokens' AND table_schema = 'public') THEN
        CREATE TABLE public.user_fcm_tokens (
            token_id uuid NOT NULL,
            user_id uuid NOT NULL,
            fcm_token text NOT NULL,
            device_id character varying(100),
            created_at timestamp with time zone NOT NULL,
            updated_at timestamp with time zone NOT NULL
        );
    END IF;

    -- Check and create users table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
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
    ELSE
        -- Check if missing columns exist and add them
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'designation_id' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN designation_id uuid;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'grade_id' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN grade_id uuid;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'user_id' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN user_id uuid DEFAULT public.uuid_generate_v4() NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'employee_number' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN employee_number character varying(50) NOT NULL DEFAULT '';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'national_id' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN national_id character varying(50);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'first_name' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN first_name character varying(100) NOT NULL DEFAULT '';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'surname' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN surname character varying(100) NOT NULL DEFAULT '';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'other_names' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN other_names character varying(150);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'suffix' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN suffix character varying(20);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'date_of_birth' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN date_of_birth date;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'gender' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN gender character varying(10);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'home_of_origin' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN home_of_origin character varying(150);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'traditional_authority' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN traditional_authority character varying(100);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'district' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN district character varying(100);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'current_address' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN current_address text;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'contact_number' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN contact_number character varying(30);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'email' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN email character varying(255);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'marital_status' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN marital_status character varying(20);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'spouse_name' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN spouse_name character varying(150);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'spouse_contact' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN spouse_contact character varying(30);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'date_of_employment' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN date_of_employment date;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'department_id' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN department_id uuid;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'is_head_of_department' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN is_head_of_department boolean DEFAULT false;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'phone' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN phone character varying(30);
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'password_hash' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN password_hash text NOT NULL DEFAULT '';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'role_id' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN role_id uuid NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'status' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN status character varying(30) DEFAULT 'pending'::character varying NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'profile_photo_url' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN profile_photo_url text;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'blacklisted_at' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN blacklisted_at timestamp with time zone;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'blacklisted_reason' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN blacklisted_reason text;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'registration_timestamp' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN registration_timestamp timestamp with time zone DEFAULT CURRENT_TIMESTAMP;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'selfie_verified' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN selfie_verified boolean DEFAULT false;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'last_login_at' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN last_login_at timestamp with time zone;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'created_at' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'updated_at' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'deleted_at' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN deleted_at timestamp with time zone;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'deleted_by' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN deleted_by uuid;
        END IF;
    END IF;

    -- Check and create work_reports table
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'work_reports' AND table_schema = 'public') THEN
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
    END IF;
END $$;

-- Add missing columns to existing tables
DO $$
BEGIN
    -- Add missing columns to users table if they don't exist
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'designation_id' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN designation_id uuid;
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'grade_id' AND table_schema = 'public') THEN
            ALTER TABLE public.users ADD COLUMN grade_id uuid;
        END IF;
    END IF;
END $$;


-- Create indexes if they don't exist
DO $$
BEGIN
    -- Create indexes for attendance_logs
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance_logs' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'attendance_logs' AND indexname = 'idx_attendance_logs_user_id') THEN
            CREATE INDEX idx_attendance_logs_user_id ON public.attendance_logs(user_id);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'attendance_logs' AND indexname = 'idx_attendance_logs_check_in_time') THEN
            CREATE INDEX idx_attendance_logs_check_in_time ON public.attendance_logs(check_in_time);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'attendance_logs' AND indexname = 'idx_attendance_location_gist') THEN
            CREATE INDEX idx_attendance_location_gist ON public.attendance_logs USING gist (location);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'attendance_logs' AND indexname = 'idx_attendance_shift_type') THEN
            CREATE INDEX idx_attendance_shift_type ON public.attendance_logs USING btree (shift_type);
        END IF;
    END IF;

    -- Create indexes for users table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'users' AND indexname = 'idx_users_employee_number') THEN
            CREATE INDEX idx_users_employee_number ON public.users(employee_number);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'users' AND indexname = 'idx_users_email') THEN
            CREATE INDEX idx_users_email ON public.users(email);
        END IF;
    END IF;

    -- Create indexes for audit_logs
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'audit_logs' AND indexname = 'idx_audit_logs_actor_id') THEN
            CREATE INDEX idx_audit_logs_actor_id ON public.audit_logs(actor_id);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'audit_logs' AND indexname = 'idx_audit_logs_occurred_at') THEN
            CREATE INDEX idx_audit_logs_occurred_at ON public.audit_logs(occurred_at);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'audit_logs' AND indexname = 'idx_audit_actor_time') THEN
            CREATE INDEX idx_audit_actor_time ON public.audit_logs USING btree (actor_id, occurred_at);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'audit_logs' AND indexname = 'idx_audit_entity') THEN
            CREATE INDEX idx_audit_entity ON public.audit_logs USING btree (entity_type, entity_id);
        END IF;
    END IF;

    -- Create indexes for departments
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'departments' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'departments' AND indexname = 'idx_departments_name') THEN
            CREATE INDEX idx_departments_name ON public.departments USING btree (name);
        END IF;
    END IF;

    -- Create indexes for designations
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'designations' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'designations' AND indexname = 'idx_designations_department_id') THEN
            CREATE INDEX idx_designations_department_id ON public.designations USING btree (department_id);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'designations' AND indexname = 'idx_designations_name') THEN
            CREATE INDEX idx_designations_name ON public.designations USING btree (name);
        END IF;
    END IF;

    -- Create indexes for holidays
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'holidays' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'holidays' AND indexname = 'idx_holidays_category') THEN
            CREATE INDEX idx_holidays_category ON public.holidays USING btree (category);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'holidays' AND indexname = 'idx_holidays_source') THEN
            CREATE INDEX idx_holidays_source ON public.holidays USING btree (source);
        END IF;
    END IF;

    -- Create indexes for requests
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'requests' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'requests' AND indexname = 'idx_requests_user_id') THEN
            CREATE INDEX idx_requests_user_id ON public.requests(user_id);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'requests' AND indexname = 'idx_requests_status') THEN
            CREATE INDEX idx_requests_status ON public.requests(status);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'requests' AND indexname = 'idx_requests_pending_approver') THEN
            CREATE INDEX idx_requests_pending_approver ON public.requests USING btree (current_approver_id) WHERE ((status = 'pending'::public.request_status_enum) AND (deleted_at IS NULL));
        END IF;
    END IF;

    -- Create indexes for email_verifications
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'email_verifications' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'email_verifications' AND indexname = 'ix_email_verifications_email') THEN
            CREATE INDEX ix_email_verifications_email ON public.email_verifications USING btree (email);
        END IF;
    END IF;
END $$;

-- Create primary keys and constraints if they don't exist
DO $$
BEGIN
    -- Add primary keys to tables
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'departments' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'departments' AND constraint_type = 'PRIMARY KEY') THEN
            ALTER TABLE public.departments ADD CONSTRAINT departments_pkey PRIMARY KEY (department_id);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'departments' AND constraint_name = 'departments_name_key') THEN
            ALTER TABLE public.departments ADD CONSTRAINT departments_name_key UNIQUE (name);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'roles' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'roles' AND constraint_type = 'PRIMARY KEY') THEN
            ALTER TABLE public.roles ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'roles' AND constraint_name = 'roles_name_key') THEN
            ALTER TABLE public.roles ADD CONSTRAINT roles_name_key UNIQUE (name);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'grades' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'grades' AND constraint_type = 'PRIMARY KEY') THEN
            ALTER TABLE public.grades ADD CONSTRAINT grades_pkey PRIMARY KEY (grade_id);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'grades' AND constraint_name = 'grades_name_key') THEN
            ALTER TABLE public.grades ADD CONSTRAINT grades_name_key UNIQUE (name);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'designations' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'designations' AND constraint_type = 'PRIMARY KEY') THEN
            ALTER TABLE public.designations ADD CONSTRAINT designations_pkey PRIMARY KEY (designation_id);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'designations' AND constraint_name = 'designations_department_id_name_key') THEN
            ALTER TABLE public.designations ADD CONSTRAINT designations_department_id_name_key UNIQUE (department_id, name);
        END IF;
    END IF;
END $$;

-- Create triggers if they don't exist
DO $$
BEGIN
    -- Create triggers for attendance_logs
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance_logs' AND table_schema = 'public') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_attendance_logs_soft_delete_audit') THEN
            CREATE TRIGGER trg_attendance_logs_soft_delete_audit BEFORE UPDATE ON public.attendance_logs FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION public.soft_delete_audit();
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_attendance_logs_update_timestamp') THEN
            CREATE TRIGGER trg_attendance_logs_update_timestamp BEFORE UPDATE ON public.attendance_logs FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
        END IF;
    END IF;
END $$;

-- Create foreign key constraints if they don't exist
DO $$
BEGIN
    -- Add foreign key for users.designation_id if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'designation_id' AND table_schema = 'public') THEN
            IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'users' AND constraint_name = 'users_designation_id_fkey') THEN
                ALTER TABLE ONLY public.users ADD CONSTRAINT users_designation_id_fkey FOREIGN KEY (designation_id) REFERENCES public.designations(designation_id);
            END IF;
        END IF;
        
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'grade_id' AND table_schema = 'public') THEN
            IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'users' AND constraint_name = 'users_grade_id_fkey') THEN
                ALTER TABLE ONLY public.users ADD CONSTRAINT users_grade_id_fkey FOREIGN KEY (grade_id) REFERENCES public.grades(grade_id);
            END IF;
        END IF;
    END IF;
END $$;

-- Add comments if they don't exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance_logs' AND table_schema = 'public') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'shift_type' AND table_schema = 'public') THEN
            IF NOT EXISTS (SELECT 1 FROM pg_description WHERE objoid = (SELECT oid FROM pg_class WHERE relname = 'attendance_logs') AND description IS NOT NULL AND objsubid = (SELECT attnum FROM pg_attribute WHERE attname = 'shift_type' AND attrelid = (SELECT oid FROM pg_class WHERE relname = 'attendance_logs'))) THEN
                COMMENT ON COLUMN public.attendance_logs.shift_type IS 'The shift type (Day Shift/Night Shift) based on check-in time';
            END IF;
        END IF;
        
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'attendance_logs' AND column_name = 'work_hours' AND table_schema = 'public') THEN
            IF NOT EXISTS (SELECT 1 FROM pg_description WHERE objoid = (SELECT oid FROM pg_class WHERE relname = 'attendance_logs') AND description IS NOT NULL AND objsubid = (SELECT attnum FROM pg_attribute WHERE attname = 'work_hours' AND attrelid = (SELECT oid FROM pg_class WHERE relname = 'attendance_logs'))) THEN
                COMMENT ON COLUMN public.attendance_logs.work_hours IS 'Pre-calculated work hours in decimal format';
            END IF;
        END IF;
    END IF;
END $$;

-- Migration complete
SELECT 'Migration completed successfully. Database has been updated to match the cleaned version.' as status;
