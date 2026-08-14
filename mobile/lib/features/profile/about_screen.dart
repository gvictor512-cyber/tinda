import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.home, size: 56, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'RoomMate Match',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Versión 1.0.0',
                style: TextStyle(color: AppTheme.textDarkSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'Conectamos personas compatibles para compartir piso de forma segura y sencilla.',
                style: TextStyle(fontSize: 16, color: AppTheme.textDarkSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: AppTheme.primaryBlue),
                title: const Text('Términos de uso'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _launch('https://roommatematch.com/terms'),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryBlue),
                title: const Text('Política de privacidad'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _launch('https://roommatematch.com/privacy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
