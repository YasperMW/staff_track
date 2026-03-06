-- Fix request_approvals table schema to match SQLAlchemy model
-- This migration adds missing columns and fixes column name mismatches

-- First, let's add the missing columns that exist in the SQLAlchemy model but not in the database

-- Add stage-specific fields for Leave approvals (Section B, C, D)
ALTER TABLE request_approvals 
ADD COLUMN IF NOT EXISTS hod_recommended_from DATE,
ADD COLUMN IF NOT EXISTS hod_recommended_to DATE,
ADD COLUMN IF NOT EXISTS hod_not_recommended_reason TEXT;

-- Add HR-specific fields (Section C)
ALTER TABLE request_approvals 
ADD COLUMN IF NOT EXISTS hr_annual_entitlement NUMERIC(5, 2),
ADD COLUMN IF NOT EXISTS hr_entitlement_taken_from DATE,
ADD COLUMN IF NOT EXISTS hr_entitlement_taken_to DATE,
ADD COLUMN IF NOT EXISTS hr_last_leave_from DATE,
ADD COLUMN IF NOT EXISTS hr_last_leave_to DATE,
ADD COLUMN IF NOT EXISTS hr_last_leave_days NUMERIC(5, 2),
ADD COLUMN IF NOT EXISTS hr_balance_if_approved NUMERIC(5, 2),
ADD COLUMN IF NOT EXISTS hr_leave_grant_status VARCHAR(30);

-- Add Administrator-specific fields (Section D)
ALTER TABLE request_approvals 
ADD COLUMN IF NOT EXISTS admin_granted_from DATE,
ADD COLUMN IF NOT EXISTS admin_granted_to DATE,
ADD COLUMN IF NOT EXISTS admin_total_days_approved NUMERIC(5, 2);

-- Add Trip-specific fields (Section C, D, E)
ALTER TABLE request_approvals 
ADD COLUMN IF NOT EXISTS accountant_funds_available BOOLEAN,
ADD COLUMN IF NOT EXISTS accountant_signed_date DATE,
ADD COLUMN IF NOT EXISTS hod_trip_recommendation TEXT,
ADD COLUMN IF NOT EXISTS admin_trip_approval_details TEXT;

-- Rename the timestamp column to match the model (approved_at -> timestamp)
DO $$
BEGIN
    -- Check if the approved_at column exists and timestamp doesn't
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'request_approvals' 
               AND column_name = 'approved_at')
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns 
                    WHERE table_name = 'request_approvals' 
                    AND column_name = 'timestamp') THEN
        -- Rename the column
        ALTER TABLE request_approvals RENAME COLUMN approved_at TO timestamp;
    END IF;
END $$;

-- Add comments to document the new columns
COMMENT ON COLUMN request_approvals.hod_recommended_from IS 'HOD recommended start date for leave';
COMMENT ON COLUMN request_approvals.hod_recommended_to IS 'HOD recommended end date for leave';
COMMENT ON COLUMN request_approvals.hod_not_recommended_reason IS 'HOD reason for not recommending leave';
COMMENT ON COLUMN request_approvals.hr_annual_entitlement IS 'HR annual leave entitlement';
COMMENT ON COLUMN request_approvals.hr_entitlement_taken_from IS 'HR entitlement taken from date';
COMMENT ON COLUMN request_approvals.hr_entitlement_taken_to IS 'HR entitlement taken to date';
COMMENT ON COLUMN request_approvals.hr_last_leave_from IS 'HR last leave from date';
COMMENT ON COLUMN request_approvals.hr_last_leave_to IS 'HR last leave to date';
COMMENT ON COLUMN request_approvals.hr_last_leave_days IS 'HR last leave days taken';
COMMENT ON COLUMN request_approvals.hr_balance_if_approved IS 'HR leave balance if approved';
COMMENT ON COLUMN request_approvals.hr_leave_grant_status IS 'HR leave grant status';
COMMENT ON COLUMN request_approvals.admin_granted_from IS 'Admin granted leave from date';
COMMENT ON COLUMN request_approvals.admin_granted_to IS 'Admin granted leave to date';
COMMENT ON COLUMN request_approvals.admin_total_days_approved IS 'Admin total days approved';
COMMENT ON COLUMN request_approvals.accountant_funds_available IS 'Accountant confirmation of funds availability';
COMMENT ON COLUMN request_approvals.accountant_signed_date IS 'Accountant signed date';
COMMENT ON COLUMN request_approvals.hod_trip_recommendation IS 'HOD trip recommendation';
COMMENT ON COLUMN request_approvals.admin_trip_approval_details IS 'Admin trip approval details';
