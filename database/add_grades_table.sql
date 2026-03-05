-- Migration script to add grades and annual leave entitlement

-- Create grades table
CREATE TABLE IF NOT EXISTS public.grades (
    grade_id uuid DEFAULT public.uuid_generate_v4() NOT NULL PRIMARY KEY,
    name character varying(50) NOT NULL UNIQUE,
    annual_leave_days integer DEFAULT 21 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted_at timestamp with time zone,
    deleted_by uuid
);

-- Add grade_id to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS grade_id uuid REFERENCES public.grades(grade_id);

-- Insert initial grades for ST JOHN'S HOSPITAL
INSERT INTO public.grades (name, annual_leave_days) VALUES
('Grade A', 30),
('Grade B', 28),
('Grade C', 25),
('Grade D', 21),
('Grade E', 18)
ON CONFLICT (name) DO NOTHING;
