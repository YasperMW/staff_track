-- Option 3: Rename public_holidays to holidays and drop the existing holidays table
-- Use this if public_holidays has the data you want to keep

-- First, drop the existing holidays table
DROP TABLE IF EXISTS holidays;

-- Rename public_holidays to holidays
ALTER TABLE public_holidays RENAME TO holidays;

-- Add new columns if they don't exist
ALTER TABLE holidays 
ADD COLUMN IF NOT EXISTS category VARCHAR(20) DEFAULT 'institutional',
ADD COLUMN IF NOT EXISTS source VARCHAR(100),
ADD COLUMN IF NOT EXISTS country_code VARCHAR(2) DEFAULT 'MW';

-- Make created_by nullable if needed
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'holidays' AND column_name = 'created_by' AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE holidays ALTER COLUMN created_by DROP NOT NULL;
    END IF;
END $$;

-- Update existing records to have proper defaults
UPDATE holidays 
SET category = COALESCE(category, 'institutional'),
    source = COALESCE(source, 'manual'),
    country_code = COALESCE(country_code, 'MW')
WHERE category IS NULL OR source IS NULL OR country_code IS NULL;

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
