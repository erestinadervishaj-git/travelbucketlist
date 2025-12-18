-- ============================================
-- REMOVE local_recommendations TABLE SAFELY
-- ============================================
-- Run this in your Supabase SQL Editor
-- This will safely remove the local_recommendations table without breaking anything
-- 
-- WHY IT'S SAFE:
-- - No other tables reference local_recommendations.id (no foreign keys pointing to it)
-- - The table only has foreign keys TO other tables (bucket_item_id, user_id)
-- - Removing it won't break any referential integrity constraints

-- Step 1: Drop all RLS policies for local_recommendations (if they exist)
DROP POLICY IF EXISTS "Users can view own recommendations" ON local_recommendations;
DROP POLICY IF EXISTS "Users can insert own recommendations" ON local_recommendations;
DROP POLICY IF EXISTS "Users can update own recommendations" ON local_recommendations;
DROP POLICY IF EXISTS "Users can delete own recommendations" ON local_recommendations;
DROP POLICY IF EXISTS "Authenticated users can view recommendations" ON local_recommendations;
DROP POLICY IF EXISTS "Authenticated users can insert recommendations" ON local_recommendations;
DROP POLICY IF EXISTS "Authenticated users can update recommendations" ON local_recommendations;
DROP POLICY IF EXISTS "Authenticated users can delete recommendations" ON local_recommendations;

-- Step 2: Disable RLS on the table (required before dropping)
ALTER TABLE IF EXISTS local_recommendations DISABLE ROW LEVEL SECURITY;

-- Step 3: Drop the table
-- CASCADE will also drop any dependent objects (like indexes, triggers, etc.)
-- This is safe because no other tables reference this table
DROP TABLE IF EXISTS local_recommendations CASCADE;

-- Verification: Check that the table is gone
-- This query should return 0 rows if the table was successfully dropped
SELECT 
  'Table still exists!' as status,
  table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'local_recommendations';

-- If the above returns 0 rows, the table has been successfully removed
