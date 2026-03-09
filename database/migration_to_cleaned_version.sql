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

-- Insert missing data only if tables are empty
DO $$
BEGIN
    -- Insert departments data if table is empty
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'departments' AND table_schema = 'public') THEN
        IF (SELECT COUNT(*) FROM public.departments) = 0 THEN
            INSERT INTO public.departments (department_id, name, description, created_at, updated_at, deleted_at, deleted_by) VALUES 
            ('8f2c6616-9702-4c17-b4fc-ef8737c96493', 'Emergency Department', 'Provides immediate medical care for acute illnesses and injuries', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', 'Intensive Care Unit (ICU)', 'Provides critical care for seriously ill patients', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('fdc59d81-4f99-456b-99ab-67549128563b', 'Operating Room (OR)', 'Surgical procedures and operations', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('8de34a57-a843-4f93-bb3c-b7293b0ee599', 'Medical-Surgical Unit', 'General medical and surgical patient care', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('31e5ee6f-f076-4106-9e4e-5fc45090fdf0', 'Obstetrics and Gynecology (OB/GYN)', 'Women''s health and childbirth services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('e9563043-70d4-4e5f-af94-ae4284cb79f0', 'Pediatrics', 'Medical care for infants, children, and adolescents', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('42298cff-98f2-4507-8dea-533d7829c667', 'Radiology', 'Medical imaging and diagnostic services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', 'Laboratory', 'Clinical laboratory testing and analysis', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('ccc19504-7d7c-4b52-b2b2-53b63d7660c4', 'Pharmacy', 'Medication dispensing and pharmaceutical care', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('373f5cca-4360-4d30-82e7-a6c16f99da00', 'Physical Therapy', 'Rehabilitation and physical therapy services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('69d1c38d-2d74-4299-817b-517abda58b0f', 'Administration', 'Hospital management and administrative services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('04ebbbce-d888-480d-a1a2-4599109e2d46', 'Finance', 'Financial management and accounting services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('c6615015-4728-473e-a14c-40686e9d597f', 'Human Resources', 'Employee management and HR services', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('b277017f-5f87-439b-8433-33707796c2b7', 'Information Technology (IT)', 'Technology infrastructure and IT support', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('f2a3c406-0416-4e33-b5aa-7388187b7e9b', 'Marketing and Communications', 'Hospital marketing and public relations', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL);
        END IF;
    END IF;

    -- Insert designations data if table is empty
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'designations' AND table_schema = 'public') THEN
        IF (SELECT COUNT(*) FROM public.designations) = 0 THEN
            INSERT INTO public.designations (designation_id, name, description, department_id, created_at, updated_at, deleted_at, deleted_by) VALUES 
            ('c972b69e-125a-403e-9658-4b11bfeaf966', 'Emergency Physician', 'Physician specializing in emergency medicine', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('1bda7019-d49e-4faa-ba43-08c3f1df779b', 'Emergency Nurse', 'Nurse specializing in emergency care', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('491fc91e-c243-494a-87e4-5141debc6726', 'Paramedic', 'Emergency medical services provider', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('a94bd811-f2c3-4477-9d81-a4078c2ca1fd', 'ER Technician', 'Emergency room technician', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('9c4ceea1-e98d-4ff8-bbb9-214746578645', 'Triage Nurse', 'Nurse responsible for patient assessment and prioritization', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('11383de0-9f62-4ad5-8098-746fe800bb5b', 'Emergency Medical Director', 'Director of emergency medical services', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('16ac60a7-c17e-4b0c-8174-399adf0821e3', 'Trauma Surgeon', 'Surgeon specializing in trauma care', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('7dfd4129-1b2b-481c-80ad-798d2beaf8e4', 'Emergency Department Manager', 'Manager of emergency department operations', '8f2c6616-9702-4c17-b4fc-ef8737c96493', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('baf47104-8ffe-4cb8-8cdb-3d034379ff28', 'ICU Physician', 'Physician specializing in critical care', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('2d2457f9-8068-48d1-92ff-fa5768f46ebf', 'Critical Care Nurse', 'Nurse specializing in intensive care', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('78f6e82b-2965-44a9-a50d-66be74771a0a', 'Respiratory Therapist', 'Therapist specializing in respiratory care', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('2281dcdd-5f27-4cd9-9d32-46530dabda6b', 'ICU Manager', 'Manager of intensive care unit', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('ee918036-ad43-4472-b148-b8c696086ce1', 'Critical Care Specialist', 'Specialist in critical care medicine', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('993f3c06-e2f1-48f0-b53b-e1050e81a7ab', 'ICU Technician', 'Technician supporting ICU operations', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('cc859923-22ae-43f7-beb4-d8f5bdd49ebc', 'Pulmonologist', 'Physician specializing in lung diseases', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('22047dea-725d-4e34-8d68-7a30d58dd7db', 'Intensivist', 'Physician specializing in intensive care', 'a293a1f8-e2e9-4e86-87fc-d6d9b4c702df', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('50c88390-a56e-4449-9a9c-8110dd4ea0ea', 'Surgeon', 'Physician who performs surgical procedures', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('4e5f92e4-fc21-4b75-902a-d4466dcac180', 'Anesthesiologist', 'Physician specializing in anesthesia', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('fed4c1ff-1847-4cd2-ba43-f5de51400b66', 'OR Nurse', 'Nurse assisting in surgical procedures', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('6dd62f17-1fc4-4a33-b78c-b59620f6617a', 'Surgical Technician', 'Technician assisting surgeons', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('c4192d8e-8b3f-4714-9c01-58951f13f007', 'OR Manager', 'Manager of operating room operations', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('f3571f02-ea79-4299-9a44-744893c2282e', 'Perioperative Nurse', 'Nurse specializing in perioperative care', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('a6e81002-255a-44c7-b2f8-725dccb0a60a', 'Surgical Assistant', 'Assistant to surgical team', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('d23197b1-8e63-41e1-80f7-beab8e0dee2a', 'Circulating Nurse', 'Nurse managing operating room flow', 'fdc59d81-4f99-456b-99ab-67549128563b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('0a199eaf-567a-4ad4-b2cf-39da1279bccc', 'Staff Nurse', 'Registered nurse providing general patient care', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('841c74fc-c60e-4801-b17f-3a8c8974f0dc', 'Charge Nurse', 'Nurse responsible for unit management', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('470ade43-9e0c-4a6a-a36a-d169b0adad1b', 'Medical-Surgical Nurse', 'Nurse specializing in medical-surgical care', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('7a7e44a8-b540-4964-8bf4-43fa4b662d47', 'Unit Manager', 'Manager of medical-surgical unit', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('39f49ff0-a054-40b4-b95f-f4d89178888d', 'Patient Care Technician', 'Technician assisting with patient care', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('9f904a20-9c18-4d3d-ad6a-ba1492d4c08d', 'Medication Nurse', 'Nurse responsible for medication administration', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('8c24de82-183d-4d5e-b5fe-5f1eb3d5c848', 'Wound Care Nurse', 'Nurse specializing in wound management', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('b984c582-064a-48d2-a87c-fbd6b206c188', 'Case Manager', 'Professional managing patient care coordination', '8de34a57-a843-4f93-bb3c-b7293b0ee599', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('fc156203-535e-4d1b-808c-474b1e074ffc', 'OB/GYN Physician', 'Physician specializing in women''s health', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('4c3f78ef-340f-43fc-a1de-ab77a795dfcb', 'Labor and Delivery Nurse', 'Nurse specializing in childbirth care', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('62dda02e-d495-4c85-b297-1eaa3e6ad400', 'Midwife', 'Healthcare professional specializing in childbirth', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('57d4d4d1-e2d3-4312-8915-52f23c06c35c', 'Neonatal Nurse', 'Nurse specializing in newborn care', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('a3cd00f2-a7ce-4d68-8c3e-56ca7f05164b', 'OB Technician', 'Technician assisting in obstetric procedures', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('43b0895c-22d9-49cf-9def-1ae9281d1160', 'Lactation Consultant', 'Specialist in breastfeeding support', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('41232ac8-762c-4af6-9631-9a3cfca9c9a8', 'Gynecological Nurse', 'Nurse specializing in gynecological care', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('3b7f2655-0037-442c-b1c7-c09ba022fcc7', 'Women''s Health Nurse Practitioner', 'Nurse practitioner specializing in women''s health', '31e5ee6f-f076-4106-9e4e-5fc45090fdf0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('48c83b58-9a0b-4937-bc81-cbcc6192cc5e', 'Pediatrician', 'Physician specializing in child healthcare', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('e853b387-99bf-4788-943b-654210c36afb', 'Pediatric Nurse', 'Nurse specializing in pediatric care', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('e2302de4-f609-4052-bdf8-dcba9f3a8f84', 'Child Life Specialist', 'Specialist supporting children in healthcare', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('5a463cc0-0da7-415c-b812-8816d0e6674f', 'Pediatric Nurse Practitioner', 'Nurse practitioner specializing in pediatrics', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('a77ac9ea-465c-490e-9362-d2ab65da22c0', 'Pediatric Resident', 'Physician in pediatric training', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('12b62337-1ac6-4adc-bde5-f7167509e8f3', 'Pediatric Medical Assistant', 'Medical assistant specializing in pediatrics', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('b660d10b-1a78-4fc3-93fd-90d2cb040b86', 'Developmental Pediatrician', 'Physician specializing in child development', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('9df814b6-c7e7-4924-b9d6-c59aa90f13d4', 'Pediatric Surgeon', 'Surgeon specializing in pediatric surgery', 'e9563043-70d4-4e5f-af94-ae4284cb79f0', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('a5a4b857-6b9a-47b5-b1cd-8289bea77563', 'Radiologist', 'Physician specializing in medical imaging', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('2b57f7b1-2f8a-4be9-83b4-5e4d63096163', 'Radiology Technician', 'Technician operating medical imaging equipment', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('86500c97-f4b6-47f0-adc4-e19b854985fc', 'X-Ray Technician', 'Technician operating X-ray equipment', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('cdb557c1-4acb-48ea-ab7a-5568672113ad', 'MRI Technician', 'Technician operating MRI equipment', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('958ed11c-fef3-4cac-940d-761788d34071', 'CT Technician', 'Technician operating CT scanner', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('762047ae-0aea-405f-82f2-f52b33f5d6ef', 'Ultrasound Technician', 'Technician operating ultrasound equipment', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('dbced688-7945-4081-99be-ce73a240d719', 'Interventional Radiologist', 'Radiologist performing interventional procedures', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('ae337b22-cbf9-4a70-a876-f0e1855af8c9', 'Radiology Manager', 'Manager of radiology department', '42298cff-98f2-4507-8dea-533d7829c667', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('94cc6364-b173-447d-b519-1739d7afd729', 'Medical Laboratory Scientist', 'Professional performing laboratory tests', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('fc0fd1c1-450e-4572-9c0c-9020a98db030', 'Lab Technician', 'Technician assisting in laboratory operations', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('4b455a51-e0f3-4d0b-a634-48b53fa8ce28', 'Phlebotomist', 'Professional who draws blood for testing', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('8bfedf9d-1b68-4536-ae9b-c841729e6fbb', 'Lab Manager', 'Manager of laboratory operations', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('f611fb32-91d3-44d5-81b9-368ea7952976', 'Clinical Pathologist', 'Physician specializing in laboratory medicine', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('b7f9484d-8673-49d6-a759-d0f1f8ec5706', 'Medical Technologist', 'Technologist performing complex lab tests', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('583d134e-3e1a-4323-8110-1a78dd4db263', 'Cytotechnologist', 'Technologist studying cells for disease', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('9d80cfdf-79a0-484f-9022-8a727f10ba83', 'Histology Technician', 'Technician preparing tissue samples', '7aa3ea8e-e3d3-4292-b23b-369c02b01ac3', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('2de1bfb4-ad35-48d5-b8c8-4b9e3617c51b', 'Pharmacist', 'Professional dispensing medications', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('9217f8c4-13c6-48ed-aa94-0b2addc37e8f', 'Pharmacy Technician', 'Technician assisting pharmacists', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('99ea63ff-59fc-46ce-bf90-ffe8390e215e', 'Clinical Pharmacist', 'Pharmacist working with clinical teams', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('ae6a06ff-6912-4b8f-bf35-e4859fe650f8', 'Pharmacy Manager', 'Manager of pharmacy operations', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('7ccdb8ab-dac0-4208-a6f3-cea3e6d75435', 'Compounding Pharmacist', 'Pharmacist preparing customized medications', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('f88d2149-5281-42d7-81ca-2ee2f0a8bed8', 'Oncology Pharmacist', 'Pharmacist specializing in cancer medications', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('e484ab15-90ff-4dc5-a10c-56eb89eb91b2', 'Pharmacy Buyer', 'Professional purchasing medications', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('dc3ed1d4-f8ee-4842-9d22-18471b402199', 'Informatics Pharmacist', 'Pharmacist specializing in pharmacy informatics', 'ccc19504-7d7c-4b52-b2b2-53b63d7660c4', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('50f690bd-a603-4578-b346-0f92d489ed5a', 'Physical Therapist', 'Therapist providing rehabilitation services', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('7821971b-9345-4947-9086-68fda9a7e859', 'Physical Therapy Assistant', 'Assistant to physical therapist', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('c180af1a-f8c9-4a07-b4a5-fccba9e6911c', 'Rehabilitation Manager', 'Manager of rehabilitation services', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('deaa3dff-c304-4717-96a6-badd7170c518', 'Sports Medicine Specialist', 'Specialist in sports-related injuries', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('6df705e2-b18f-40c9-b46c-4444c30e6ce6', 'Occupational Therapist', 'Therapist helping with daily living skills', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('ab864b52-72a4-4dfc-bd23-4d5909afc0eb', 'Therapy Technician', 'Technician assisting therapists', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('f5ce8a2a-796d-4113-9d9d-dcfaf2cccb82', 'Rehabilitation Aide', 'Aide assisting in rehabilitation', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('6d92e83c-5d4d-448a-a045-5e9672884fc6', 'Hand Therapist', 'Therapist specializing in hand rehabilitation', '373f5cca-4360-4d30-82e7-a6c16f99da00', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('6ed54ed3-6ec3-43f4-a9d5-a3a9bc82311b', 'Hospital Administrator', 'Senior hospital management position', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('c32e50e6-48ed-4a7a-930f-456fb2805a4d', 'Chief Executive Officer', 'CEO of the hospital', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('71d82498-8d83-42af-b1c9-61acbfe3ba11', 'Chief Operating Officer', 'COO of the hospital', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('e6dbcabf-bd93-4364-8b90-b5a2f4fde0cf', 'Administrative Director', 'Director of administrative services', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('21cbb342-a039-47f4-8a1b-1ee2d8b7f585', 'Department Head', 'Head of a specific department', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('337116e5-d293-4f91-bb78-545946f236a1', 'Administrative Assistant', 'Assistant providing administrative support', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('a36b6c6d-1aa0-4e6a-9cc8-a66ec08e7a4b', 'Executive Assistant', 'Assistant to senior executives', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('84107c40-e043-43ab-82e9-8fda09720889', 'Hospital Manager', 'Manager of hospital operations', '69d1c38d-2d74-4299-817b-517abda58b0f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('e56b899b-3c17-4333-b931-7b14107052aa', 'Chief Financial Officer', 'CFO of the hospital', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('3a8e15bc-5dc8-49ff-b20d-f5f75484456c', 'Accountant', 'Professional managing financial records', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('08b4c831-30e5-4801-adca-2e6a6b472368', 'Financial Analyst', 'Professional analyzing financial data', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('d30b3f72-25e0-462e-972a-d7cff9fc9e14', 'Billing Specialist', 'Specialist handling medical billing', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('db5d55ea-8285-48ce-8958-7be410f16792', 'Revenue Cycle Manager', 'Manager of revenue cycle operations', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('ec069b65-98c4-46ce-9482-dbe70485e3ef', 'Accounts Payable Clerk', 'Clerk managing accounts payable', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('438f23fc-d765-44ac-b2f2-0fd299dd2a60', 'Payroll Manager', 'Manager of payroll operations', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('d49766d8-021b-4478-99fc-e46a252c510c', 'Financial Controller', 'Controller of financial operations', '04ebbbce-d888-480d-a1a2-4599109e2d46', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('fa6da6c4-9843-4bd1-a2a6-fc3e44917404', 'HR Director', 'Director of human resources', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('96af833e-a052-4838-b36d-e1309ac06042', 'HR Manager', 'Manager of human resources department', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('8ef325e6-f7d1-4a97-a898-b4a787486ead', 'HR Generalist', 'Generalist providing HR support', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('e10503c2-5f60-4a3c-a0d4-6c069df29a1e', 'Recruiter', 'Professional responsible for hiring', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('59feed0a-2b2d-4c67-b149-0c348e6ff42d', 'Training Coordinator', 'Coordinator of employee training', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('2beef42b-c29e-4c6b-a056-6cc8994dcd53', 'Compensation Analyst', 'Analyst managing compensation programs', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('f4aaf9aa-83c1-4a50-81b8-2c2ea564fec3', 'Employee Relations Specialist', 'Specialist handling employee relations', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('b51588f6-94d1-471e-b451-7431d129d71b', 'HR Assistant', 'Assistant providing HR support', 'c6615015-4728-473e-a14c-40686e9d597f', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('bedcc3c5-361c-41d9-b29b-fce92e6aac85', 'IT Director', 'Director of information technology', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('c9662e1d-8ab8-4e2e-8a7d-1f3d9485578a', 'System Administrator', 'Professional managing IT systems', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('afb91e8b-cae9-4491-899f-8cde3951ca62', 'Network Administrator', 'Professional managing network infrastructure', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('47931197-105c-4ebc-926a-a4d68e68dc73', 'Database Administrator', 'Professional managing databases', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('74a7d7f6-17a9-4b06-a5fb-b10818347b4d', 'IT Support Specialist', 'Professional providing IT support', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('2ee12051-d35d-4c01-bbb7-7eaf88687774', 'Software Developer', 'Developer creating software solutions', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('e4e25767-c253-40e5-8781-ac1219f14906', 'Security Analyst', 'Analyst managing IT security', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('7b4d6aef-2d35-4415-a82a-ba730eb81661', 'IT Project Manager', 'Manager of IT projects', 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('36424165-6afb-4603-a237-379fa7e85209', 'Marketing Director', 'Director of marketing activities', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('90c8978c-beb4-442e-9f67-143406422b6b', 'Communications Manager', 'Manager of communications activities', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('9dec9c95-934f-4de3-be41-62644947829a', 'Public Relations Specialist', 'Specialist handling public relations', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('aa382bc0-bfa7-482d-a6f6-ad29ea8a5190', 'Marketing Coordinator', 'Coordinator of marketing activities', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('d7e53526-5dbd-4b3d-a51c-2ac5701b83d7', 'Content Creator', 'Creator of marketing content', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('d5ad0d11-7b54-4528-a649-db0844492ec6', 'Social Media Manager', 'Manager of social media presence', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('7247904e-64db-40ab-bb35-bfc84e9e19a9', 'Graphic Designer', 'Designer creating visual content', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('76469f20-a68f-441c-8002-41440b1d1d9b', 'Community Outreach Coordinator', 'Coordinator of community outreach', 'f2a3c406-0416-4e33-b5aa-7388187b7e9b', '2026-02-17 16:26:28.500851+02', '2026-02-17 16:26:28.500851+02', NULL, NULL),
            ('13e409b4-ccaa-49e8-9fce-c05c67bd7ce6', 'IT Manager', NULL, 'b277017f-5f87-439b-8433-33707796c2b7', '2026-02-17 15:59:20.660278+02', '2026-02-17 15:59:20.660278+02', NULL, NULL);
        END IF;
    END IF;

    -- Insert sample data for other tables if they are empty
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'announcements' AND table_schema = 'public') THEN
        IF (SELECT COUNT(*) FROM public.announcements) = 0 THEN
            INSERT INTO public.announcements (announcement_id, title, message, type, target_audience, target_department_id, target_role_id, is_active, expires_at, attachment_url, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES 
            ('981089b6-3dcb-425e-bf06-cd08f58fba08', 'Holiday', 'asdasdad', 'general', 'All Staff', NULL, NULL, true, '2026-03-03 00:00:00+02', NULL, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 07:18:57.490797+02', '2026-03-02 07:18:57.490797+02', NULL, NULL),
            ('01314e2e-1a7d-421d-a3f4-30ed4e84edee', 'asdfghjk', 'asdfghjk', 'general', 'All Staff', NULL, NULL, true, NULL, NULL, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 07:19:39.868772+02', '2026-03-02 07:19:39.868772+02', NULL, NULL),
            ('ba394cd9-12a7-4f76-bfcb-7b6b6ce291eb', 'testing', 'testing', 'general', 'Medical, Nursing, IT', NULL, NULL, true, NULL, NULL, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 07:30:55.406572+02', '2026-03-02 07:30:55.406572+02', NULL, NULL);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'attendance_logs' AND table_schema = 'public') THEN
        IF (SELECT COUNT(*) FROM public.attendance_logs) = 0 THEN
            INSERT INTO public.attendance_logs (attendance_log_id, user_id, check_in_time, check_out_time, location, accuracy, device_id, offline_flag, sync_time, created_at, updated_at, deleted_at, deleted_by, shift_type, work_hours) VALUES 
            ('b024aff9-2f3e-4d61-9315-46e58790edef', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-02-19 13:08:22.826467+02', NULL, NULL, NULL, NULL, false, NULL, '2026-02-19 13:08:22.826467+02', '2026-02-26 08:15:35.160756+02', NULL, NULL, 'Day Shift', NULL),
            ('e79c04aa-9987-4f49-8aa7-e03baf4d5974', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-02-24 08:40:04.957727+02', NULL, NULL, NULL, NULL, false, NULL, '2026-02-24 08:40:04.957727+02', '2026-02-26 08:15:35.160756+02', NULL, NULL, 'Day Shift', NULL),
            ('fe8c55bd-7883-4bb2-b592-78be478869f0', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', '2026-02-24 12:46:35.868274+02', NULL, NULL, NULL, NULL, false, NULL, '2026-02-24 12:46:35.868274+02', '2026-02-26 08:15:35.160756+02', NULL, NULL, 'Day Shift', NULL);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'audit_logs' AND table_schema = 'public') THEN
        IF (SELECT COUNT(*) FROM public.audit_logs) = 0 THEN
            -- Try inserting with minimal columns first, then with full columns if that fails
            BEGIN
                INSERT INTO public.audit_logs (audit_id, actor_id, action, occurred_at) VALUES 
                ('7b74d33d-2c51-4620-9b60-f59c3ac7c894', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_out', '2026-03-05 21:57:04.639363+02'),
                ('5bf9e6f8-ad79-4d27-911a-8ff3cb472707', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_in', '2026-03-05 21:57:54.619129+02'),
                ('75b417c3-7764-4754-be38-88fb08c8f107', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_out', '2026-03-05 21:59:06.443682+02');
            EXCEPTION WHEN OTHERS THEN
                -- If minimal insert fails, try with more columns
                INSERT INTO public.audit_logs (audit_id, actor_id, action, entity_type, entity_id, old_value, new_value, ip_address, user_agent, occurred_at, entity, details, "timestamp") VALUES 
                ('7b74d33d-2c51-4620-9b60-f59c3ac7c894', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_out', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-05 21:57:04.639363+02', 'attendance', '{"work_hours": 0.12561389694444444, "attendance_log_id": "d6ee992a-b586-4173-b8d1-a8b1954a52a9"}', '2026-03-05 21:57:04.650453+02'),
                ('5bf9e6f8-ad79-4d27-911a-8ff3cb472707', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_in', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-05 21:57:54.619129+02', 'attendance', '{"attendance_log_id": "11185bd4-e7c6-47c8-950d-199bbe11452d"}', '2026-03-05 21:57:54.622156+02'),
                ('75b417c3-7764-4754-be38-88fb08c8f107', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'check_out', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-05 21:59:06.443682+02', 'attendance', '{"work_hours": 0.019951729722222224, "attendance_log_id": "11185bd4-e7c6-47c8-950d-199bbe11452d"}', '2026-03-05 21:59:06.446829+02');
            END;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications' AND table_schema = 'public') THEN
        IF (SELECT COUNT(*) FROM public.notifications) = 0 THEN
            INSERT INTO public.notifications (notification_id, user_id, title, message, type, is_read, created_at, updated_at, deleted_at, deleted_by) VALUES 
            ('7ddb4b5e-61ef-4cdb-846c-4bff077d16b1', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'Request Approved', 'Your Annual Leave request has been approved', 'request', false, '2026-03-06 05:05:21.002739+02', '2026-03-06 05:05:21.002739+02', NULL, NULL),
            ('0078e07d-55b9-4c3a-8a04-d02d7769b6b9', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'Geofence Violation Detected', 'Check-in location was 8152917m outside work area', 'security', false, '2026-03-07 20:38:16.820101+02', '2026-03-07 20:38:16.820101+02', NULL, NULL),
            ('e9ef276e-6b09-4ec9-aecd-f3b98de1ec91', 'b64ca688-a13a-4d9c-8cd3-8b078ff697af', '✅ Check-in Successful', 'You successfully checked in at 20:38 for Night Shift', 'attendance', false, '2026-03-07 20:38:16.820101+02', '2026-03-07 20:38:16.820101+02', NULL, NULL);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        IF (SELECT COUNT(*) FROM public.users) = 0 THEN
            INSERT INTO public.users (user_id, employee_number, national_id, first_name, surname, other_names, suffix, date_of_birth, gender, home_of_origin, traditional_authority, district, current_address, contact_number, email, marital_status, spouse_name, spouse_contact, date_of_employment, department_id, is_head_of_department, phone, password_hash, role_id, status, profile_photo_url, blacklisted_at, blacklisted_reason, registration_timestamp, selfie_verified, last_login_at, created_at, updated_at, deleted_at, deleted_by, designation_id, grade_id) VALUES 
            ('b64ca688-a13a-4d9c-8cd3-8b078ff697af', 'EMP2', 'NAT2', 'Maxwell', 'Chisale', 'Yankho', 'MR', '2001-02-04', 'male', 'Mitundu', 'Chiseka', 'Lilongwe', 'st johns', NULL, 'cis-011-21@must.ac.mw', 'single', '', '', '2025-02-02', 'b277017f-5f87-439b-8433-33707796c2b7', false, '0883271664', '$2b$12$8h83NsXhzmBUpB3ktyYrLuV7KMx5sW1DZ8n/qTES7deWf8oyuBE16', '585f3343-9234-47ff-8c6c-021a7b3ca84f', 'active', NULL, NULL, NULL, '2026-02-19 08:27:53.217735+02', false, '2026-03-07 18:37:53.927935+02', '2026-02-19 08:27:53.217735+02', '2026-03-07 20:37:53.567819+02', NULL, NULL, '13e409b4-ccaa-49e8-9fce-c05c67bd7ce6', '83ebcd88-559f-4150-87a5-cfa681c148cd'),
            ('ae7fafd7-72ed-428e-9ef3-debc44e02d47', 'Emp1', 'NATIONAL1', 'Yankho', 'Chisale', 'Maxwell', 'Mr', '2001-02-23', 'male', 'Mitundu', 'Chiseka', 'Lilongwe', 'St johns', NULL, 'yankhochisale4@gmail.com', 'single', '', '', '2025-02-01', 'b277017f-5f87-439b-8433-33707796c2b7', false, '0997823454', '$2b$12$ezXx85RHfj/JwHd29YoOuuC52Pdk57bRcyFpGBUNREKHoP/dUXPqa', '970f339b-6bb2-4851-a9fc-1b2b89a67b21', 'active', NULL, NULL, NULL, '2026-02-17 15:59:21.048198+02', false, '2026-03-08 20:57:41.406237+02', '2026-02-17 15:59:21.048198+02', '2026-03-08 22:57:40.822842+02', NULL, NULL, '13e409b4-ccaa-49e8-9fce-c05c67bd7ce6', '0ab214a5-a0cb-42f5-b96d-e1c31b41da86');
        END IF;
    END IF;

    -- Insert email verifications data if table is empty
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'email_verifications' AND table_schema = 'public') THEN
        IF (SELECT COUNT(*) FROM public.email_verifications) = 0 THEN
            INSERT INTO public.email_verifications (verification_id, email, otp_code, purpose, expires_at, is_used, attempts, created_at, updated_at) VALUES 
            ('e2e1771b-35e0-4204-af3a-dfdbfeccc6dd', 'yankhochisale4@gmail.com', '717504', 'registration', '2026-02-24 06:44:02.721227+02', true, 0, '2026-02-24 06:34:02.721227+02', '2026-02-24 06:34:02.721227+02'),
            ('0ccdacac-0e41-4397-ba43-a9fdd9ea3a63', 'yankhochisale4@gmail.com', '762754', 'registration', '2026-02-24 06:47:21.239062+02', true, 0, '2026-02-24 06:37:21.239062+02', '2026-02-24 06:38:11.798771+02'),
            ('851b4372-3a33-40b1-a56e-c86310f4cfdb', 'cis-011-21@must.ac.mw', '718243', 'registration', '2026-02-24 10:54:58.86864+02', true, 0, '2026-02-24 10:44:58.86864+02', '2026-02-24 10:45:28.485198+02');
        END IF;
    END IF;

    -- Insert employee files data if table is empty
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'employee_files' AND table_schema = 'public') THEN
        IF (SELECT COUNT(*) FROM public.employee_files) = 0 THEN
            INSERT INTO public.employee_files (employee_file_id, user_id, file_type, file_url, original_filename, upload_date, created_at, deleted_at, deleted_by) VALUES 
            ('0dfa5a6d-6ae5-475f-ba7d-ece43285aca4', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', 'payslip', 'http://0.0.0.0:8000/uploads/employee_files/a146d69d-5a31-4305-bc9d-82258bcb9981.png', NULL, '2026-03-05 07:08:27.110744+02', '2026-03-05 09:08:27.115243+02', NULL, NULL);
        END IF;
    END IF;

    -- Insert holidays data if table is empty
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'holidays' AND table_schema = 'public') THEN
        IF (SELECT COUNT(*) FROM public.holidays) = 0 THEN
            INSERT INTO public.holidays (holiday_id, name, date, description, type, category, source, country_code, is_recurring, created_by, created_at, updated_at, deleted_at, deleted_by) VALUES 
            ('25082a67-a444-46ad-9181-44f062a1df63', 'ash', '2026-03-03', 'asdfghjk', 'Institutional Holiday', 'institutional', 'manual', 'MW', false, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:08:03.93446+02', '2026-03-02 08:24:01.097879+02', '2026-03-02 08:24:01.097879+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47'),
            ('cb0435ae-4c3d-47d0-b680-921e9a356a6f', 'testing', '2026-03-04', 'test 2', 'Institutional Holiday', 'institutional', 'manual', 'MW', false, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:16:22.162834+02', '2026-03-02 08:24:31.45783+02', '2026-03-02 08:24:31.45783+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47'),
            ('5ebab23e-3d11-4308-aa10-fed829f750f3', 'testing', '2026-03-04', 'test 2', 'Institutional Holiday', 'institutional', 'manual', 'MW', false, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:16:26.298139+02', '2026-03-02 08:30:57.248916+02', '2026-03-02 08:30:57.248916+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47'),
            ('4f4b1e01-84b0-4ce2-9a86-9cb58852775e', 'test 3', '2026-03-05', 'testing 3', 'Institutional Holiday', 'institutional', 'manual', 'MW', false, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:19:29.280819+02', '2026-03-02 08:36:09.584385+02', '2026-03-02 08:36:09.584385+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47'),
            ('97e30f20-18a4-4b94-b966-8b27b3b7b224', 'test', '2026-03-12', 'ad', 'Institutional Holiday', 'institutional', 'manual', 'MW', true, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 08:35:59.41296+02', '2026-03-02 08:42:55.292843+02', '2026-03-02 08:42:55.292843+02', 'ae7fafd7-72ed-428e-9ef3-debc44e02d47'),
            ('f413c875-ebd6-4acd-b7fc-f38954bd7974', 'is it working', '2026-03-04', 'maybe', 'Institutional Holiday', 'institutional', 'manual', 'MW', true, 'ae7fafd7-72ed-428e-9ef3-debc44e02d47', '2026-03-02 09:22:25.68131+02', '2026-03-02 09:22:25.68131+02', NULL, NULL);
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
