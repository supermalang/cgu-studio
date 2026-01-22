-- ============================================================================
-- FIX: Infinite Recursion in Admin RLS Policies
-- ============================================================================
-- This migration fixes the infinite recursion error that occurs when admin
-- users query tables with RLS policies that check the profiles table.
--
-- PROBLEM: Admin RLS policies use EXISTS (SELECT FROM profiles WHERE role = 'admin')
-- which triggers RLS on the profiles table, causing infinite recursion.
--
-- SOLUTION: Create a SECURITY DEFINER function that bypasses RLS to check
-- if the current user is an admin, then use this function in all admin policies.
--
-- USAGE: Run this script in Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- STEP 1: Create helper function to check admin status (bypasses RLS)
-- ============================================================================

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- SECURITY DEFINER allows this function to bypass RLS policies
  -- This prevents infinite recursion when checking admin status
  RETURN EXISTS (
    SELECT 1
    FROM profiles
    WHERE id = auth.uid()
    AND role = 'admin'
  );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION is_admin() TO authenticated;

-- ============================================================================
-- STEP 2: Drop existing admin policies that cause recursion
-- ============================================================================

-- Profiles table
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;

-- Admin settings table
DROP POLICY IF EXISTS "Only admins can update admin settings" ON admin_settings;

-- Projects table
DROP POLICY IF EXISTS "Admins can view all projects" ON projects;
DROP POLICY IF EXISTS "Admins can update all projects" ON projects;

-- Shots table
DROP POLICY IF EXISTS "Admins can view all shots" ON shots;

-- Credit transactions table
DROP POLICY IF EXISTS "Admins can view all transactions" ON credit_transactions;

-- Payment transactions table
DROP POLICY IF EXISTS "Admins can view all payments" ON payment_transactions;

-- Exports table
DROP POLICY IF EXISTS "Admins can view all exports" ON exports;

-- N8N jobs table
DROP POLICY IF EXISTS "Admins can view all jobs" ON n8n_jobs;

-- Avatars table
DROP POLICY IF EXISTS "Admins can view all avatars" ON avatars;

-- Environments table
DROP POLICY IF EXISTS "Admins can view all environments" ON environments;

-- ============================================================================
-- STEP 3: Recreate admin policies using the is_admin() function
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PROFILES TABLE
-- ----------------------------------------------------------------------------

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles"
ON profiles FOR SELECT
USING (is_admin());

-- Admins can update all profiles
CREATE POLICY "Admins can update all profiles"
ON profiles FOR UPDATE
USING (is_admin());

-- ----------------------------------------------------------------------------
-- ADMIN SETTINGS TABLE
-- ----------------------------------------------------------------------------

-- Only admins can update admin settings
CREATE POLICY "Only admins can update admin settings"
ON admin_settings FOR UPDATE
USING (is_admin());

-- ----------------------------------------------------------------------------
-- PROJECTS TABLE
-- ----------------------------------------------------------------------------

-- Admins can view all projects
CREATE POLICY "Admins can view all projects"
ON projects FOR SELECT
USING (is_admin());

-- Admins can update all projects
CREATE POLICY "Admins can update all projects"
ON projects FOR UPDATE
USING (is_admin());

-- ----------------------------------------------------------------------------
-- SHOTS TABLE
-- ----------------------------------------------------------------------------

-- Admins can view all shots
CREATE POLICY "Admins can view all shots"
ON shots FOR SELECT
USING (is_admin());

-- ----------------------------------------------------------------------------
-- CREDIT TRANSACTIONS TABLE
-- ----------------------------------------------------------------------------

-- Admins can view all transactions
CREATE POLICY "Admins can view all transactions"
ON credit_transactions FOR SELECT
USING (is_admin());

-- ----------------------------------------------------------------------------
-- PAYMENT TRANSACTIONS TABLE
-- ----------------------------------------------------------------------------

-- Admins can view all payments
CREATE POLICY "Admins can view all payments"
ON payment_transactions FOR SELECT
USING (is_admin());

-- ----------------------------------------------------------------------------
-- EXPORTS TABLE
-- ----------------------------------------------------------------------------

-- Admins can view all exports
CREATE POLICY "Admins can view all exports"
ON exports FOR SELECT
USING (is_admin());

-- ----------------------------------------------------------------------------
-- N8N JOBS TABLE
-- ----------------------------------------------------------------------------

-- Admins can view all jobs
CREATE POLICY "Admins can view all jobs"
ON n8n_jobs FOR SELECT
USING (is_admin());

-- ----------------------------------------------------------------------------
-- AVATARS TABLE
-- ----------------------------------------------------------------------------

-- Admins can view all avatars
CREATE POLICY "Admins can view all avatars"
ON avatars FOR SELECT
USING (is_admin());

-- ----------------------------------------------------------------------------
-- ENVIRONMENTS TABLE
-- ----------------------------------------------------------------------------

-- Admins can view all environments
CREATE POLICY "Admins can view all environments"
ON environments FOR SELECT
USING (is_admin());

-- ============================================================================
-- STEP 4: Verify the fix
-- ============================================================================

-- Test the is_admin() function
-- Run as admin: should return true
-- Run as regular user: should return false
SELECT is_admin() AS am_i_admin;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
