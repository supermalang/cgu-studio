-- Migration 008: Add Environment Usage Tracking
-- Description: Adds FK constraint for project-environment relationship,
--              usage tracking columns, and RPC functions for statistics

-- ============================================================================
-- PART 1: Add Foreign Key Constraint for Projects → Environments
-- ============================================================================

-- Add FK constraint
ALTER TABLE projects
ADD CONSTRAINT fk_projects_environment
FOREIGN KEY (environment_id) REFERENCES environments(id) ON DELETE SET NULL;

-- Add index for performance
CREATE INDEX idx_projects_environment_id ON projects(environment_id);

COMMENT ON CONSTRAINT fk_projects_environment ON projects IS 'Links project to its associated environment';

-- ============================================================================
-- PART 2: Add Usage Tracking Columns to Environments Table
-- ============================================================================

-- Add tracking columns
ALTER TABLE environments
ADD COLUMN view_count INTEGER NOT NULL DEFAULT 0,
ADD COLUMN last_viewed_at TIMESTAMPTZ,
ADD COLUMN regeneration_count INTEGER NOT NULL DEFAULT 0,
ADD COLUMN last_regenerated_at TIMESTAMPTZ;

-- Add index for stats queries
CREATE INDEX idx_environments_usage_stats ON environments(view_count, regeneration_count);

-- Add comments
COMMENT ON COLUMN environments.view_count IS 'Number of times environment detail page was viewed';
COMMENT ON COLUMN environments.last_viewed_at IS 'Timestamp of most recent view';
COMMENT ON COLUMN environments.regeneration_count IS 'Number of times "Try Again" was clicked to regenerate';
COMMENT ON COLUMN environments.last_regenerated_at IS 'Timestamp of most recent regeneration request';

-- ============================================================================
-- PART 3: RPC Function - Get Projects Using Environment
-- ============================================================================

CREATE OR REPLACE FUNCTION get_projects_by_environment(env_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  status project_status,
  total_shots INTEGER,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) AS $$
BEGIN
  -- Return projects that reference this environment
  RETURN QUERY
  SELECT
    p.id,
    p.name,
    p.status,
    p.total_shots,
    p.created_at,
    p.updated_at
  FROM projects p
  WHERE p.environment_id = env_id
  AND p.user_id = auth.uid()
  ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_projects_by_environment(UUID) IS 'Returns all projects using the specified environment for current user';

-- ============================================================================
-- PART 4: RPC Function - Get Environment Usage Statistics
-- ============================================================================

CREATE OR REPLACE FUNCTION get_environment_usage_stats(env_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_project_count INTEGER;
  v_variant_count INTEGER;
  v_regeneration_count INTEGER;
  v_view_count INTEGER;
  v_last_viewed TIMESTAMPTZ;
  v_last_regenerated TIMESTAMPTZ;
  v_first_generated TIMESTAMPTZ;
  v_days_since_creation NUMERIC;
BEGIN
  -- Verify user owns this environment
  IF NOT EXISTS (
    SELECT 1 FROM environments
    WHERE id = env_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Environment not found or access denied';
  END IF;

  -- Get basic stats from environments table
  SELECT
    view_count,
    last_viewed_at,
    regeneration_count,
    last_regenerated_at
  INTO v_view_count, v_last_viewed, v_regeneration_count, v_last_regenerated
  FROM environments
  WHERE id = env_id;

  -- Count projects using this environment
  SELECT COUNT(*) INTO v_project_count
  FROM projects
  WHERE environment_id = env_id
  AND user_id = auth.uid();

  -- Get variant count from result_images JSONB array
  SELECT
    COALESCE(jsonb_array_length(result_images), 0)
  INTO v_variant_count
  FROM environments
  WHERE id = env_id;

  -- Get first generation timestamp (earliest variant in result_images)
  SELECT
    MIN((elem->>'created_at')::TIMESTAMPTZ)
  INTO v_first_generated
  FROM environments, jsonb_array_elements(result_images) elem
  WHERE id = env_id;

  -- Calculate days since creation
  IF v_first_generated IS NOT NULL THEN
    v_days_since_creation := EXTRACT(DAY FROM NOW() - v_first_generated);
  ELSE
    v_days_since_creation := 0;
  END IF;

  -- Build result object
  v_result := jsonb_build_object(
    'project_count', COALESCE(v_project_count, 0),
    'variant_count', COALESCE(v_variant_count, 0),
    'regeneration_count', COALESCE(v_regeneration_count, 0),
    'view_count', COALESCE(v_view_count, 0),
    'last_viewed_at', v_last_viewed,
    'last_regenerated_at', v_last_regenerated,
    'first_generated_at', v_first_generated,
    'days_since_creation', v_days_since_creation
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_environment_usage_stats(UUID) IS 'Returns comprehensive usage statistics for an environment';

-- ============================================================================
-- PART 5: RPC Function - Track Environment View
-- ============================================================================

CREATE OR REPLACE FUNCTION track_environment_view(env_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_new_count INTEGER;
BEGIN
  -- Increment view count and update last viewed timestamp
  UPDATE environments
  SET
    view_count = view_count + 1,
    last_viewed_at = NOW(),
    updated_at = NOW(),
    updated_by = auth.uid()
  WHERE id = env_id
  AND user_id = auth.uid()
  RETURNING view_count INTO v_new_count;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Environment not found or access denied';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'environment_id', env_id,
    'view_count', v_new_count,
    'timestamp', NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION track_environment_view(UUID) IS 'Increments view count and updates last viewed timestamp';

-- ============================================================================
-- PART 6: RPC Function - Track Environment Regeneration
-- ============================================================================

CREATE OR REPLACE FUNCTION track_environment_regeneration(env_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_new_count INTEGER;
BEGIN
  -- Increment regeneration count and update last regenerated timestamp
  UPDATE environments
  SET
    regeneration_count = regeneration_count + 1,
    last_regenerated_at = NOW(),
    updated_at = NOW(),
    updated_by = auth.uid()
  WHERE id = env_id
  AND user_id = auth.uid()
  RETURNING regeneration_count INTO v_new_count;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Environment not found or access denied';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'environment_id', env_id,
    'regeneration_count', v_new_count,
    'timestamp', NOW()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION track_environment_regeneration(UUID) IS 'Increments regeneration count and updates last regenerated timestamp';

-- ============================================================================
-- PART 7: Grant Permissions
-- ============================================================================

-- Grant execute permissions on RPC functions to authenticated users
GRANT EXECUTE ON FUNCTION get_projects_by_environment(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_environment_usage_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION track_environment_view(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION track_environment_regeneration(UUID) TO authenticated;

-- ============================================================================
-- Migration Complete
-- ============================================================================
