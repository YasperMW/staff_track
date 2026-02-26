-- Migration to add shift support to attendance system
-- Run this migration to update your database schema

-- Add shift_type column to attendance_logs table
ALTER TABLE attendance_logs 
ADD COLUMN shift_type VARCHAR(50) DEFAULT NULL;

-- Add work_hours column to store pre-calculated work hours
ALTER TABLE attendance_logs 
ADD COLUMN work_hours NUMERIC(5,2) DEFAULT NULL;

-- Update existing records with shift information
-- This is a one-time update for existing records
UPDATE attendance_logs 
SET shift_type = CASE 
    WHEN EXTRACT(HOUR FROM check_in_time) >= 7 AND EXTRACT(HOUR FROM check_in_time) < 16 THEN 'Day Shift'
    WHEN EXTRACT(HOUR FROM check_in_time) >= 16 OR EXTRACT(HOUR FROM check_in_time) < 7 THEN 'Night Shift'
    ELSE 'Unknown Shift'
END
WHERE shift_type IS NULL;

-- Update existing records with work hours
UPDATE attendance_logs 
SET work_hours = ROUND(
    EXTRACT(EPOCH FROM (check_out_time - check_in_time)) / 3600.0, 2
)
WHERE check_out_time IS NOT NULL AND work_hours IS NULL;

-- Add index for better performance on shift queries
CREATE INDEX IF NOT EXISTS idx_attendance_shift_type ON attendance_logs(shift_type);
CREATE INDEX IF NOT EXISTS idx_attendance_date_shift ON attendance_logs(date, shift_type);

-- Add comments for documentation
COMMENT ON COLUMN attendance_logs.shift_type IS 'The shift type (Day Shift/Night Shift) based on check-in time';
COMMENT ON COLUMN attendance_logs.work_hours IS 'Pre-calculated work hours in decimal format';
