-- Database Schema Fixes Summary
-- This file documents all the schema changes made to align the database with SQLAlchemy models

-- Migration 1: Add missing columns to requests table (add_requests_missing_columns.sql)
-- Added Section A - Applicant fields:
-- - leave_grant_required (BOOLEAN DEFAULT FALSE)
-- - contact_address (TEXT)

-- Added Second Form - Leave Duty Station fields:
-- - reason_for_leaving (TEXT)
-- - travel_date (DATE)
-- - travel_place (VARCHAR(255))

-- Added cost fields for Leave Duty Station:
-- - cost_accommodation (NUMERIC(12, 2))
-- - cost_breakfast (NUMERIC(12, 2))
-- - cost_lunch (NUMERIC(12, 2))
-- - cost_supper (NUMERIC(12, 2))
-- - cost_public_transport (NUMERIC(12, 2))
-- - cost_fuel_lubricants (NUMERIC(12, 2))
-- - cost_total (NUMERIC(12, 2) DEFAULT 0.0)

-- Migration 2: Fix request_approvals table schema (fix_request_approvals_schema.sql)
-- Added stage-specific fields for Leave approvals:
-- - hod_recommended_from (DATE)
-- - hod_recommended_to (DATE)
-- - hod_not_recommended_reason (TEXT)
-- - hr_annual_entitlement (NUMERIC(5, 2))
-- - hr_entitlement_taken_from (DATE)
-- - hr_entitlement_taken_to (DATE)
-- - hr_last_leave_from (DATE)
-- - hr_last_leave_to (DATE)
-- - hr_last_leave_days (NUMERIC(5, 2))
-- - hr_balance_if_approved (NUMERIC(5, 2))
-- - hr_leave_grant_status (VARCHAR(30))
-- - admin_granted_from (DATE)
-- - admin_granted_to (DATE)
-- - admin_total_days_approved (NUMERIC(5, 2))

-- Added stage-specific fields for Trip approvals:
-- - accountant_funds_available (BOOLEAN)
-- - accountant_signed_date (DATE)
-- - hod_trip_recommendation (TEXT)
-- - admin_trip_approval_details (TEXT)

-- Renamed column: approved_at -> timestamp

-- Migration 3: Add missing grade_id column to users table (add_grade_id_column.sql)
-- - grade_id (UUID REFERENCES grades(grade_id))

-- Model Fix: Updated RequestApproval model to use correct primary key column name
-- Changed: approval_id = Column(UUID...) -> approval_id = Column("request_approval_id", UUID...)

-- All migrations completed successfully on 2026-03-05
