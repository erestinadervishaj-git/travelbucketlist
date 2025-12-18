# Supabase Storage Setup Guide

## Fix "Failed to load" Images in Gallery

If you're seeing "Failed to load" messages for images in the gallery, it's likely because the storage bucket is not configured correctly.

### Steps to Fix:

1. **Go to Supabase Dashboard**
   - Navigate to your Supabase project
   - Click on "Storage" in the left sidebar

2. **Create the `destination-images` Bucket (with hyphen, not underscore)**
   - **IMPORTANT**: The bucket name must be exactly `destination-images` (with a hyphen `-`, not underscore `_`)
   - If you have a bucket with a different name, you can either:
     - **Option A (Recommended)**: Create a new bucket with the correct name `destination-images`
     - **Option B**: Delete the old bucket and create a new one with the correct name
   
   - To create the bucket:
     - Click "New bucket" or the "+" button
     - Name: `destination-images` (exactly this, with hyphen)
     - **IMPORTANT**: Check "Public bucket" checkbox
     - Click "Create bucket"
   
   - If the bucket already exists but has wrong settings:
     - Click on the `destination-images` bucket
     - Go to "Settings" tab
     - Under "Public bucket", toggle it to **ON** (enabled)
     - Save changes

3. **Set Up Storage Policies (if needed)**
   - Go to "Policies" tab for the `destination-images` bucket
   - Ensure there's a policy that allows public read access:
   
   ```sql
   -- Allow public read access
   CREATE POLICY "Public Access"
   ON storage.objects FOR SELECT
   USING (bucket_id = 'destination-images');
   ```

4. **Verify the Fix**
   - Restart your Flutter app
   - Try viewing the gallery again
   - Images should now load properly

### Alternative: Using Signed URLs

If you prefer to keep the bucket private for security, the app will automatically generate signed URLs. However, making the bucket public is simpler and recommended for this use case.

### Troubleshooting

- **Check console logs**: Look for messages starting with "Gallery:" to see what URLs are being used
- **Verify bucket name**: Make sure it's exactly `destination-images` (with hyphen, not underscore)
- **Check file permissions**: Ensure uploaded files have correct permissions
