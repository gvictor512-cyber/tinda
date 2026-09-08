import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/feedback_service.dart';
import '../../services/app_review_service.dart';
import '../../services/referral_service.dart';
import '../auth/welcome_screen.dart';
import '../settings/privacy_settings_screen.dart';
import '../settings/legal_document_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  bool _notifications = true;
  bool _darkMode = false;

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _showInviteDialog() async {
    final referralLink = await ReferralService.getReferralLink();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invita a un amigo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comparte tu enlace y consigue beneficios exclusivos.'),
            const SizedBox(height: 16),
            Text(
              referralLink,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: referralLink));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enlace copiado al portapapeles')),
              );
            },
            child: const Text('Copiar enlace'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInAppReview() async {
    await AppReviewService.requestReview();
  }

  void _showFeedbackDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar sugerencia'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Cuéntanos cómo podemos mejorar...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final message = controller.text.trim();
              if (message.isEmpty) return;
              Navigator.of(context).pop();
              try {
                await FeedbackService.submit(message: message);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sugerencia enviada, gracias.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo enviar la sugerencia.')),
                  );
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _openDocument(String title, String assetPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LegalDocumentScreen(
          title: title,
          assetPath: assetPath,
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          '¿Estás seguro? Esta acción eliminará tu cuenta y todos tus datos de forma permanente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _authService.deleteAccount();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar la cuenta: $e')),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const SizedBox(height: 8),
            const Text(
              'Preferencias',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _notifications,
              onChanged: (value) => setState(() => _notifications = value),
              title: const Text('Notificaciones'),
              secondary: const Icon(Icons.notifications_outlined, color: AppTheme.primaryBlue),
            ),
            SwitchListTile(
              value: _darkMode,
              onChanged: (value) => setState(() => _darkMode = value),
              title: const Text('Modo oscuro'),
              secondary: const Icon(Icons.dark_mode_outlined, color: AppTheme.primaryBlue),
            ),
            const Divider(height: 48),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryBlue),
              title: const Text('Privacidad y datos'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Legal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.gavel, color: AppTheme.primaryBlue),
              title: const Text('Términos de Servicio'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _openDocument('Términos de Servicio', 'assets/legal/terms_of_service.md'),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: AppTheme.primaryBlue),
              title: const Text('Política de Privacidad'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _openDocument('Política de Privacidad', 'assets/legal/privacy_policy.md'),
            ),
            ListTile(
              leading: const Icon(Icons.cookie_outlined, color: AppTheme.primaryBlue),
              title: const Text('Política de Cookies'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _openDocument('Política de Cookies', 'assets/legal/cookie_policy.md'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Cuenta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.error),
              title: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.error)),
              onTap: _signOut,
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: AppTheme.error),
              title: const Text('Eliminar cuenta', style: TextStyle(color: AppTheme.error)),
              onTap: _showDeleteConfirmation,
            ),
            const SizedBox(height: 32),
            const Text(
              'Más',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_add, color: AppTheme.primaryBlue),
              title: const Text('Invita a un amigo'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showInviteDialog(),
            ),
            ListTile(
              leading: const Icon(Icons.star, color: AppTheme.primaryBlue),
              title: const Text('Valora la app'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _openInAppReview(),
            ),
            ListTile(
              leading: const Icon(Icons.feedback_outlined, color: AppTheme.primaryBlue),
              title: const Text('Enviar sugerencia'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showFeedbackDialog,
            ),
            const SizedBox(height: 32),
            const Text(
              '© 2026 RoomMate Match. All rights reserved.',
              style: TextStyle(fontSize: 12, color: AppTheme.textDarkSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
