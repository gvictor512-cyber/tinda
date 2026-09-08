import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuración centralizada de las tiendas de aplicaciones.
class StoreConfig {
  /// Android applicationId definido en android/app/build.gradle.kts
  static const String androidAppId = 'com.roommatematch.app';

  /// ID numérico de la app en App Store Connect.
  /// Reemplazar por el ID real cuando esté disponible.
  static const String iosAppStoreId = 'YOUR_APP_ID';

  /// URL de la ficha en Google Play
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidAppId';

  /// URL de la ficha en App Store
  static const String appStoreUrl =
      'https://apps.apple.com/app/id$iosAppStoreId';

  /// Devuelve la URL de la tienda apropiada para la plataforma actual.
  static String get currentStoreUrl {
    if (kIsWeb) return playStoreUrl;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? appStoreUrl
        : playStoreUrl;
  }
}
