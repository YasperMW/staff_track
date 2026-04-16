-- Migration: Add late_reason and early_checkout_reason columns to attendance_logs table
-- Date: 2024-04-16
-- Purpose: Store reasons for late check-in and early check-out

-- Add late_reason column for late check-ins
ALTER TABLE attendance_logs
ADD COLUMN IF NOT EXISTS late_reason TEXT;

-- Add early_checkout_reason column for early check-outs
ALTER TABLE attendance_logs
ADD COLUMN IF NOT EXISTS early_checkout_reason TEXT;

-- Add comments for documentation
COMMENT ON COLUMN attendance_logs.late_reason IS 'Reason provided by employee for late check-in (after 09:00 for day shift, after 18:00 for night shift)';
COMMENT ON COLUMN attendance_logs.early_checkout_reason IS 'Reason provided by employee for early check-out (before shift end time)';