# Screenshot Capture Guide - RoomMate Match

## Current Status
✅ App is running on emulator (Pixel 6 - Android 14)
✅ Dependencies installed and configured
✅ Email service implemented (using url_launcher)
⏳ Screenshots need to be captured manually

## How to Capture Screenshots

### Method 1: Android Studio (Recommended)
1. Open Android Studio
2. Go to View > Tool Windows > Device Manager
3. Select the running emulator
4. Click the "More" button (three dots)
5. Select "Screen capture"
6. Save screenshot to desired location

### Method 2: Emulator Built-in
1. In the emulator window, find the camera icon in the toolbar
2. Click it to capture screenshot
3. Save to desired location

### Method 3: Using Flutter Tools
```bash
# From mobile directory
flutter screenshot --device=emulator-5554
```

### Method 4: Using ADB (if available)
```bash
# Find Android SDK path in Android Studio: File > Settings > Appearance & Behavior > System Settings > Android SDK
# Add to PATH or use full path
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png
```

## Required Screenshots

### 1. Onboarding - User Type Selection
**File:** screenshot_1_onboarding.png
**Content:** UserTypeSelectionScreen with "Busca piso" and "Tienes piso" options
**Location:** Navigate to first screen after splash

### 2. Swipe Interface
**File:** screenshot_2_swipe.png
**Content:** SwipeScreen with profile card and like/dislike buttons
**Location:** Navigate to swipe screen after onboarding

### 3. Compatibility Score
**File:** screenshot_3_compatibility.png
**Content:** Compatibility score display with factors
**Location:** Tap on a profile to see compatibility details

### 4. Chat Screen
**File:** screenshot_4_chat.png
**Content:** ChatScreen with conversation bubbles
**Location:** Navigate to chat after making a match

### 5. Apartment Search
**File:** screenshot_5_apartment.png
**Content:** Apartment search with filters and results
**Location:** Navigate to apartment search feature

### 6. User Profile
**File:** screenshot_6_profile.png
**Content:** User profile with photos and preferences
**Location:** Navigate to profile settings

### 7. Premium Features
**File:** screenshot_7_premium.png
**Content:** Premium subscription screen with benefits
**Location:** Navigate to premium/subscription screen

### 8. Privacy Settings
**File:** screenshot_8_privacy.png
**Content:** PrivacySettingsScreen with GDPR options
**Location:** Navigate to settings > privacy

## Image Requirements

### Android Screenshots
- **Resolution:** 1080x1920 px (16:9) or 1080x2400 px (2:1)
- **Format:** PNG or JPG
- **Quality:** High resolution, clear text

### iOS Screenshots (when testing on iOS)
- **iPhone 6.7":** 1290x2796 px
- **iPhone 6.5":** 1242x2688 px
- **Format:** PNG or JPG

## Screenshot Preparation Tips

### Before Capturing
1. **Clear status bar:** Remove notifications
2. **Time:** Set realistic time (e.g., 10:30 AM)
3. **Battery:** Show reasonable battery level
4. **WiFi:** Show WiFi icon
5. **No debugging:** Ensure debug banner is hidden

### During Capture
1. **Focus:** Ensure screen is focused and sharp
2. **Lighting:** Good screen brightness
3. **Content:** Show key features clearly
4. **Consistency:** Use same style across all screenshots

### After Capture
1. **Crop:** Remove emulator frame if desired
2. **Resize:** Ensure correct dimensions
3. **Optimize:** Compress file size if needed
4. **Name:** Use consistent naming convention

## Output Locations

### Android Screenshots
```
assets/store/google-play/screenshots/
├── screenshot_1_onboarding.png
├── screenshot_2_swipe.png
├── screenshot_3_compatibility.png
├── screenshot_4_chat.png
├── screenshot_5_apartment.png
├── screenshot_6_profile.png
├── screenshot_7_premium.png
└── screenshot_8_privacy.png
```

### iOS Screenshots
```
assets/store/app-store/screenshots/
├── screenshot_1_onboarding.png
├── screenshot_2_swipe.png
├── screenshot_3_compatibility.png
├── screenshot_4_chat.png
├── screenshot_5_apartment.png
├── screenshot_6_profile.png
├── screenshot_7_premium.png
└── screenshot_8_privacy.png
```

## Automation Script (Optional)

Create a script to automate screenshot capture:

```bash
#!/bin/bash
# screenshot_capture.sh

# Navigate to mobile directory
cd mobile

# Capture screenshots
flutter screenshot --device=emulator-5554 --out=../assets/store/google-play/screenshots/screenshot_1_onboarding.png
# Navigate to next screen
# flutter screenshot --device=emulator-5554 --out=../assets/store/google-play/screenshots/screenshot_2_swipe.png
# ... continue for all screenshots
```

## Troubleshooting

### Emulator Not Found
```bash
flutter devices
flutter emulators --launch <emulator_id>
```

### Screenshot Blurry
- Increase emulator resolution
- Use higher density emulator
- Check emulator display settings

### Wrong Dimensions
- Resize using image editor (Figma, GIMP, Photoshop)
- Ensure aspect ratio is correct
- Use high-quality scaling

## Next Steps After Screenshots

1. **Review screenshots** for quality and consistency
2. **Edit screenshots** if needed (crop, resize, add text)
3. **Create feature graphic** for Google Play (1024x500 px)
4. **Create app preview video** (optional, 15-30 seconds)
5. **Upload to store consoles** when ready for submission

## Current App State

The app is currently running on the emulator with:
- ✅ Splash screen
- ✅ User type selection
- ✅ Main navigation
- ✅ Email service (via url_launcher)
- ✅ Privacy settings screen

Navigate through the app to capture each required screenshot.
