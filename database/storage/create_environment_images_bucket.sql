-- Update storage bucket configuration for Environments bucket
-- Date: 2026-01-23
-- Description: Updates the existing Environments bucket with size and MIME type restrictions for environment images

-- Note: Using existing "Environments" bucket in Supabase
-- Update the Environments bucket configuration if needed
UPDATE storage.buckets
SET
  file_size_limit = 5242880, -- 5MB limit (5 * 1024 * 1024 bytes)
  allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
WHERE id = 'Environments';

-- Storage Path Structure:
-- Environments/{user_id}/environment_{timestamp}_{random}.{ext}
--
-- Example:
-- Environments/550e8400-e29b-41d4-a716-446655440000/environment_1706000000000_a3f9c.jpg
