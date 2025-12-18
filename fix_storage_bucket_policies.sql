-- ============================================
-- FIX STORAGE BUCKET POLICIES FOR destination-images
-- ============================================
-- Run this in your Supabase SQL Editor to fix the Storage bucket RLS issue
-- This fixes the "new row violates row-level security policy" error during upload

-- IMPORTANT: Storage buckets have their own RLS policies separate from database tables
-- The error is happening during uploadBinary, which means Storage bucket policies are blocking it

-- 1. First, check if the bucket exists and is public
-- Go to Storage > destination-images > Settings and make sure "Public bucket" is enabled

-- 2. Create Storage policies for the destination-images bucket

-- Policy 1: Allow authenticated users to upload files
-- This allows users to upload files where the filename starts with their user ID
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;

CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'destination-images'
  AND (
    -- Allow if filename starts with user ID (format: userId/filename.jpg or userId_bucketItemId_timestamp.jpg)
    name LIKE auth.uid()::text || '%'
    OR
    -- Allow if filename is in a folder with user ID (format: userId/filename.jpg)
    (storage.foldername(name))[1] = auth.uid()::text
  )
);

-- Policy 2: Allow authenticated users to view their own files
DROP POLICY IF EXISTS "Authenticated users can view images" ON storage.objects;

CREATE POLICY "Authenticated users can view images"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'destination-images'
  AND (
    -- Allow if filename starts with user ID (format: userId/filename.jpg)
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    -- Allow if filename contains user ID (format: userId_bucketItemId_timestamp.jpg)
    name LIKE auth.uid()::text || '%'
  )
);

-- Policy 3: Allow authenticated users to delete their own files
DROP POLICY IF EXISTS "Authenticated users can delete images" ON storage.objects;

CREATE POLICY "Authenticated users can delete images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'destination-images'
  AND (
    -- Allow if filename starts with user ID (format: userId/filename.jpg)
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    -- Allow if filename contains user ID (format: userId_bucketItemId_timestamp.jpg)
    name LIKE auth.uid()::text || '%'
  )
);

-- Policy 4: Allow authenticated users to update their own files
DROP POLICY IF EXISTS "Authenticated users can update images" ON storage.objects;

CREATE POLICY "Authenticated users can update images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'destination-images'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR name LIKE auth.uid()::text || '%'
  )
)
WITH CHECK (
  bucket_id = 'destination-images'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR name LIKE auth.uid()::text || '%'
  )
);

-- If the bucket is public, also add public read access
-- This allows anyone to view images (for public bucket)
DROP POLICY IF EXISTS "Public can view images" ON storage.objects;

CREATE POLICY "Public can view images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'destination-images');

-- Verify the policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename = 'objects'
AND schemaname = 'storage'
AND policyname LIKE '%images%';
