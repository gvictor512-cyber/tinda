# Android Privacy Configuration

## AndroidManifest.xml Permissions

Add these permissions to `mobile/android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.roommatematch.app">

    <!-- Required Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Camera for profile photos and verification -->
    <uses-permission android:name="android.permission.CAMERA" />
    
    <!-- Storage for photos -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
        android:maxSdkVersion="28" />
    
    <!-- Location for matching and apartment search -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- Notifications -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <!-- Phone for verification -->
    <uses-permission android:name="android.permission.READ_PHONE_STATE" />
    
    <!-- Optional Permissions -->
    <uses-permission android:name="android.permission.VIBRATE" />
    
    <application
        android:label="RoomMate Match"
        android:icon="@mipmap/ic_launcher"
        android:requestLegacyExternalStorage="true">
        
        <!-- Privacy Policy -->
        <meta-data
            android:name="com.google.android.gms.ads.APPLICATION_ID"
            android:value="[YOUR_ADS_APP_ID]"/>
            
        <!-- Firebase Configuration -->
        <meta-data
            android:name="firebase_analytics_collection_enabled"
            android:value="true"/>
            
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

## Privacy Policy URL in Google Play Console

Add your privacy policy URL in Google Play Console:
- **Privacy Policy URL:** [Your privacy policy URL]
- **Link should be publicly accessible**

## Data Safety Section (Google Play Console)

### Data Collection
**Purpose:** App functionality and security

**Data Types:**
- **Email address:** For account creation and verification
- **Phone number:** For verification and safety
- **Photos:** For user profiles
- **Location:** For matching and apartment search
- **User IDs:** For authentication

**Sharing:**
- **Shared with third parties:** Firebase (Google) for app functionality
- **Shared for analytics:** Google Analytics (anonymized)
- **Shared for advertising:** None

### Security Practices
- **Data encryption:** Yes (in transit and at rest)
- **Data deletion:** Users can request deletion
- **Data portability:** Users can export their data
- **Security practices:** Regular security audits, access controls

## AdMob Privacy (if using ads)

If you implement AdMob, add to `AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.AD_MANAGER_APP_ID"
    android:value="[YOUR_AD_MANAGER_ID]"/>
```

And implement consent form for GDPR/CCPA compliance.

## Play Store Asset Requirements

### App Icon
- **512x512 px** high-resolution icon
- **PNG format**
- **No transparency**

### Feature Graphic
- **1024x500 px**
- **JPG or PNG format**
- **No transparency**

### Screenshots
- **Phone:** Minimum 2, maximum 8 screenshots
  - **1080x1920 px** or **1080x2400 px**
  - **JPG or PNG format**
- **Tablet:** Optional
  - **Minimum 2, maximum 8 screenshots**
  - **1200x1800 px** or **1200x2400 px**

### Promotional Assets
- **YouTube promo video:** Optional
- **Short description:** 80 characters maximum
- **Full description:** 4000 characters maximum

## Google Play Policy Compliance

### User Data
- **Privacy policy:** Required and publicly accessible
- **Data deletion:** Must provide way to delete user data
- **Data portability:** Must allow users to export data

### Permissions
- **Justification required:** Each permission must be justified
- **Runtime permissions:** Must request at runtime (Android 6.0+)
- **Permission rationale:** Must explain why permission is needed

### Content
- **No prohibited content:** No violence, hate speech, sexual content
- **User-generated content:** Must have moderation system
- **Age rating:** Appropriate age rating (17+)

### Payments
- **Google Play Billing:** Required for in-app purchases
- **Price transparency:** Clear pricing information
- **Refund policy:** Must comply with Google Play refund policy

## Testing Checklist

- [ ] Test all permission requests
- [ ] Verify privacy policy is accessible
- [ ] Test data deletion functionality
- [ ] Verify location permission handling
- [ ] Test camera and storage permissions
- [ ] Verify notification permissions
- [ ] Test on Android 8.0+ devices
- [ ] Verify compliance with Google Play policies
