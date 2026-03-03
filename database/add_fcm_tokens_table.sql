-- Migration: Create user_fcm_tokens table for push notifications

CREATE TABLE IF NOT EXISTS user_fcm_tokens (
    token_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL UNIQUE,
    device_id VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Add index for user_id to speed up lookups
CREATE INDEX IF NOT EXISTS idx_user_fcm_tokens_user_id ON user_fcm_tokens(user_id);

-- Note: The SQLAlchemy models have been updated to include the UserFCMToken class
-- and the relationship with the User class.
