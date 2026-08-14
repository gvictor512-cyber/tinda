# iOS Privacy Configuration

## Info.plist Keys

Add these keys to `mobile/ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para que puedas subir fotos de perfil y verificar tu identidad</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Necesitamos acceso a tu galería para que puedas seleccionar fotos de perfil</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>Necesitamos acceso para guardar fotos de perfil en tu dispositivo</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrarte compañeros de piso y pisos cercanos</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrarte compañeros de piso y pisos cercanos</string>

<key>NSContactsUsageDescription</key>
<string>Opcional: para encontrar amigos que ya usan la app</string>

<key>NSMicrophoneUsageDescription</key>
<string>Necesitamos acceso al micrófono para mensajes de voz (opcional)</string>

<key>NSFaceIDUsageDescription</key>
<string>Usa Face ID para iniciar sesión de forma segura</string>

<!-- App Transport Security -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>firebaseio.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>

<!-- Privacy - Tracking -->
<key>NSUserTrackingUsageDescription</key>
<string>Usamos datos de uso para mejorar la app y mostrarte contenido relevante</string>

<!-- Background Modes -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>fetch</string>
</array>

<!-- App Category -->
<key>LSApplicationCategoryType</key>
<string>public.app-category.lifestyle</string>

<!-- Supported Devices -->
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>

<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>

<!-- Required Device Capabilities -->
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>armv7</string>
</array>

<!-- App Info -->
<key>CFBundleDisplayName</key>
<string>RoomMate Match</string>

<key>CFBundleName</key>
<string>roommatematch</string>

<key>CFBundleVersion</key>
<string>1</string>

<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
```

## App Store Privacy Details

### Data Collection

**Purpose:** App functionality and user matching

**Data Types Collected:**

**Contact Info:**
- Email address (Account creation, verification)
- Phone number (Verification, safety)
- Physical address (Optional, for apartment search)

**User Content:**
- Photos (Profile pictures, verification)
- User IDs (Authentication)
- Profile information (Preferences, interests)

**Usage Data:**
- App interactions (Matching, chat, search)
- Crash data (App stability)
- Performance data (App optimization)

**Identifiers:**
- Device ID (Analytics, security)
- User ID (Authentication)

**Location:**
- Precise location (Matching, apartment search)
- Coarse location (General area matching)

### Data Usage

**Purpose of Data Collection:**
- **App Functionality:** Core features (matching, chat, search)
- **Analytics:** App improvement and bug fixing
- **Product Personalization:** Better matching recommendations
- **Security:** Fraud prevention and user safety

**Third-Party Sharing:**
- **Firebase (Google):** Authentication, database, analytics
- **Socket.io:** Real-time communication
- **No data sold to third parties**

### Data Linking
- **Linked to user identity:** Yes (account-based app)
- **Tracking:** No (no cross-app tracking)

### Data Access
- **User can request data deletion:** Yes
- **User can export data:** Yes
- **Data retention period:** 30 days after account deletion

## App Store Connect Privacy Policy URL

**Privacy Policy URL:** [Your privacy policy URL]

**Must be:**
- Publicly accessible
- HTTPS secured
- Mobile-friendly
- Contains all required privacy information

## App Store Asset Requirements

### App Icon
- **1024x1024 px**
- **PNG format**
- **No transparency**
- **No rounded corners**

### App Store Screenshots
- **iPhone 6.7" Display:** 1290 x 2796 px
- **iPhone 6.5" Display:** 1242 x 2688 px
- **iPhone 5.5" Display:** 1242 x 2208 px
- **Minimum:** 3 screenshots
- **Maximum:** 10 screenshots
- **PNG or JPEG format**

### App Preview Video (Optional)
- **16:9 aspect ratio**
- **15-30 seconds**
- **M4V, MP4, or MOV format**
- **H.264 or ProRes codec**

### Promotional Text (170 chars max)
"¡Encuentra tu compañero de piso ideal! Algoritmo de compatibilidad inteligente, chat en tiempo real y búsqueda de pisos integrada."

## App Review Information

**Demo Account:**
- **Email:** demo@roommatematch.com
- **Password:** [Demo password]
- **Notes:** Account with full access for testing

**Contact Information:**
- **First Name:** [Your first name]
- **Last Name:** [Your last name]
- **Phone Number:** [Your phone number]
- **Email Address:** [Your email]

## App Store Review Guidelines Compliance

### Safety
- **No harmful content:** Content moderation system in place
- **User safety:** Verification system, report/block features
- **Data protection:** Encryption, secure authentication

### Performance
- **App completeness:** All features functional
- **No beta features:** Only production-ready features
- **No bugs:** Thoroughly tested

### Business
- **In-app purchases:** Clear pricing, no hidden fees
- **No scams:** Transparent business model
- **Legal compliance:** GDPR, CCPA compliant

### Design
- **Human interface guidelines:** Follows Apple's HIG
- **No placeholder content:** All content is real
- **Good user experience:** Intuitive navigation

## Testing Checklist

- [ ] Test on iOS 13.0+ devices
- [ ] Test permission requests
- [ ] Verify privacy policy accessibility
- [ ] Test data deletion functionality
- [ ] Test on different screen sizes
- [ ] Verify in-app purchases
- [ ] Test push notifications
- [ ] Test location services
- [ ] Verify camera and photo library access
- [ ] Test on both iPhone and iPad

## Additional Notes

### App Store Connect Categories
**Primary:** Lifestyle
**Secondary:** Social Networking

### Age Rating
**17+** due to:
- Unrestricted web access
- User-generated content
- Location services
- Contact information sharing

### Export Compliance
**Encryption:** Yes (standard encryption)
**Export Compliance:** App uses standard encryption, no special export license required
