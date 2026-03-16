# Firebase Setup Guide for FlaRide Driver

## Prerequisites
- Firebase account (https://console.firebase.google.com)
- Flutter CLI installed

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add Project"
3. Name it "FlaRide Driver" (or your preferred name)
4. Enable/disable Google Analytics as needed
5. Click "Create Project"

## Step 2: Add Android App

1. In Firebase Console, click "Add App" → Android
2. Enter package name: `com.flaride.flaride_driver`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

## Step 3: Add iOS App

1. In Firebase Console, click "Add App" → iOS
2. Enter bundle ID: `com.flaride.flarideDriver`
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

## Step 4: Configure Android

The `android/app/build.gradle` already has the necessary configuration.

Add to `android/build.gradle` (project-level) if not present:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

## Step 5: Configure iOS

Add to `ios/Runner/Info.plist` (already added):
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## Step 6: Enable Cloud Messaging

1. In Firebase Console, go to Project Settings → Cloud Messaging
2. Note your Server Key (for backend)
3. Enable Cloud Messaging API

## Step 7: Test Notifications

Run the app and check console for:
```
NotificationService: FCM Token: <your-token>
```

Send a test notification from Firebase Console:
1. Go to Engage → Messaging
2. Click "Create your first campaign"
3. Select "Firebase Notification messages"
4. Enter title and body
5. Target your app
6. Send test message

## Notification Channels (Android)

The app has 3 notification channels:
- `order_notifications` - New orders and updates (High priority)
- `message_notifications` - Customer messages (High priority)
- `system_notifications` - System announcements (Default priority)

## Backend Integration

Send the FCM token to your backend after login:
```dart
final token = NotificationService().fcmToken;
// Send to backend API
```

## Troubleshooting

### iOS Simulator
Push notifications don't work on iOS Simulator. Test on real device.

### Android Emulator
Works with Google Play Services. Use an emulator with Play Store.

### Token Not Received
- Check internet connection
- Verify Firebase configuration files are correct
- Check Firebase Console for any issues
