-- Migration: Update users table to use designation_id instead of designation text field

-- First, add the new designation_id column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'designation_id'
    ) THEN
        ALTER TABLE users ADD COLUMN designation_id UUID REFERENCES designations(designation_id);
    END IF;
END $$;

-- Update existing users to map their designation text to designation_id
UPDATE users 
SET designation_id = d.designation_id
FROM designations d 
WHERE users.designation = d.name AND users.designation IS NOT NULL AND users.designation != '';

-- Drop the old designation text column (optional - comment out if you want to keep it for backup)
-- ALTER TABLE users DROP COLUMN designation;

-- Set designation_id to NOT NULL if all users have designations
-- ALTER TABLE users ALTER COLUMN designation_id SET NOT NULL;
