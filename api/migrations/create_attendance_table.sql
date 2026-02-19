-- Create attendance table
CREATE TABLE IF NOT EXISTS attendance (
    attendance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    date DATE NOT NULL,
    check_in_time TIME,
    check_out_time TIME,
    check_in_location TEXT,
    check_out_location TEXT,
    check_in_latitude NUMERIC(10, 8),
    check_in_longitude NUMERIC(11, 8),
    check_out_latitude NUMERIC(10, 8),
    check_out_longitude NUMERIC(11, 8),
    work_hours NUMERIC(5, 2),
    overtime_hours NUMERIC(5, 2),
    status VARCHAR(20) DEFAULT 'present',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_attendance_user_id ON attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date);
CREATE INDEX IF NOT EXISTS idx_attendance_user_date ON attendance(user_id, date);

-- Add unique constraint to prevent duplicate attendance records for the same user on the same day
ALTER TABLE attendance ADD CONSTRAINT unique_user_date_attendance UNIQUE (user_id, date);

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_attendance_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_attendance_updated_at
    BEFORE UPDATE ON attendance
    FOR EACH ROW
    EXECUTE FUNCTION update_attendance_updated_at();
