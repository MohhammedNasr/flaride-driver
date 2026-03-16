# FlaRide Driver - Backend & Supabase Setup Guide

This guide provides step-by-step instructions for setting up the backend APIs and Supabase configuration for the FlaRide Driver app.

---

## Table of Contents
1. [Supabase Database Schema](#1-supabase-database-schema)
2. [Supabase Storage Setup](#2-supabase-storage-setup)
3. [Backend API Endpoints](#3-backend-api-endpoints)
4. [Missing APIs to Implement](#4-missing-apis-to-implement)
5. [Real-time Subscriptions](#5-real-time-subscriptions)
6. [FCM Token Registration](#6-fcm-token-registration)

---

## 1. Supabase Database Schema

### Step 1.1: Verify/Create `drivers` Table

Run this SQL in Supabase SQL Editor:

```sql
-- Drivers table (if not exists, create it)
CREATE TABLE IF NOT EXISTS drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  
  -- Status
  is_online BOOLEAN DEFAULT false,
  is_available BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  
  -- Current order
  current_order_id UUID REFERENCES orders(id),
  
  -- Location
  current_latitude DECIMAL(10, 8),
  current_longitude DECIMAL(11, 8),
  last_location_update TIMESTAMPTZ,
  
  -- Vehicle info
  vehicle_type VARCHAR(50), -- motorcycle, bicycle, car
  vehicle_brand VARCHAR(100),
  vehicle_model VARCHAR(100),
  vehicle_color VARCHAR(50),
  vehicle_license_plate VARCHAR(50),
  vehicle_year INTEGER,
  
  -- License & verification
  driver_license_number VARCHAR(100),
  driver_license_expiry DATE,
  national_id VARCHAR(100),
  has_insulated_bag BOOLEAN DEFAULT false,
  has_smartphone BOOLEAN DEFAULT true,
  
  -- Documents (Supabase Storage URLs)
  profile_photo_url TEXT,
  driver_license_front_url TEXT,
  driver_license_back_url TEXT,
  national_id_front_url TEXT,
  national_id_back_url TEXT,
  vehicle_photo_url TEXT,
  vehicle_registration_url TEXT,
  
  -- Stats
  acceptance_rate DECIMAL(5, 2) DEFAULT 100.0,
  completion_rate DECIMAL(5, 2) DEFAULT 100.0,
  average_rating DECIMAL(3, 2) DEFAULT 0.0,
  total_ratings INTEGER DEFAULT 0,
  total_deliveries INTEGER DEFAULT 0,
  successful_deliveries INTEGER DEFAULT 0,
  
  -- Earnings
  total_earnings DECIMAL(12, 2) DEFAULT 0,
  pending_earnings DECIMAL(12, 2) DEFAULT 0,
  today_online_minutes INTEGER DEFAULT 0,
  
  -- Settings
  max_delivery_distance_km DECIMAL(5, 2) DEFAULT 15.0,
  preferred_work_areas JSONB,
  auto_accept_orders BOOLEAN DEFAULT false,
  
  -- Payment info
  preferred_payout_method VARCHAR(50), -- mobile_money, bank_transfer
  mobile_money_provider VARCHAR(50),
  mobile_money_number VARCHAR(50),
  bank_name VARCHAR(100),
  bank_account_number VARCHAR(100),
  bank_branch VARCHAR(100),
  
  -- Notification preferences
  notifications_enabled BOOLEAN DEFAULT true,
  push_notifications BOOLEAN DEFAULT true,
  email_notifications BOOLEAN DEFAULT true,
  sms_notifications BOOLEAN DEFAULT false,
  
  -- FCM token for push notifications
  fcm_token TEXT,
  fcm_token_updated_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_drivers_user_id ON drivers(user_id);
CREATE INDEX IF NOT EXISTS idx_drivers_is_online ON drivers(is_online);
CREATE INDEX IF NOT EXISTS idx_drivers_is_available ON drivers(is_available);
CREATE INDEX IF NOT EXISTS idx_drivers_location ON drivers(current_latitude, current_longitude);
```

### Step 1.2: Create `driver_payouts` Table

```sql
CREATE TABLE IF NOT EXISTS driver_payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
  
  amount DECIMAL(12, 2) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed
  
  payout_method VARCHAR(50), -- mobile_money, bank_transfer
  payout_details JSONB, -- provider, number, reference, etc.
  
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  
  transaction_reference VARCHAR(255),
  failure_reason TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payouts_driver_id ON driver_payouts(driver_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON driver_payouts(status);
```

### Step 1.3: Create `driver_earnings` Table

```sql
CREATE TABLE IF NOT EXISTS driver_earnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id),
  
  delivery_fee DECIMAL(10, 2) NOT NULL,
  tip_amount DECIMAL(10, 2) DEFAULT 0,
  bonus_amount DECIMAL(10, 2) DEFAULT 0,
  total_earned DECIMAL(10, 2) NOT NULL,
  
  earning_type VARCHAR(50) DEFAULT 'delivery', -- delivery, bonus, referral
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_earnings_driver_id ON driver_earnings(driver_id);
CREATE INDEX IF NOT EXISTS idx_earnings_created_at ON driver_earnings(created_at);
```

### Step 1.4: Create `driver_daily_stats` Table

```sql
CREATE TABLE IF NOT EXISTS driver_daily_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
  
  stat_date DATE NOT NULL,
  
  orders_received INTEGER DEFAULT 0,
  orders_accepted INTEGER DEFAULT 0,
  orders_declined INTEGER DEFAULT 0,
  orders_completed INTEGER DEFAULT 0,
  orders_cancelled INTEGER DEFAULT 0,
  
  total_earnings DECIMAL(12, 2) DEFAULT 0,
  total_tips DECIMAL(12, 2) DEFAULT 0,
  total_bonuses DECIMAL(12, 2) DEFAULT 0,
  
  online_minutes INTEGER DEFAULT 0,
  active_minutes INTEGER DEFAULT 0,
  
  average_delivery_time INTEGER, -- in minutes
  total_distance_km DECIMAL(10, 2) DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(driver_id, stat_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_stats_driver_date ON driver_daily_stats(driver_id, stat_date);
```

### Step 1.5: Enable Realtime for Driver Tables

```sql
-- Enable realtime for orders table
ALTER PUBLICATION supabase_realtime ADD TABLE orders;

-- Enable realtime for drivers table
ALTER PUBLICATION supabase_realtime ADD TABLE drivers;
```

---

## 2. Supabase Storage Setup

### Step 2.1: Create Storage Buckets

Go to **Supabase Dashboard → Storage** and create these buckets:

| Bucket Name | Public | Description |
|-------------|--------|-------------|
| `driver-documents` | No | Driver verification documents (private) |
| `driver-photos` | Yes | Driver profile photos |
| `delivery-photos` | No | Proof of delivery photos |

### Step 2.2: Storage Policies

Run in SQL Editor:

```sql
-- Policy for driver-documents bucket (private - only owner can access)
CREATE POLICY "Drivers can upload their own documents"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'driver-documents' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Drivers can view their own documents"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'driver-documents' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Drivers can update their own documents"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'driver-documents' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy for driver-photos bucket (public read, authenticated upload)
CREATE POLICY "Anyone can view driver photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'driver-photos');

CREATE POLICY "Drivers can upload their photos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'driver-photos' AND
  auth.role() = 'authenticated'
);

CREATE POLICY "Drivers can update their photos"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'driver-photos' AND
  auth.role() = 'authenticated'
);

-- Policy for delivery-photos bucket
CREATE POLICY "Drivers can upload delivery photos"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'delivery-photos' AND
  auth.role() = 'authenticated'
);

CREATE POLICY "Authenticated users can view delivery photos"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'delivery-photos' AND
  auth.role() = 'authenticated'
);
```

### Step 2.3: Storage File Structure

```
driver-documents/
  └── {user_id}/
      ├── driver_license_front.jpg
      ├── driver_license_back.jpg
      ├── national_id_front.jpg
      ├── national_id_back.jpg
      ├── vehicle_photo.jpg
      └── vehicle_registration.jpg

driver-photos/
  └── {user_id}/
      └── profile.jpg

delivery-photos/
  └── {order_id}/
      ├── pickup_confirmation.jpg
      └── delivery_proof.jpg
```

---

## 3. Backend API Endpoints

### Existing APIs (Already Implemented)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/login` | POST | Driver login |
| `/api/auth/me` | GET | Get current user |
| `/api/auth/change-password` | POST | Change password |
| `/api/drivers/me` | GET | Get driver profile |
| `/api/drivers/me` | PUT | Update driver profile/status |
| `/api/driver/orders` | GET | Get order history |
| `/api/driver/orders/available` | GET | Get available orders |
| `/api/driver/orders/active` | GET | Get current active order |
| `/api/driver/orders/[id]/accept` | POST | Accept an order |
| `/api/driver/orders/[id]/status` | PATCH | Update order status |
| `/api/driver/earnings` | GET | Get earnings summary |
| `/api/driver/payouts` | GET/POST | Get/request payouts |
| `/api/driver/stats` | GET | Get driver statistics |

---

## 4. Missing APIs to Implement

### 4.1: FCM Token Registration

Create file: `/api/driver/fcm-token/route.js`

```javascript
import { NextResponse } from 'next/server';
import { getSupabaseClient } from '../../../../lib/supabase.js';
import { verifyToken } from '../../../../lib/auth.js';

const supabase = getSupabaseClient();

// POST /api/driver/fcm-token - Register FCM token
export async function POST(request) {
  try {
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Access token required' }, { status: 401 });
    }

    const token = authHeader.substring(7);
    const decoded = verifyToken(token);
    if (!decoded) {
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
    }

    const { fcm_token } = await request.json();
    
    if (!fcm_token) {
      return NextResponse.json({ error: 'FCM token required' }, { status: 400 });
    }

    // Update driver's FCM token
    const { error } = await supabase
      .from('drivers')
      .update({ 
        fcm_token,
        fcm_token_updated_at: new Date().toISOString()
      })
      .eq('user_id', decoded.userId);

    if (error) throw error;

    return NextResponse.json({ success: true, message: 'FCM token registered' });
  } catch (error) {
    console.error('FCM token registration error:', error);
    return NextResponse.json({ error: 'Failed to register FCM token' }, { status: 500 });
  }
}

// DELETE /api/driver/fcm-token - Remove FCM token (on logout)
export async function DELETE(request) {
  try {
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Access token required' }, { status: 401 });
    }

    const token = authHeader.substring(7);
    const decoded = verifyToken(token);
    if (!decoded) {
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
    }

    await supabase
      .from('drivers')
      .update({ fcm_token: null, fcm_token_updated_at: null })
      .eq('user_id', decoded.userId);

    return NextResponse.json({ success: true, message: 'FCM token removed' });
  } catch (error) {
    console.error('FCM token removal error:', error);
    return NextResponse.json({ error: 'Failed to remove FCM token' }, { status: 500 });
  }
}
```

### 4.2: Document Upload URL Generator

Create file: `/api/driver/upload-url/route.js`

```javascript
import { NextResponse } from 'next/server';
import { getSupabaseClient } from '../../../../lib/supabase.js';
import { verifyToken } from '../../../../lib/auth.js';

const supabase = getSupabaseClient();

// POST /api/driver/upload-url - Get signed upload URL
export async function POST(request) {
  try {
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Access token required' }, { status: 401 });
    }

    const token = authHeader.substring(7);
    const decoded = verifyToken(token);
    if (!decoded) {
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
    }

    const { document_type, content_type } = await request.json();
    
    const validTypes = [
      'profile_photo',
      'driver_license_front',
      'driver_license_back',
      'national_id_front',
      'national_id_back',
      'vehicle_photo',
      'vehicle_registration'
    ];
    
    if (!validTypes.includes(document_type)) {
      return NextResponse.json({ error: 'Invalid document type' }, { status: 400 });
    }

    const bucket = document_type === 'profile_photo' ? 'driver-photos' : 'driver-documents';
    const extension = content_type?.includes('png') ? 'png' : 'jpg';
    const filePath = `${decoded.userId}/${document_type}.${extension}`;

    // Create signed upload URL
    const { data, error } = await supabase.storage
      .from(bucket)
      .createSignedUploadUrl(filePath);

    if (error) throw error;

    return NextResponse.json({
      success: true,
      upload_url: data.signedUrl,
      file_path: filePath,
      bucket,
      token: data.token
    });
  } catch (error) {
    console.error('Upload URL generation error:', error);
    return NextResponse.json({ error: 'Failed to generate upload URL' }, { status: 500 });
  }
}
```

### 4.3: Delivery Photo Upload

Create file: `/api/driver/orders/[id]/photo/route.js`

```javascript
import { NextResponse } from 'next/server';
import { getSupabaseClient } from '../../../../../../lib/supabase.js';
import { verifyToken } from '../../../../../../lib/auth.js';

const supabase = getSupabaseClient();

// POST /api/driver/orders/[id]/photo - Upload delivery photo
export async function POST(request, { params }) {
  try {
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Access token required' }, { status: 401 });
    }

    const token = authHeader.substring(7);
    const decoded = verifyToken(token);
    if (!decoded) {
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
    }

    const { id: orderId } = await params;
    const { photo_type, content_type } = await request.json();
    
    const validTypes = ['pickup_confirmation', 'delivery_proof'];
    if (!validTypes.includes(photo_type)) {
      return NextResponse.json({ error: 'Invalid photo type' }, { status: 400 });
    }

    // Verify driver owns this order
    const { data: driver } = await supabase
      .from('drivers')
      .select('id')
      .eq('user_id', decoded.userId)
      .single();

    if (!driver) {
      return NextResponse.json({ error: 'Driver not found' }, { status: 404 });
    }

    const { data: order } = await supabase
      .from('orders')
      .select('id, driver_id')
      .eq('id', orderId)
      .single();

    if (!order || order.driver_id !== driver.id) {
      return NextResponse.json({ error: 'Order not found or not assigned to you' }, { status: 404 });
    }

    const extension = content_type?.includes('png') ? 'png' : 'jpg';
    const filePath = `${orderId}/${photo_type}.${extension}`;

    const { data, error } = await supabase.storage
      .from('delivery-photos')
      .createSignedUploadUrl(filePath);

    if (error) throw error;

    // Also update order with photo URL placeholder
    const updateField = photo_type === 'pickup_confirmation' 
      ? 'pickup_photo_url' 
      : 'delivery_photo_url';
    
    await supabase
      .from('orders')
      .update({ [updateField]: filePath })
      .eq('id', orderId);

    return NextResponse.json({
      success: true,
      upload_url: data.signedUrl,
      file_path: filePath,
      token: data.token
    });
  } catch (error) {
    console.error('Delivery photo upload error:', error);
    return NextResponse.json({ error: 'Failed to generate upload URL' }, { status: 500 });
  }
}
```

### 4.4: Daily Goals & Achievements

Create file: `/api/driver/goals/route.js`

```javascript
import { NextResponse } from 'next/server';
import { getSupabaseClient } from '../../../../lib/supabase.js';
import { verifyToken } from '../../../../lib/auth.js';

const supabase = getSupabaseClient();

// GET /api/driver/goals - Get driver's daily goals and progress
export async function GET(request) {
  try {
    const authHeader = request.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Access token required' }, { status: 401 });
    }

    const token = authHeader.substring(7);
    const decoded = verifyToken(token);
    if (!decoded) {
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
    }

    const { data: driver } = await supabase
      .from('drivers')
      .select('id, total_deliveries')
      .eq('user_id', decoded.userId)
      .single();

    if (!driver) {
      return NextResponse.json({ error: 'Driver not found' }, { status: 404 });
    }

    // Get today's stats
    const today = new Date().toISOString().split('T')[0];
    
    const { data: todayStats } = await supabase
      .from('driver_daily_stats')
      .select('*')
      .eq('driver_id', driver.id)
      .eq('stat_date', today)
      .single();

    // Get this week's stats
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - weekStart.getDay());
    
    const { data: weekStats } = await supabase
      .from('driver_daily_stats')
      .select('orders_completed, total_earnings')
      .eq('driver_id', driver.id)
      .gte('stat_date', weekStart.toISOString().split('T')[0]);

    const weeklyDeliveries = (weekStats || []).reduce((sum, s) => sum + s.orders_completed, 0);
    const weeklyEarnings = (weekStats || []).reduce((sum, s) => sum + parseFloat(s.total_earnings), 0);

    // Define goals
    const dailyGoals = {
      deliveries: { target: 10, current: todayStats?.orders_completed || 0 },
      earnings: { target: 15000, current: parseFloat(todayStats?.total_earnings || 0) },
      online_hours: { target: 8, current: (todayStats?.online_minutes || 0) / 60 },
    };

    const weeklyGoals = {
      deliveries: { target: 50, current: weeklyDeliveries },
      earnings: { target: 75000, current: weeklyEarnings },
    };

    // Achievements
    const achievements = [];
    
    if (driver.total_deliveries >= 100) {
      achievements.push({ id: 'century', name: '100 Deliveries', icon: '🎯' });
    }
    if (driver.total_deliveries >= 500) {
      achievements.push({ id: 'veteran', name: '500 Deliveries', icon: '🏆' });
    }
    if (driver.total_deliveries >= 1000) {
      achievements.push({ id: 'legend', name: '1000 Deliveries', icon: '👑' });
    }

    return NextResponse.json({
      success: true,
      daily_goals: dailyGoals,
      weekly_goals: weeklyGoals,
      achievements,
      streak_days: 0, // TODO: Calculate streak
    });
  } catch (error) {
    console.error('Get goals error:', error);
    return NextResponse.json({ error: 'Failed to fetch goals' }, { status: 500 });
  }
}
```

---

## 5. Real-time Subscriptions

The driver app uses Supabase Realtime for:

1. **Available Orders** - New pending orders
2. **Driver Updates** - Profile/status changes
3. **Active Order Updates** - Order status changes

Ensure Realtime is enabled (Step 1.5).

---

## 6. FCM Token Registration

After successful login in the Flutter app, register the FCM token:

```dart
// In driver_provider.dart or after login
final fcmToken = await NotificationService().fcmToken;
if (fcmToken != null) {
  await _apiService.post('/api/driver/fcm-token', {
    'fcm_token': fcmToken,
  });
}
```

---

## Quick Reference - Environment Variables

### Backend (.env)
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key
JWT_SECRET=your-jwt-secret
```

### Flutter App (.env)
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GOOGLE_MAPS_API_KEY=your-google-maps-key
API_BASE_URL=https://flaride.vercel.app
```

---

## Checklist

- [ ] Run database schema SQL in Supabase
- [ ] Create storage buckets
- [ ] Apply storage policies
- [ ] Enable Realtime for tables
- [ ] Create FCM token API endpoint
- [ ] Create upload URL API endpoint
- [ ] Create delivery photo API endpoint
- [ ] Create goals API endpoint
- [ ] Add Firebase config to Flutter app
- [ ] Test end-to-end flow
