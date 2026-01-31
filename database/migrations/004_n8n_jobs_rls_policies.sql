-- Migration: Add RLS policies for n8n_jobs table
-- Version: 1.2.0
-- Date: 2026-01-24
-- Description: Adds Row Level Security policies to allow users to manage their own jobs

BEGIN;

-- Enable RLS on n8n_jobs table (if not already enabled)
ALTER TABLE n8n_jobs ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can insert their own jobs
CREATE POLICY "Users can create own jobs"
ON n8n_jobs FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid()
);

-- Policy 2: Users can view their own jobs
CREATE POLICY "Users can view own jobs"
ON n8n_jobs FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
);

-- Policy 3: Users can update their own jobs
CREATE POLICY "Users can update own jobs"
ON n8n_jobs FOR UPDATE
TO authenticated
USING (
  user_id = auth.uid()
);

-- Policy 4: n8n can update jobs via service role (for status updates from n8n workflows)
-- Note: This assumes n8n uses service_role key for authentication
CREATE POLICY "Service role can update all jobs"
ON n8n_jobs FOR UPDATE
TO service_role
USING (true);

-- Policy 5: Admins can view all jobs (for monitoring and support)
CREATE POLICY "Admins can view all jobs"
ON n8n_jobs FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Policy 6: Admins can update all jobs
CREATE POLICY "Admins can update all jobs"
ON n8n_jobs FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);

COMMIT;

-- Notes:
-- - Users can only insert/view/update their own jobs
-- - n8n workflows should use service_role key to update job status
-- - Admins have full read/update access for monitoring
-- - Users cannot delete jobs (preserve history)
