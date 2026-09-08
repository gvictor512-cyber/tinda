import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/app_localizations.dart';

/// Muestra diálogos explicativos antes de solicitar permisos.
class PermissionService {
  static Future<bool> requestWithRationale(
    BuildContext context, {
    required Permission permission,
    required String title,
    required String description,
  }) async {
    final status = await permission.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;

    if (!context.mounted) return false;

    final l10n = AppLocalizations.of(context)!;

    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.allow),
          ),
        ],
      ),
    );

    if (shouldRequest != true) return false;

    final result = await permission.request();
    return result.isGranted;
  }

  static Future<bool> requestLocation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return requestWithRationale(
      context,
      permission: Permission.locationWhenInUse,
      title: l10n.permissionLocationTitle,
      description: l10n.permissionLocationDescription,
    );
  }

  static Future<bool> requestCamera(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return requestWithRationale(
      context,
      permission: Permission.camera,
      title: l10n.permissionCameraTitle,
      description: l10n.permissionCameraDescription,
    );
  }

  static Future<bool> requestNotifications(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return requestWithRationale(
      context,
      permission: Permission.notification,
      title: l10n.permissionNotificationsTitle,
      description: l10n.permissionNotificationsDescription,
    );
  }

  static Future<bool> requestPhotos(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return requestWithRationale(
      context,
      permission: Permission.photos,
      title: l10n.permissionPhotosTitle,
      description: l10n.permissionPhotosDescription,
    );
  }
}
