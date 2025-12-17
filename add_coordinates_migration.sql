-- Migration to add latitude and longitude columns to bucket_list_items table
-- Run this in your Supabase SQL Editor

-- Add latitude and longitude columns
ALTER TABLE bucket_list_items 
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Add index for better query performance when filtering by coordinates
CREATE INDEX IF NOT EXISTS idx_bucket_list_items_coordinates 
ON bucket_list_items(latitude, longitude) 
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

