-- Script to resolve the conflict between public_holidays and holidays tables
-- Run this to understand the data and then choose your resolution approach

-- First, let's see what data exists in both tables
DO $$
BEGIN
    RAISE NOTICE '=== COMPARING TABLE STRUCTURES ===';
END $$;

-- Structure of public_holidays table
SELECT 
    'public_holidays' as table_name,
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'public_holidays' 
AND table_schema = current_schema()
ORDER BY ordinal_position;

-- Structure of holidays table  
SELECT 
    'holidays' as table_name,
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'holidays' 
AND table_schema = current_schema()
ORDER BY ordinal_position;

-- Check data counts
DO $$
BEGIN
    RAISE NOTICE '=== DATA COUNTS ===';
END $$;

SELECT 
    (SELECT COUNT(*) FROM public_holidays) as public_holidays_count,
    (SELECT COUNT(*) FROM holidays) as holidays_count;

-- Sample data from public_holidays (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'public_holidays' AND table_schema = current_schema()) THEN
        IF (SELECT COUNT(*) FROM public_holidays) > 0 THEN
            RAISE NOTICE '=== SAMPLE DATA FROM public_holidays ===';
            -- Get sample data (first 3 rows)
            PERFORM * FROM (
                SELECT 'public_holidays' as source_table, * 
                FROM public_holidays 
                LIMIT 3
            ) AS sample_data;
        END IF;
    END IF;
END $$;

-- Sample data from holidays (if exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'holidays' AND table_schema = current_schema()) THEN
        IF (SELECT COUNT(*) FROM holidays) > 0 THEN
            RAISE NOTICE '=== SAMPLE DATA FROM holidays ===';
            -- Get sample data (first 3 rows)
            PERFORM * FROM (
                SELECT 'holidays' as source_table, * 
                FROM holidays 
                LIMIT 3
            ) AS sample_data;
        END IF;
    END IF;
END $$;
