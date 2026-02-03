-- Migration: Convert result_image_url to result_images array with active selection
-- Date: 2026-02-03
-- Description: Support multiple AI-generated result images with variant selection
-- Author: Claude AI

-- ============================================================================
-- STEP 1: Add new columns
-- ============================================================================

ALTER TABLE environments
  ADD COLUMN IF NOT EXISTS result_images JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS active_result_index INTEGER DEFAULT -1;

-- ============================================================================
-- STEP 2: Migrate existing data
-- ============================================================================
-- Convert single result_image_url to array format
-- Only migrate rows that have a result_image_url

UPDATE environments
SET
  result_images = jsonb_build_array(
    jsonb_build_object(
      'url', result_image_url,
      'storage_path', NULL,  -- Legacy data doesn't have storage path
      'created_at', updated_at,
      'generation_params', environment_specs,
      'model_version', NULL,
      'generation_id', NULL
    )
  ),
  active_result_index = 0
WHERE result_image_url IS NOT NULL;

-- ============================================================================
-- STEP 3: Drop old column
-- ============================================================================

ALTER TABLE environments DROP COLUMN IF EXISTS result_image_url;

-- ============================================================================
-- STEP 4: Add column comments
-- ============================================================================

COMMENT ON COLUMN environments.result_images IS
  'JSONB array of AI-generated result images with metadata. Structure: [{ url, storage_path, created_at, generation_params, model_version, generation_id }]';

COMMENT ON COLUMN environments.active_result_index IS
  'Index of active result image in result_images array. -1 indicates no active result (processing or no generation yet)';

-- ============================================================================
-- STEP 5: Add performance index
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_environments_active_result
  ON environments(active_result_index)
  WHERE active_result_index >= 0;

-- ============================================================================
-- VERIFICATION QUERIES (commented out - run manually to verify)
-- ============================================================================

-- Check migrated data
-- SELECT
--   id,
--   name,
--   jsonb_array_length(result_images) as variant_count,
--   active_result_index,
--   result_images
-- FROM environments
-- WHERE jsonb_array_length(result_images) > 0;

-- Check environments with no results
-- SELECT id, name, result_images, active_result_index
-- FROM environments
-- WHERE jsonb_array_length(result_images) = 0;

-- Verify JSONB structure
-- SELECT
--   id,
--   name,
--   result_images->0->>'url' as active_url,
--   result_images->0->>'created_at' as created_at
-- FROM environments
-- WHERE active_result_index = 0;
