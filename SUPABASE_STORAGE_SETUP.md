# Supabase Storage Setup Guide

Complete step-by-step guide to set up image storage for the FlaRide Driver app.

---

## Step 1: Access Supabase Dashboard

1. Go to [https://supabase.com](https://supabase.com)
2. Sign in to your account
3. Select your **FlaRide** project

---

## Step 2: Create Storage Buckets

### Navigate to Storage
1. In the left sidebar, click **Storage**
2. Click **New bucket** button

### Create Bucket 1: `driver-photos` (Public)
```
Name: driver-photos
Public bucket: ✅ ON (checked)
File size limit: 5 MB
Allowed MIME types: image/jpeg, image/png, image/webp
```
Click **Create bucket**

### Create Bucket 2: `driver-documents` (Private)
```
Name: driver-documents
Public bucket: ❌ OFF (unchecked)
File size limit: 10 MB
Allowed MIME types: image/jpeg, image/png, image/webp, application/pdf
```
Click **Create bucket**

### Create Bucket 3: `delivery-photos` (Private)
```
Name: delivery-photos
Public bucket: ❌ OFF (unchecked)
File size limit: 5 MB
Allowed MIME types: image/jpeg, image/png, image/webp
```
Click **Create bucket**

---

## Step 3: Set Up Storage Policies

### Navigate to Policies
1. Click on the bucket name (e.g., `driver-photos`)
2. Click the **Policies** tab
3. Click **New policy**

### Policy for `driver-photos` (Public Read, Authenticated Write)

**Policy 1: Public Read**
```
Policy name: Allow public read
Allowed operation: SELECT
Target roles: (leave empty for all)
```
Click **Use this template** → **For full customization**

In the policy definition:
```sql
true
```

**Policy 2: Authenticated Upload**
```
Policy name: Authenticated users can upload
Allowed operation: INSERT
Target roles: authenticated
```
Policy definition:
```sql
true
```

**Policy 3: Users can update their own photos**
```
Policy name: Users can update own photos
Allowed operation: UPDATE
Target roles: authenticated
```
Policy definition:
```sql
(bucket_id = 'driver-photos' AND auth.uid()::text = (storage.foldername(name))[1])
```

### Policy for `driver-documents` (Private - Owner Only)

**Policy 1: Upload own documents**
```sql
-- INSERT policy
(bucket_id = 'driver-documents' AND auth.uid()::text = (storage.foldername(name))[1])
```

**Policy 2: View own documents**
```sql
-- SELECT policy
(bucket_id = 'driver-documents' AND auth.uid()::text = (storage.foldername(name))[1])
```

**Policy 3: Update own documents**
```sql
-- UPDATE policy
(bucket_id = 'driver-documents' AND auth.uid()::text = (storage.foldername(name))[1])
```

### Policy for `delivery-photos` (Authenticated Access)

**Policy 1: Drivers can upload**
```sql
-- INSERT policy
auth.role() = 'authenticated'
```

**Policy 2: Authenticated users can view**
```sql
-- SELECT policy
auth.role() = 'authenticated'
```

---

## Step 4: Quick SQL Setup (Alternative)

Instead of using the UI, run this SQL in **SQL Editor**:

```sql
-- Create policies for driver-photos bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('driver-photos', 'driver-photos', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('driver-documents', 'driver-documents', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('delivery-photos', 'delivery-photos', false, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- Policies for driver-photos (public bucket)
CREATE POLICY "Public read driver-photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'driver-photos');

CREATE POLICY "Authenticated upload driver-photos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'driver-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Owner update driver-photos"
ON storage.objects FOR UPDATE
USING (bucket_id = 'driver-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Policies for driver-documents (private bucket)
CREATE POLICY "Owner access driver-documents"
ON storage.objects FOR ALL
USING (bucket_id = 'driver-documents' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Policies for delivery-photos
CREATE POLICY "Authenticated upload delivery-photos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'delivery-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Authenticated read delivery-photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'delivery-photos' AND auth.role() = 'authenticated');
```

---

## Step 5: Get Your Supabase Credentials

1. Go to **Project Settings** (gear icon)
2. Click **API** in the sidebar
3. Copy these values:

```
Project URL: https://xxxxxxxx.supabase.co
anon public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
service_role key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (for backend only)
```

---

## Step 6: Update Environment Variables

### Backend (.env)
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-role-key
```

### Flutter App (.env)
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

---

## File Structure in Storage

```
driver-photos/
  └── {user_id}/
      └── profile.jpg

driver-documents/
  └── {user_id}/
      ├── driver_license_front.jpg
      ├── driver_license_back.jpg
      ├── national_id_front.jpg
      ├── national_id_back.jpg
      ├── vehicle_photo.jpg
      └── vehicle_registration.jpg

delivery-photos/
  └── {order_id}/
      ├── pickup.jpg
      └── delivery.jpg
```

---

## Verification Checklist

- [ ] Created `driver-photos` bucket (public)
- [ ] Created `driver-documents` bucket (private)
- [ ] Created `delivery-photos` bucket (private)
- [ ] Applied storage policies
- [ ] Copied Supabase credentials
- [ ] Updated backend .env
- [ ] Updated Flutter .env
- [ ] Tested upload from app

---

## Troubleshooting

### "new row violates row-level security policy"
- Check that policies are correctly applied
- Ensure the user is authenticated
- Verify the folder path matches `{user_id}/filename`

### "Bucket not found"
- Verify bucket name is exactly correct (case-sensitive)
- Check bucket exists in Storage dashboard

### "File too large"
- Our upload API compresses to max 500KB
- Check `file_size_limit` in bucket settings
