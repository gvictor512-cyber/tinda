import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/store_config.dart';

/// Solicita una valoración nativa en iOS/Android o redirige a la tienda.
class AppReviewService {
  static Future<void> requestReview() async {
    if (kIsWeb) {
      await _openStore();
      return;
    }

    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        return;
      }
    } catch (e) {
      debugPrint('Error al solicitar valoración nativa: $e');
    }

    await _openStore();
  }

  static Future<void> _openStore() async {
    final url = Uri.parse(StoreConfig.currentStoreUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
