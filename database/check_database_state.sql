-- Script to check the current state of holiday tables
-- Run this to understand what tables exist and their structure

-- Check if holiday-related tables exist
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = current_schema()
AND (table_name = 'holidays' OR table_name = 'public_holidays')
ORDER BY table_name;

-- If holidays table exists, show its structure
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'holidays' AND table_schema = current_schema()) THEN
        RAISE NOTICE '=== HOLIDAYS TABLE STRUCTURE ===';
        SELECT 
            column_name, 
            data_type, 
            is_nullable,
            column_default,
            character_maximum_length
        FROM information_schema.columns 
        WHERE table_name = 'holidays' 
        AND table_schema = current_schema()
        ORDER BY ordinal_position;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'public_holidays' AND table_schema = current_schema()) THEN
        RAISE NOTICE '=== PUBLIC_HOLIDAYS TABLE STRUCTURE ===';
        SELECT 
            column_name, 
            data_type, 
            is_nullable,
            column_default,
            character_maximum_length
        FROM information_schema.columns 
        WHERE table_name = 'public_holidays' 
        AND table_schema = current_schema()
        ORDER BY ordinal_position;
    END IF;
END $$;

-- Check for existing data
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'holidays' AND table_schema = current_schema()) THEN
        RAISE NOTICE '=== HOLIDAYS TABLE DATA COUNT ===';
        EXECUTE 'SELECT COUNT(*) as holidays_count FROM holidays';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'public_holidays' AND table_schema = current_schema()) THEN
        RAISE NOTICE '=== PUBLIC_HOLIDAYS TABLE DATA COUNT ===';
        EXECUTE 'SELECT COUNT(*) as public_holidays_count FROM public_holidays';
    END IF;
END $$;
