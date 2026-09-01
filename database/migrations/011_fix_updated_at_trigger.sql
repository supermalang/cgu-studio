-- Migration 011: Fix the shared updated_at trigger
-- Version: 2.0.1
-- Date: 2026-08-31
-- Description: Fixes two pre-existing bugs in update_updated_at_column().
--
--   1. It assigns NEW.updated_by unconditionally, so ANY update to a table
--      without that column raises 'record "new" has no field "updated_by"'.
--      n8n_jobs has no updated_by — every job status update was failing.
--
--   2. It assigns auth.uid(), which is NULL for service_role. n8n writing a
--      generated result back to environments/avatars/projects therefore hit
--      'null value in column "updated_by" violates not-null constraint'.
--
-- The fix splits the behaviour in two: a timestamp-only trigger for tables
-- with no audit columns, and an audit trigger that keeps the previous editor
-- when the writer is a service role rather than a person.

BEGIN;

-- ----------------------------------------------------------------------------
-- Timestamp only — safe on every table with an updated_at column.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column() IS 'Stamps updated_at. Use set_updated_audit_columns() for tables that also have updated_by.';

-- ----------------------------------------------------------------------------
-- Timestamp + audit, for tables carrying updated_by.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_audit_columns()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  -- COALESCE, not a bare assignment: a service_role write (n8n) has no
  -- auth.uid(), and overwriting with NULL breaks the NOT NULL audit column.
  -- Keeping the incoming value preserves the last human editor.
  NEW.updated_by = COALESCE(auth.uid(), NEW.updated_by);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION set_updated_audit_columns() IS 'Stamps updated_at and updated_by, preserving the previous editor on service-role writes';

-- ----------------------------------------------------------------------------
-- Point each trigger at the right function.
-- ----------------------------------------------------------------------------

-- Tables with audit columns
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_audit_columns();

DROP TRIGGER IF EXISTS update_admin_settings_updated_at ON admin_settings;
CREATE TRIGGER update_admin_settings_updated_at BEFORE UPDATE ON admin_settings
  FOR EACH ROW EXECUTE FUNCTION set_updated_audit_columns();

DROP TRIGGER IF EXISTS update_projects_updated_at ON projects;
CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION set_updated_audit_columns();

DROP TRIGGER IF EXISTS update_shots_updated_at ON shots;
CREATE TRIGGER update_shots_updated_at BEFORE UPDATE ON shots
  FOR EACH ROW EXECUTE FUNCTION set_updated_audit_columns();

DROP TRIGGER IF EXISTS update_avatars_updated_at ON avatars;
CREATE TRIGGER update_avatars_updated_at BEFORE UPDATE ON avatars
  FOR EACH ROW EXECUTE FUNCTION set_updated_audit_columns();

DROP TRIGGER IF EXISTS update_environments_updated_at ON environments;
CREATE TRIGGER update_environments_updated_at BEFORE UPDATE ON environments
  FOR EACH ROW EXECUTE FUNCTION set_updated_audit_columns();

DROP TRIGGER IF EXISTS update_social_accounts_updated_at ON social_accounts;
CREATE TRIGGER update_social_accounts_updated_at BEFORE UPDATE ON social_accounts
  FOR EACH ROW EXECUTE FUNCTION set_updated_audit_columns();

DROP TRIGGER IF EXISTS update_posts_updated_at ON posts;
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION set_updated_audit_columns();

-- Tables with no updated_by keep the timestamp-only trigger, which is now
-- actually safe for them (n8n_jobs, post_variants, post_media).

COMMIT;
