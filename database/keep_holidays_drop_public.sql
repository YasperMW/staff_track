-- Option 2: Keep holidays table and drop public_holidays
-- Use this if holidays table has the data you want to keep

-- First, ensure holidays table has all required columns
DO $$
BEGIN
    -- Add category column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'holidays' AND column_name = 'category'
    ) THEN
        ALTER TABLE holidays ADD COLUMN category VARCHAR(20) DEFAULT 'institutional';
    END IF;
    
    -- Add source column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'holidays' AND column_name = 'source'
    ) THEN
        ALTER TABLE holidays ADD COLUMN source VARCHAR(100);
    END IF;
    
    -- Add country_code column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'holidays' AND column_name = 'country_code'
    ) THEN
        ALTER TABLE holidays ADD COLUMN country_code VARCHAR(2) DEFAULT 'MW';
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
    END IF;
END $$;

-- Update existing records to have proper defaults
UPDATE holidays 
SET category = COALESCE(category, 'institutional'),
    source = COALESCE(source, 'manual'),
    country_code = COALESCE(country_code, 'MW')
WHERE category IS NULL OR source IS NULL OR country_code IS NULL;

-- Drop the public_holidays table
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
