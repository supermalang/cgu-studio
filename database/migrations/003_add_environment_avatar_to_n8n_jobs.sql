-- Migration: Add environment_id and avatar_id to n8n_jobs
-- Version: 1.1.0
-- Date: 2026-01-23
-- Description: Adds foreign key columns for environments and avatars to support job tracking

BEGIN;

-- Add new columns to n8n_jobs table
ALTER TABLE n8n_jobs
ADD COLUMN environment_id UUID REFERENCES environments(id) ON DELETE SET NULL,
ADD COLUMN avatar_id UUID REFERENCES avatars(id) ON DELETE SET NULL;

-- Create indexes for performance optimization
CREATE INDEX idx_n8n_jobs_environment_id ON n8n_jobs(environment_id);
CREATE INDEX idx_n8n_jobs_avatar_id ON n8n_jobs(avatar_id);

-- Add composite index for common query: "get pending/generating jobs for current user"
CREATE INDEX idx_n8n_jobs_user_status ON n8n_jobs(user_id, status);

-- Add column comments for documentation
COMMENT ON COLUMN n8n_jobs.environment_id IS 'References environment for environment generation jobs';
COMMENT ON COLUMN n8n_jobs.avatar_id IS 'References avatar for avatar generation jobs';

COMMIT;
