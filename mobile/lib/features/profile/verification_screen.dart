import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  String? _message;

  Future<void> _sendEmail() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      await _authService.sendEmailVerification();
      if (mounted) setState(() => _message = 'Correo de verificación enviado');
    } catch (e) {
      if (mounted) {
        setState(() => _message = 'Error: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isVerified = user?.emailVerified ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Verificación')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                isVerified ? Icons.verified : Icons.shield_outlined,
                size: 80,
                color: isVerified ? AppTheme.success : AppTheme.primaryBlue,
              ),
              const SizedBox(height: 24),
              Text(
                isVerified ? 'Cuenta verificada' : 'Verifica tu identidad',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                isVerified
                    ? 'Tu correo electrónico ya ha sido verificado.'
                    : 'Para más seguridad, verifica tu correo electrónico. Te enviaremos un enlace de confirmación.',
                style: const TextStyle(fontSize: 16, color: AppTheme.textDarkSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!isVerified)
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendEmail,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text('Enviar correo de verificación'),
                ),
              if (_message != null) ...[
                const SizedBox(height: 24),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textDarkSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
