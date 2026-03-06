-- Add missing columns to requests table
-- These columns exist in the SQLAlchemy model but not in the database

-- Add Section A - Applicant fields
ALTER TABLE requests 
ADD COLUMN IF NOT EXISTS leave_grant_required BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS contact_address TEXT;

-- Add Second Form - Leave Duty Station fields
ALTER TABLE requests 
ADD COLUMN IF NOT EXISTS reason_for_leaving TEXT,
ADD COLUMN IF NOT EXISTS travel_date DATE,
ADD COLUMN IF NOT EXISTS travel_place VARCHAR(255);

-- Add cost fields for Leave Duty Station
ALTER TABLE requests 
ADD COLUMN IF NOT EXISTS cost_accommodation NUMERIC(12, 2),
ADD COLUMN IF NOT EXISTS cost_breakfast NUMERIC(12, 2),
ADD COLUMN IF NOT EXISTS cost_lunch NUMERIC(12, 2),
ADD COLUMN IF NOT EXISTS cost_supper NUMERIC(12, 2),
ADD COLUMN IF NOT EXISTS cost_public_transport NUMERIC(12, 2),
ADD COLUMN IF NOT EXISTS cost_fuel_lubricants NUMERIC(12, 2),
ADD COLUMN IF NOT EXISTS cost_total NUMERIC(12, 2) DEFAULT 0.0;

-- Add comments to document the new columns
COMMENT ON COLUMN requests.leave_grant_required IS 'Whether the request requires a leave grant';
COMMENT ON COLUMN requests.contact_address IS 'Contact address during leave/trip';
COMMENT ON COLUMN requests.reason_for_leaving IS 'Reason for leaving duty station';
COMMENT ON COLUMN requests.travel_date IS 'Date of travel for duty station requests';
COMMENT ON COLUMN requests.travel_place IS 'Destination for duty station requests';
COMMENT ON COLUMN requests.cost_accommodation IS 'Cost of accommodation for duty station trips';
COMMENT ON COLUMN requests.cost_breakfast IS 'Cost of breakfast for duty station trips';
COMMENT ON COLUMN requests.cost_lunch IS 'Cost of lunch for duty station trips';
COMMENT ON COLUMN requests.cost_supper IS 'Cost of supper for duty station trips';
COMMENT ON COLUMN requests.cost_public_transport IS 'Cost of public transport for duty station trips';
COMMENT ON COLUMN requests.cost_fuel_lubricants IS 'Cost of fuel and lubricants for duty station trips';
COMMENT ON COLUMN requests.cost_total IS 'Total cost for duty station trips';
