import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

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
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
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
          ],
        ),
      ),
    );
  }
}
