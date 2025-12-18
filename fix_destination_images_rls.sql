-- ============================================
-- FIX RLS POLICIES FOR destination_images TABLE
-- ============================================
-- Run this in your Supabase SQL Editor to fix the RLS policy issue
-- This will fix the "new row violates row level security policy" error

-- IMPORTANT: Make sure you're authenticated as a user with proper permissions
-- Run this as the postgres role or a superuser

-- First, drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own images" ON destination_images;
DROP POLICY IF EXISTS "Users can insert own images" ON destination_images;
DROP POLICY IF EXISTS "Users can delete own images" ON destination_images;
DROP POLICY IF EXISTS "Users can update own images" ON destination_images;

-- Policy 1: Users can view their own images
-- (images linked to their bucket_list_items)
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
-- This is the critical one that was failing
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

-- Verify the policies are created
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = 'destination_images';
