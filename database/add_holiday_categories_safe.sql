-- Safe migration script for holiday categories
-- This script handles scenarios where holidays table might already exist

-- Check if public_holidays table exists and holidays table doesn't exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'public_holidays' AND table_schema = current_schema())
    AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'holidays' AND table_schema = current_schema()) THEN
        -- Rename the table from public_holidays to holidays for clarity
        ALTER TABLE public_holidays RENAME TO holidays;
        RAISE NOTICE 'Renamed public_holidays to holidays';
    ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'holidays' AND table_schema = current_schema())
    AND NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'public_holidays' AND table_schema = current_schema()) THEN
        -- holidays table already exists, no need to rename
        RAISE NOTICE 'holidays table already exists, skipping rename';
    ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'public_holidays' AND table_schema = current_schema())
    AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'holidays' AND table_schema = current_schema()) THEN
        -- Both tables exist, this is an error state
        RAISE EXCEPTION 'Both public_holidays and holidays tables exist. Please resolve this conflict manually.';
    END IF;
END $$;

-- Add new columns to holidays table (IF NOT EXISTS makes this safe)
ALTER TABLE holidays 
ADD COLUMN IF NOT EXISTS category VARCHAR(20) DEFAULT 'institutional',
ADD COLUMN IF NOT EXISTS source VARCHAR(100),
ADD COLUMN IF NOT EXISTS country_code VARCHAR(2) DEFAULT 'MW';

-- Make created_by nullable to allow public holidays from API without a creator
DO $$
BEGIN
    -- Check if created_by column exists and is NOT NULL
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'holidays' 
        AND table_schema = current_schema() 
        AND column_name = 'created_by'
        AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE holidays ALTER COLUMN created_by DROP NOT NULL;
        RAISE NOTICE 'Made created_by column nullable';
    ELSE
        RAISE NOTICE 'created_by column is already nullable or does not exist';
    END IF;
END $$;

-- Update existing records to have 'institutional' category by default
-- This assumes existing holidays are institutional holidays
UPDATE holidays 
SET category = 'institutional', source = 'manual' 
WHERE category IS NULL;

-- Add comments to describe the new columns (IF NOT EXISTS is implicit for comments)
COMMENT ON COLUMN holidays.category IS 'Holiday category: institutional or public';
COMMENT ON COLUMN holidays.source IS 'Source of the holiday: manual, government_api, etc.';
COMMENT ON COLUMN holidays.country_code IS 'ISO country code for public holidays (e.g., MW for Malawi)';

-- Create indexes for better query performance (IF NOT EXISTS makes this safe)
CREATE INDEX IF NOT EXISTS idx_holidays_category ON holidays(category);
CREATE INDEX IF NOT EXISTS idx_holidays_source ON holidays(source);

-- Show final table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'holidays' 
AND table_schema = current_schema()
ORDER BY ordinal_position;
