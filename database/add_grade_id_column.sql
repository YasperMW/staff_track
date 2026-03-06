-- Add missing grade_id column to users table
-- This column exists in the SQLAlchemy model but not in the database

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS grade_id uuid REFERENCES grades(grade_id);

-- Add comment to document the new column
COMMENT ON COLUMN users.grade_id IS 'Reference to the grade table for employee grade information';
