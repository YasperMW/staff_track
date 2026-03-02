-- Final script to ensure holidays table has all required columns and structure
-- Run this after you have only the holidays table

-- Check and add missing columns
DO $$
BEGIN
    RAISE NOTICE '=== Checking and adding missing columns ===';
    
    -- Add category column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'holidays' AND column_name = 'category'
    ) THEN
        ALTER TABLE holidays ADD COLUMN category VARCHAR(20) DEFAULT 'institutional';
        RAISE NOTICE 'Added category column';
    ELSE
        RAISE NOTICE 'category column already exists';
    END IF;
    
    -- Add source column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'holidays' AND column_name = 'source'
    ) THEN
        ALTER TABLE holidays ADD COLUMN source VARCHAR(100);
        RAISE NOTICE 'Added source column';
    ELSE
        RAISE NOTICE 'source column already exists';
    END IF;
    
    -- Add country_code column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'holidays' AND column_name = 'country_code'
    ) THEN
        ALTER TABLE holidays ADD COLUMN country_code VARCHAR(2) DEFAULT 'MW';
        RAISE NOTICE 'Added country_code column';
    ELSE
        RAISE NOTICE 'country_code column already exists';
    END IF;
END $$;

-- Make created_by nullable if needed
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'holidays' AND column_name = 'created_by' AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE holidays ALTER COLUMN created_by DROP NOT NULL;
        RAISE NOTICE 'Made created_by column nullable';
    ELSE
        RAISE NOTICE 'created_by column is already nullable or does not exist';
    END IF;
END $$;

-- Update existing records to have proper defaults
UPDATE holidays 
SET category = COALESCE(category, 'institutional'),
    source = COALESCE(source, 'manual'),
    country_code = COALESCE(country_code, 'MW')
WHERE category IS NULL OR source IS NULL OR country_code IS NULL;

-- Add comments to describe the columns
COMMENT ON COLUMN holidays.category IS 'Holiday category: institutional or public';
COMMENT ON COLUMN holidays.source IS 'Source of the holiday: manual, government_api, etc.';
COMMENT ON COLUMN holidays.country_code IS 'ISO country code for public holidays (e.g., MW for Malawi)';

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_holidays_category ON holidays(category);
CREATE INDEX IF NOT EXISTS idx_holidays_source ON holidays(source);

-- Show final table structure
RAISE NOTICE '=== FINAL HOLIDAYS TABLE STRUCTURE ===';
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'holidays' 
AND table_schema = current_schema()
ORDER BY ordinal_position;

-- Show data summary
RAISE NOTICE '=== DATA SUMMARY ===';
SELECT 
    COUNT(*) as total_holidays,
    COUNT(CASE WHEN category = 'institutional' THEN 1 END) as institutional_holidays,
    COUNT(CASE WHEN category = 'public' THEN 1 END) as public_holidays,
    COUNT(CASE WHEN source = 'manual' THEN 1 END) as manual_entries,
    COUNT(CASE WHEN source = 'government_api' THEN 1 END) as api_entries
FROM holidays;

RAISE NOTICE '=== HOLIDAYS TABLE IS READY ===';
