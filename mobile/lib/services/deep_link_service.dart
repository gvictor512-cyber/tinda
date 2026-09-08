import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import '../utils/secure_storage_service.dart';
import 'analytics_service.dart';

/// Servicio para gestionar deep links de invitación/referidos.
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();

  Future<void> init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(initial);
      }

      _appLinks.uriLinkStream.listen(
        _handleUri,
        onError: (e) => debugPrint('Deep link stream error: $e'),
      );
    } catch (e) {
      debugPrint('Error inicializando deep links: $e');
    }
  }

  Future<void> _handleUri(Uri uri) async {
    debugPrint('Deep link recibido: $uri');

    // Soporta: https://roommatematch.app/ref/USER_ID o roommatematch://ref/USER_ID
    String? referralCode;
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'ref') {
      if (uri.pathSegments.length > 1) {
        referralCode = uri.pathSegments[1];
      }
    } else if (uri.queryParameters.containsKey('ref')) {
      referralCode = uri.queryParameters['ref'];
    }

    if (referralCode != null && referralCode.isNotEmpty) {
      await SecureStorageService.setString('referred_by', referralCode);
      unawaited(AnalyticsService().logShare('referral_link', referralCode));
      debugPrint('Referral guardado: $referralCode');
    }
  }
}
