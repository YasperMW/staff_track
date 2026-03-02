-- Migration script to rename table and add holiday categories
-- Run this script to update the existing holidays table structure

-- Rename the table from public_holidays to holidays for clarity
ALTER TABLE public_holidays RENAME TO holidays;

-- Add new columns to holidays table
ALTER TABLE holidays 
ADD COLUMN IF NOT EXISTS category VARCHAR(20) DEFAULT 'institutional',
ADD COLUMN IF NOT EXISTS source VARCHAR(100),
ADD COLUMN IF NOT EXISTS country_code VARCHAR(2) DEFAULT 'MW';

-- Make created_by nullable to allow public holidays from API without a creator
ALTER TABLE holidays 
ALTER COLUMN created_by DROP NOT NULL;

-- Update existing records to have 'institutional' category by default
-- This assumes existing holidays are institutional holidays
UPDATE holidays 
SET category = 'institutional', source = 'manual' 
WHERE category IS NULL;

-- Add comments to describe the new columns
COMMENT ON COLUMN holidays.category IS 'Holiday category: institutional or public';
COMMENT ON COLUMN holidays.source IS 'Source of the holiday: manual, government_api, etc.';
COMMENT ON COLUMN holidays.country_code IS 'ISO country code for public holidays (e.g., MW for Malawi)';

-- Create index on category for better query performance
CREATE INDEX IF NOT EXISTS idx_holidays_category ON holidays(category);

-- Create index on source for better query performance
CREATE INDEX IF NOT EXISTS idx_holidays_source ON holidays(source);

-- Update sequences and constraints if needed
-- (PostgreSQL automatically updates sequences and primary key constraints when renaming tables)
