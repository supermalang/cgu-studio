-- Migration: Clean up duplicate variants in result_images
-- Date: 2026-02-03
-- Description: Fix environments with too many variants by keeping only the most recent 5
-- Author: Claude AI

-- ============================================================================
-- STEP 1: Backup current state (optional - comment out if not needed)
-- ============================================================================
-- CREATE TABLE IF NOT EXISTS environments_backup_20260203 AS
-- SELECT * FROM environments WHERE jsonb_array_length(result_images) > 10;

-- ============================================================================
-- STEP 2: Clean up environments with excessive variants
-- ============================================================================

-- For environments with more than 5 variants, keep only the most recent 5
UPDATE environments
SET
  result_images = (
    -- Get the last 5 items from the array
    SELECT jsonb_agg(elem ORDER BY (elem->>'created_at') DESC)
    FROM (
      SELECT elem, row_number() OVER (ORDER BY (elem->>'created_at') DESC) as rn
      FROM jsonb_array_elements(result_images) elem
    ) sub
    WHERE rn <= 5
  ),
  active_result_index = CASE
    WHEN active_result_index >= 0 THEN 0  -- Set to first (most recent) variant
    ELSE -1  -- Keep -1 if no active variant
  END,
  updated_at = now()
WHERE jsonb_array_length(result_images) > 5;

-- ============================================================================
-- STEP 3: Report on cleaned environments
-- ============================================================================

-- Show environments that were cleaned
SELECT
  id,
  name,
  jsonb_array_length(result_images) as variant_count,
  active_result_index,
  updated_at
FROM environments
WHERE updated_at > now() - interval '5 minutes'
  AND jsonb_array_length(result_images) <= 5
ORDER BY updated_at DESC;

-- ============================================================================
-- VERIFICATION QUERIES (run to check results)
-- ============================================================================

-- Check all environments variant counts
-- SELECT
--   id,
--   name,
--   jsonb_array_length(result_images) as variant_count,
--   active_result_index
-- FROM environments
-- ORDER BY variant_count DESC;

-- Check for any environments still with excessive variants
-- SELECT COUNT(*) as environments_with_excessive_variants
-- FROM environments
-- WHERE jsonb_array_length(result_images) > 10;
