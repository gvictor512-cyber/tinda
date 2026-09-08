import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Servicio para solicitar el consentimiento de App Tracking Transparency en iOS.
class AttService {
  static bool _requested = false;

  /// Solicita el permiso de rastreo en iOS la primera vez.
  static Future<void> requestIfNeeded() async {
    if (_requested) return;
    _requested = true;

    if (!Platform.isIOS) return;

    try {
      final status = await Permission.appTrackingTransparency.status;
      if (status.isDenied || status.isRestricted) {
        await Permission.appTrackingTransparency.request();
      }
    } catch (e) {
      debugPrint('Error solicitando ATT: $e');
    }
  }
}
