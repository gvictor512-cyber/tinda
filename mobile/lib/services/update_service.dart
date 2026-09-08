import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/store_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Verifica si hay una actualización obligatoria y bloquea la app si la hay.
class UpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('versions')
          .get();

      if (!doc.exists) return;

      final data = doc.data();
      final minVersion = data?['minVersion'] as String?;
      final forceUpdate = data?['forceUpdate'] as bool? ?? false;

      if (minVersion == null || minVersion.isEmpty) return;

      if (_shouldUpdate(currentVersion, minVersion)) {
        if (forceUpdate) {
          await _showForceUpdateDialog(context);
        } else {
          await _showOptionalUpdateDialog(context);
        }
      }
    } catch (e) {
      debugPrint('Error comprobando actualización: $e');
    }
  }

  static bool _shouldUpdate(String current, String minimum) {
    final currentParts = current.split('.').map(int.tryParse).whereType<int>().toList();
    final minimumParts = minimum.split('.').map(int.tryParse).whereType<int>().toList();

    for (var i = 0; i < minimumParts.length; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      if (currentPart < minimumParts[i]) return true;
      if (currentPart > minimumParts[i]) return false;
    }
    return false;
  }

  static Future<void> _openStore() async {
    final url = Uri.parse(StoreConfig.currentStoreUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> _showForceUpdateDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text('Actualización obligatoria'),
          content: Text(
            'Hay una nueva versión de RoomMate Match. Debes actualizar para continuar.',
          ),
          actions: [
            TextButton(
              onPressed: _openStore,
              child: Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showOptionalUpdateDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva versión disponible'),
        content: const Text(
          'Hay una nueva versión de RoomMate Match con mejoras. ¿Quieres actualizar ahora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Más tarde'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openStore();
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}
