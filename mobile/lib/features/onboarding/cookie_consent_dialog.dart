import 'package:flutter/material.dart';
import '../../utils/secure_storage_service.dart';
import '../settings/legal_document_screen.dart';

const String _cookiesAcceptedKey = 'cookies_accepted';

/// Diálogo de consentimiento de cookies mostrado al primer inicio.
class CookieConsentDialog extends StatelessWidget {
  const CookieConsentDialog({super.key});

  static Future<bool> wasAccepted() async {
    final value = await SecureStorageService.read(_cookiesAcceptedKey);
    return value == 'true';
  }

  static Future<bool> showIfNeeded(BuildContext context) async {
    if (await wasAccepted()) return true;

    if (!context.mounted) return false;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CookieConsentDialog(),
    );
    return accepted ?? false;
  }

  void _openLegalDocument(BuildContext context, String title, String assetPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LegalDocumentScreen(
          title: title,
          assetPath: assetPath,
        ),
      ),
    );
  }

  Future<void> _accept(BuildContext context) async {
    await SecureStorageService.write(_cookiesAcceptedKey, 'true');
    if (context.mounted) Navigator.of(context).pop(true);
  }

  Future<void> _reject(BuildContext context) async {
    await SecureStorageService.write(_cookiesAcceptedKey, 'false');
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Preferencias de cookies'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usamos cookies y tecnologías similares para ofrecerte una experiencia segura y personalizada.',
            ),
            const SizedBox(height: 12),
            _CookieCategory(
              title: 'Esenciales',
              description: 'Necesarias para que la app funcione.',
              alwaysOn: true,
            ),
            _CookieCategory(
              title: 'Rendimiento y analíticas',
              description: 'Nos ayudan a entender cómo se usa la app.',
            ),
            _CookieCategory(
              title: 'Funcionalidad',
              description: 'Recuerdan tus preferencias.',
            ),
            _CookieCategory(
              title: 'Marketing',
              description: 'Personalización y anuncios relevantes.',
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _openLegalDocument(
                context,
                'Política de Cookies',
                'assets/legal/cookie_policy.md',
              ),
              child: const Text(
                'Ver Política de Cookies',
                style: TextStyle(
                  color: Color(0xFF4A90E2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _reject(context),
          child: const Text('Solo esenciales'),
        ),
        ElevatedButton(
          onPressed: () => _accept(context),
          child: const Text('Aceptar todas'),
        ),
      ],
    );
  }
}

class _CookieCategory extends StatelessWidget {
  final String title;
  final String description;
  final bool alwaysOn;

  const _CookieCategory({
    required this.title,
    required this.description,
    this.alwaysOn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            alwaysOn ? Icons.check_circle : Icons.check_circle_outline,
            color: alwaysOn ? const Color(0xFF4A90E2) : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
