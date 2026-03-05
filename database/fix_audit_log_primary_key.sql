-- Fix audit_logs table primary key column name
-- Change audit_log_id to audit_id to match the model

-- Drop the primary key constraint
ALTER TABLE audit_logs DROP CONSTRAINT audit_logs_pkey;

-- Rename the column
ALTER TABLE audit_logs RENAME COLUMN audit_log_id TO audit_id;

-- Add the primary key constraint back
ALTER TABLE audit_logs ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (audit_id);
