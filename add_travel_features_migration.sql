-- ============================================
-- TRAVEL FEATURES MIGRATION
-- Adds support for local recommendations, reviews, and enhanced features
-- ============================================
-- Run this in your Supabase SQL Editor

-- 1. Create local_recommendations table
CREATE TABLE IF NOT EXISTS local_recommendations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  bucket_item_id UUID REFERENCES bucket_list_items(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  must_try_foods TEXT[],
  restaurants TEXT,
  local_tips TEXT,
  language_phrases JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Add enhanced review fields to bucket_list_items (if not already exists)
-- First check if columns exist, if not add them
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='bucket_list_items' AND column_name='pros') THEN
    ALTER TABLE bucket_list_items ADD COLUMN pros TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='bucket_list_items' AND column_name='cons') THEN
    ALTER TABLE bucket_list_items ADD COLUMN cons TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='bucket_list_items' AND column_name='best_time_to_visit') THEN
    ALTER TABLE bucket_list_items ADD COLUMN best_time_to_visit TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='bucket_list_items' AND column_name='would_visit_again') THEN
    ALTER TABLE bucket_list_items ADD COLUMN would_visit_again BOOLEAN;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name='bucket_list_items' AND column_name='rating') THEN
    ALTER TABLE bucket_list_items ADD COLUMN rating INTEGER;
  END IF;
END $$;

-- 3. Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_local_recommendations_bucket_item 
  ON local_recommendations(bucket_item_id);
CREATE INDEX IF NOT EXISTS idx_local_recommendations_user 
  ON local_recommendations(user_id);

-- 4. Enable Row Level Security for local_recommendations
ALTER TABLE local_recommendations ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS policies for local_recommendations
CREATE POLICY "Users can view their own recommendations"
  ON local_recommendations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own recommendations"
  ON local_recommendations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own recommendations"
  ON local_recommendations FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own recommendations"
  ON local_recommendations FOR DELETE
  USING (auth.uid() = user_id);

-- 6. Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Create trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_local_recommendations_updated_at ON local_recommendations;
CREATE TRIGGER update_local_recommendations_updated_at
  BEFORE UPDATE ON local_recommendations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

