-- ============================================
-- COMPLETE FIX FOR ALL POLICIES
-- ============================================
-- Run this in your Supabase SQL Editor
-- This will delete old policies and create new ones for both:
-- 1. Storage bucket (destination-images)
-- 2. Database table (destination_images)

-- ============================================
-- PART 1: FIX STORAGE BUCKET POLICIES
-- ============================================

-- Delete all existing Storage policies for destination-images bucket
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can view images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update images" ON storage.objects;
DROP POLICY IF EXISTS "Public can view images" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Users can view images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update images" ON storage.objects;

-- Create new Storage policies

-- Policy 1: Allow authenticated users to upload files
-- Format: userId_bucketItemId_timestamp.jpg
CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'destination-images'
  AND name LIKE auth.uid()::text || '%'
);

-- Policy 2: Allow authenticated users to view their own files
CREATE POLICY "Authenticated users can view images"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'destination-images'
  AND name LIKE auth.uid()::text || '%'
);

-- Policy 3: Allow authenticated users to delete their own files
CREATE POLICY "Authenticated users can delete images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'destination-images'
  AND name LIKE auth.uid()::text || '%'
);

-- Policy 4: Allow authenticated users to update their own files
CREATE POLICY "Authenticated users can update images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'destination-images'
  AND name LIKE auth.uid()::text || '%'
)
WITH CHECK (
  bucket_id = 'destination-images'
  AND name LIKE auth.uid()::text || '%'
);

-- Policy 5: Public read access (if bucket is public)
CREATE POLICY "Public can view images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'destination-images');

-- ============================================
-- PART 2: FIX DATABASE TABLE POLICIES
-- ============================================

-- Delete all existing policies for destination_images table
DROP POLICY IF EXISTS "Users can view own images" ON destination_images;
DROP POLICY IF EXISTS "Users can insert own images" ON destination_images;
DROP POLICY IF EXISTS "Users can delete own images" ON destination_images;
DROP POLICY IF EXISTS "Users can update own images" ON destination_images;

-- Create new database policies

-- Policy 1: Users can view their own images
CREATE POLICY "Users can view own images"
  ON destination_images FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bucket_list_items
      WHERE bucket_list_items.id = destination_images.bucket_item_id
      AND bucket_list_items.user_id = auth.uid()
    )
  );

-- Policy 2: Users can insert images for their own bucket_list_items
CREATE POLICY "Users can insert own images"
  ON destination_images FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM bucket_list_items
      WHERE bucket_list_items.id = destination_images.bucket_item_id
      AND bucket_list_items.user_id = auth.uid()
    )
  );

-- Policy 3: Users can update their own images
CREATE POLICY "Users can update own images"
  ON destination_images FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM bucket_list_items
      WHERE bucket_list_items.id = destination_images.bucket_item_id
      AND bucket_list_items.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM bucket_list_items
      WHERE bucket_list_items.id = destination_images.bucket_item_id
      AND bucket_list_items.user_id = auth.uid()
    )
  );

-- Policy 4: Users can delete their own images
CREATE POLICY "Users can delete own images"
  ON destination_images FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM bucket_list_items
      WHERE bucket_list_items.id = destination_images.bucket_item_id
      AND bucket_list_items.user_id = auth.uid()
    )
  );

-- ============================================
-- VERIFY POLICIES
-- ============================================

-- Check Storage policies
SELECT 
  'STORAGE' as type,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'objects'
AND schemaname = 'storage'
AND policyname LIKE '%images%'
ORDER BY policyname;

-- Check Database policies
SELECT 
  'DATABASE' as type,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename = 'destination_images'
ORDER BY policyname;
