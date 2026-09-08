import 'package:flutter/material.dart';
import '../../config/theme.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  final List<Map<String, String>> _events = const [
    {
      'title': 'Quedada de compañeros de piso',
      'date': 'Sábado, 19:00',
      'location': 'Plaza Catalunya',
      'image': '🎉',
    },
    {
      'title': 'Taller de convivencia',
      'date': 'Domingo, 11:00',
      'location': 'Centro cívico Gràcia',
      'image': '🤝',
    },
    {
      'title': 'Nómadas digitales Barcelona',
      'date': 'Miércoles, 18:30',
      'location': 'Cowork Diagonal',
      'image': '💻',
    },
  ];

  final List<String> _groups = const [
    'Estudiantes UAB',
    'Nómadas digitales',
    'Pisos LGBT+ friendly',
    'Amantes de mascotas',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Eventos y grupos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Conoce gente antes de compartir piso.',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ..._events.map((e) => _buildEventCard(e, isDarkMode)),
          const SizedBox(height: 24),
          Text(
            'Grupos por ciudad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          ..._groups.map((g) => _buildGroupChip(g, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, String> event, bool isDarkMode) {
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
          Text(
            event['image']!,
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event['date']!,
                  style: TextStyle(
                    color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event['location']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildGroupChip(String group, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        tileColor: isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          child: const Icon(Icons.group, color: AppTheme.primaryBlue),
        ),
        title: Text(
          group,
          style: TextStyle(
            color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textLightSecondary),
        onTap: () {},
      ),
    );
  }
}
