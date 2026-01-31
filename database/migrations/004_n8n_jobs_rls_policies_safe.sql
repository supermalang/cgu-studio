-- Migration: Add RLS policies for n8n_jobs table (Safe version)
-- Version: 1.2.0
-- Date: 2026-01-24
-- Description: Safely adds Row Level Security policies, dropping existing ones first if they exist

BEGIN;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can create own jobs" ON n8n_jobs;
DROP POLICY IF EXISTS "Users can view own jobs" ON n8n_jobs;
DROP POLICY IF EXISTS "Users can update own jobs" ON n8n_jobs;
DROP POLICY IF EXISTS "Service role can update all jobs" ON n8n_jobs;
DROP POLICY IF EXISTS "Admins can view all jobs" ON n8n_jobs;
DROP POLICY IF EXISTS "Admins can update all jobs" ON n8n_jobs;

-- Enable RLS on n8n_jobs table
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

-- Verification query:
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
-- FROM pg_policies
-- WHERE tablename = 'n8n_jobs';
