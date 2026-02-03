-- Migration: Add result_image_url to environments table
-- Date: 2026-02-02
-- Description: Adds result image support to environments for before/after comparison

-- Add result_image_url column to environments table
ALTER TABLE environments ADD COLUMN result_image_url TEXT;

-- Add comments for clarity on both image fields
COMMENT ON COLUMN environments.result_image_url IS 'URL to AI-generated result image (after), stored in Environments bucket';
COMMENT ON COLUMN environments.reference_image_url IS 'URL to user-uploaded reference image (before), stored in Environments bucket';
