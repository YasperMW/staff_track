-- Option 1: Merge data from public_holidays into holidays table, then drop public_holidays
-- Use this if both tables have valuable data and you want to combine them

-- First, add any missing columns to holidays table to match public_holidays structure
DO $$
BEGIN
    -- Add category column if it doesn't exist in holidays
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'holidays' AND column_name = 'category'
    ) THEN
        ALTER TABLE holidays ADD COLUMN category VARCHAR(20) DEFAULT 'institutional';
    END IF;
    
    -- Add source column if it doesn't exist in holidays
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'holidays' AND column_name = 'source'
    ) THEN
        ALTER TABLE holidays ADD COLUMN source VARCHAR(100);
    END IF;
    
    -- Add country_code column if it doesn't exist in holidays
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'holidays' AND column_name = 'country_code'
    ) THEN
        ALTER TABLE holidays ADD COLUMN country_code VARCHAR(2) DEFAULT 'MW';
    END IF;
END $$;

-- Make created_by nullable in holidays if needed
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'holidays' AND column_name = 'created_by' AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE holidays ALTER COLUMN created_by DROP NOT NULL;
    END IF;
END $$;

-- Merge data from public_holidays into holidays
-- This handles potential column differences between the tables
INSERT INTO holidays (
    holiday_id, name, date, description, type, category, source, 
    country_code, is_recurring, created_by, created_at, updated_at, 
    deleted_at, deleted_by
)
SELECT 
    holiday_id, name, date, description, type, 
    COALESCE(category, 'institutional') as category,
    COALESCE(source, 'manual') as source,
    COALESCE(country_code, 'MW') as country_code,
    is_recurring, created_by, created_at, updated_at, 
    deleted_at, deleted_by
FROM public_holidays
WHERE NOT EXISTS (
    SELECT 1 FROM holidays h 
    WHERE h.holiday_id = public_holidays.holiday_id
);

-- Update any existing records in holidays that don't have category set
UPDATE holidays 
SET category = 'institutional', source = 'manual' 
WHERE category IS NULL;

-- Drop the old public_holidays table
DROP TABLE IF EXISTS public_holidays;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_holidays_category ON holidays(category);
CREATE INDEX IF NOT EXISTS idx_holidays_source ON holidays(source);

-- Show final result
SELECT 
    'holidays' as final_table,
    COUNT(*) as total_records,
    COUNT(CASE WHEN category = 'institutional' THEN 1 END) as institutional_count,
    COUNT(CASE WHEN category = 'public' THEN 1 END) as public_count
FROM holidays;
