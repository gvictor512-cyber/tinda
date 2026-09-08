import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/secure_storage_service.dart';
import 'app_review_service.dart';

class RatingService {
  static const _openCountKey = 'app_open_count';
  static const _ratedKey = 'user_rated';
  static const _dismissedKey = 'rate_dismissed';

  /// Incrementa el contador de aperturas.
  static Future<void> trackAppOpen() async {
    final count = await SecureStorageService.getInt(_openCountKey);
    await SecureStorageService.setInt(_openCountKey, count + 1);
  }

  /// Muestra el diálogo para valorar si se cumplen las condiciones.
  static Future<void> showIfNeeded(BuildContext context) async {
    final count = await SecureStorageService.getInt(_openCountKey);
    final hasRated = await SecureStorageService.getBool(_ratedKey);
    final dismissed = await SecureStorageService.getBool(_dismissedKey);

    // Ajusta los umbrales: 5 aperturas, luego 15 si la descartó.
    final threshold = dismissed ? 15 : 5;

    if (count < threshold || hasRated) return;
    if (!context.mounted) return;

    final shouldOpen = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¿Te gusta RoomMate Match?'),
        content: const Text(
          'Si te está siendo útil, tu valoración en la tienda nos ayuda mucho a seguir mejorando.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              SecureStorageService.setBool(_dismissedKey, true);
              Navigator.of(context).pop(false);
            },
            child: const Text('Ahora no'),
          ),
          TextButton(
            onPressed: () {
              SecureStorageService.setBool(_ratedKey, true);
              Navigator.of(context).pop(true);
            },
            child: const Text('Valorar'),
          ),
        ],
      ),
    );

    if (shouldOpen == true && context.mounted) {
      unawaited(AppReviewService.requestReview());
    }
  }
}
