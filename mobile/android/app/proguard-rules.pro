# Reglas ProGuard para flutter_stripe / RoomMate Match
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
-dontwarn kotlinx.parcelize.Parceler$DefaultImpls
-dontwarn kotlinx.parcelize.Parceler
-dontwarn kotlinx.parcelize.Parcelize
# Keep Stripe classes
-keep class com.stripe.** { *; }
-dontwarn com.reactnativestripesdk.**
# Keep flutter_secure_storage and related classes
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Firebase / Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# In-app purchase (Google Play Billing)
-keep class com.android.billingclient.** { *; }
-dontwarn com.android.billingclient.**
