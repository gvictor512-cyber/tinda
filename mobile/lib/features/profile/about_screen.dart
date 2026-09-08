import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../settings/legal_document_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _openDocument(BuildContext context, String title, String assetPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LegalDocumentScreen(
          title: title,
          assetPath: assetPath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo_symbol.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const Text(
                  'RoomMate Match',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Versión 1.0.0',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Conectamos personas compatibles para compartir piso de forma segura y sencilla.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: Colors.white),
                  title: const Text('Términos de uso', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.white70),
                  onTap: () => _openDocument(
                    context,
                    'Términos de Servicio',
                    'assets/legal/terms_of_service.md',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white),
                  title: const Text('Política de privacidad', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.white70),
                  onTap: () => _openDocument(
                    context,
                    'Política de Privacidad',
                    'assets/legal/privacy_policy.md',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.cookie_outlined, color: Colors.white),
                  title: const Text('Política de cookies', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.white70),
                  onTap: () => _openDocument(
                    context,
                    'Política de Cookies',
                    'assets/legal/cookie_policy.md',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '© 2026 RoomMate Match. All rights reserved.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
