-- Add missing entity column to audit_logs table
-- The model expects 'entity' column but the database has 'entity_type' and 'entity_id'

-- Add the entity column to match the SQLAlchemy model
ALTER TABLE audit_logs ADD COLUMN entity character varying(100);

-- Also add details column if it doesn't exist (for JSONB data)
ALTER TABLE audit_logs ADD COLUMN details jsonb;

-- Add timestamp column if it doesn't exist (the model expects this)
ALTER TABLE audit_logs ADD COLUMN timestamp timestamp with time zone;

-- Update existing records to populate entity from entity_type if needed
UPDATE audit_logs SET entity = entity_type WHERE entity IS NULL AND entity_type IS NOT NULL;
