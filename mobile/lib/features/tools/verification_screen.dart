import 'package:flutter/material.dart';
import '../../config/theme.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  final List<Map<String, dynamic>> _steps = const [
    {
      'title': 'DNI / Pasaporte',
      'subtitle': 'Verifica tu identidad real',
      'icon': Icons.badge,
      'done': false,
    },
    {
      'title': 'Email universitario o empresa',
      'subtitle': 'Gana el badge de confianza',
      'icon': Icons.email,
      'done': true,
    },
    {
      'title': 'Reseñas de compañeros',
      'subtitle': '2 reseñas recibidas',
      'icon': Icons.star,
      'done': true,
    },
    {
      'title': 'Teléfono verificado',
      'subtitle': 'Número confirmado',
      'icon': Icons.phone,
      'done': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación y confianza'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(isDarkMode),
          const SizedBox(height: 24),
          ..._steps.map((s) => _buildStepCard(s, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.verified,
            size: 48,
            color: Colors.white,
          ),
          SizedBox(height: 12),
          Text(
            'Perfil verificado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Los perfiles verificados ganan visibilidad y generan más confianza.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(Map<String, dynamic> step, bool isDarkMode) {
    final done = step['done'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: done
                  ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                  : AppTheme.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step['icon'] as IconData,
              color: done ? AppTheme.primaryGreen : AppTheme.warning,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['title'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step['subtitle'] as String,
                  style: TextStyle(
                    color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? AppTheme.primaryGreen : AppTheme.textLightSecondary,
          ),
        ],
      ),
    );
  }
}
