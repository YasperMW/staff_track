-- Migration: Create shift_configurations table
-- This table allows HR to configure shift time ranges dynamically

-- Create the shift_configurations table
CREATE TABLE IF NOT EXISTS public.shift_configurations (
    shift_config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shift_name VARCHAR(50) NOT NULL UNIQUE,
    shift_type VARCHAR(20) NOT NULL CHECK (shift_type IN ('Day Shift', 'Night Shift')),
    
    -- Check-in time ranges
    check_in_earliest TIME NOT NULL DEFAULT '06:00:00',
    check_in_latest TIME NOT NULL DEFAULT '07:45:00',
    official_start_time TIME NOT NULL DEFAULT '07:30:00',
    
    -- Check-out time ranges  
    check_out_earliest TIME NOT NULL DEFAULT '16:00:00',
    check_out_latest TIME NOT NULL DEFAULT '17:30:00',
    official_end_time TIME NOT NULL DEFAULT '16:30:00',
    
    -- Extended shift threshold
    extended_start_time TIME NOT NULL DEFAULT '17:30:00',
    
    -- Late check-in threshold (for requiring reasons)
    late_threshold TIME NOT NULL DEFAULT '09:00:00',
    
    -- Status and metadata
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES public.users(user_id),
    updated_by UUID REFERENCES public.users(user_id),
    
    -- Description for HR reference
    description TEXT
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_shift_configurations_type ON public.shift_configurations(shift_type);
CREATE INDEX IF NOT EXISTS idx_shift_configurations_active ON public.shift_configurations(is_active);

-- Add trigger for updated_at
CREATE TRIGGER update_shift_configurations_timestamp 
    BEFORE UPDATE ON public.shift_configurations
    FOR EACH ROW
    EXECUTE FUNCTION public.update_timestamp();

-- Insert default shift configurations
INSERT INTO public.shift_configurations (
    shift_name,
    shift_type,
    check_in_earliest,
    check_in_latest,
    official_start_time,
    check_out_earliest,
    check_out_latest,
    official_end_time,
    extended_start_time,
    late_threshold,
    description
) VALUES 
(
    'Standard Day Shift',
    'Day Shift',
    '06:00:00',
    '07:45:00',
    '07:30:00',
    '16:00:00',
    '17:30:00',
    '16:30:00',
    '17:30:00',
    '09:00:00',
    'Standard day shift with flexible check-in/out times'
),
(
    'Standard Night Shift',
    'Night Shift',
    '16:30:00',
    '23:59:59',
    '16:30:00',
    '06:00:00',
    '08:00:00',
    '07:30:00',
    '08:00:00',
    '18:00:00',
    'Standard night shift spanning midnight'
)
ON CONFLICT (shift_type) DO NOTHING;

-- Add comments for documentation
COMMENT ON TABLE public.shift_configurations IS 'Stores configurable time ranges for different shift types, allowing HR to modify shift schedules';
COMMENT ON COLUMN public.shift_configurations.shift_name IS 'Human-readable name for the shift configuration';
COMMENT ON COLUMN public.shift_configurations.shift_type IS 'Type of shift: Day Shift or Night Shift';
COMMENT ON COLUMN public.shift_configurations.check_in_earliest IS 'Earliest allowed check-in time';
COMMENT ON COLUMN public.shift_configurations.check_in_latest IS 'Latest allowed check-in time without requiring reason';
COMMENT ON COLUMN public.shift_configurations.official_start_time IS 'Official shift start time';
COMMENT ON COLUMN public.shift_configurations.check_out_earliest IS 'Earliest allowed check-out time';
COMMENT ON COLUMN public.shift_configurations.check_out_latest IS 'Latest allowed check-out time without requiring reason';
COMMENT ON COLUMN public.shift_configurations.official_end_time IS 'Official shift end time';
COMMENT ON COLUMN public.shift_configurations.extended_start_time IS 'Time after which shift is considered extended';
COMMENT ON COLUMN public.shift_configurations.late_threshold IS 'Time after which check-in is considered late and requires reason';
