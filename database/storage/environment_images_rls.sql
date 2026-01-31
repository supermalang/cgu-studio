-- Row Level Security (RLS) Policies for Environments bucket
-- Date: 2026-01-23
-- Description: Ensures users can only access their own environment images, with admin override

-- Policy 1: Users can upload images to their own folder
CREATE POLICY "Users can upload own environment images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'Environments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 2: Users can read/view their own images
CREATE POLICY "Users can read own environment images"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'Environments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 3: Users can update their own images (e.g., replace with new version)
CREATE POLICY "Users can update own environment images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'Environments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 4: Users can delete their own images
CREATE POLICY "Users can delete own environment images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'Environments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 5: Admins can access all images (for moderation and support)
CREATE POLICY "Admins can access all environment images"
ON storage.objects FOR ALL
TO authenticated
USING (
  bucket_id = 'Environments' AND
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- Security Notes:
-- - User-specific folders ({user_id}/) prevent filename collisions
-- - RLS ensures complete data isolation between users
-- - Admins have full access for moderation and support purposes
-- - File size (5MB) and MIME type restrictions enforced at bucket level
