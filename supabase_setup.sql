-- ============================================
-- SUPABASE SETUP SQL FOR TRAVEL BUCKET LIST APP
-- ============================================
-- Run this in your Supabase SQL Editor

-- 1. Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  username TEXT NOT NULL,
  email TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create countries table
CREATE TABLE IF NOT EXISTS countries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

-- 3. Create bucket_list_items table
CREATE TABLE IF NOT EXISTS bucket_list_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  country_id UUID REFERENCES countries(id) ON DELETE CASCADE,
  is_visited BOOLEAN DEFAULT FALSE,
  note TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create destination_images table
CREATE TABLE IF NOT EXISTS destination_images (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  bucket_item_id UUID REFERENCES bucket_list_items(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL
);

-- 5. Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bucket_list_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE destination_images ENABLE ROW LEVEL SECURITY;

-- 6. Create function to automatically create profile on user signup
-- This is the RECOMMENDED approach - it automatically creates a profile
-- when a user signs up, so you don't need to insert from the app
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, email, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
    NEW.email,
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create trigger to call the function when a new user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 8. RLS Policies for profiles
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- Users can insert their own profile (backup policy if trigger doesn't work)
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- 9. RLS Policies for bucket_list_items
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own bucket items" ON bucket_list_items;
DROP POLICY IF EXISTS "Users can insert own bucket items" ON bucket_list_items;
DROP POLICY IF EXISTS "Users can update own bucket items" ON bucket_list_items;
DROP POLICY IF EXISTS "Users can delete own bucket items" ON bucket_list_items;

CREATE POLICY "Users can view own bucket items"
  ON bucket_list_items FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own bucket items"
  ON bucket_list_items FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own bucket items"
  ON bucket_list_items FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own bucket items"
  ON bucket_list_items FOR DELETE
  USING (auth.uid() = user_id);

-- 10. RLS Policies for destination_images
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own images" ON destination_images;
DROP POLICY IF EXISTS "Users can insert own images" ON destination_images;
DROP POLICY IF EXISTS "Users can delete own images" ON destination_images;

CREATE POLICY "Users can view own images"
  ON destination_images FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bucket_list_items
      WHERE bucket_list_items.id = destination_images.bucket_item_id
      AND bucket_list_items.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own images"
  ON destination_images FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM bucket_list_items
      WHERE bucket_list_items.id = destination_images.bucket_item_id
      AND bucket_list_items.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own images"
  ON destination_images FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM bucket_list_items
      WHERE bucket_list_items.id = destination_images.bucket_item_id
      AND bucket_list_items.user_id = auth.uid()
    )
  );

-- 11. Allow public read access to countries (so users can see available countries)
ALTER TABLE countries ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view countries" ON countries;
DROP POLICY IF EXISTS "Authenticated users can add countries" ON countries;

CREATE POLICY "Anyone can view countries"
  ON countries FOR SELECT
  TO authenticated
  USING (true);

-- Optional: Allow authenticated users to add new countries
CREATE POLICY "Authenticated users can add countries"
  ON countries FOR INSERT
  TO authenticated
  WITH CHECK (true);

