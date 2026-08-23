import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'compatibility_screen.dart';
import 'visits_screen.dart';
import 'map_screen.dart';
import 'community_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  final List<Map<String, dynamic>> _items = const [
    {
      'title': 'Compatibilidad IA',
      'subtitle': 'Cuestionario de convivencia',
      'icon': Icons.psychology,
      'screen': CompatibilityScreen(),
    },
    {
      'title': 'Visitas y videollamadas',
      'subtitle': 'Agenda citas sin salir de la app',
      'icon': Icons.calendar_today,
      'screen': VisitsScreen(),
    },
    {
      'title': 'Mapa de pisos',
      'subtitle': 'Explora pisos y compañeros',
      'icon': Icons.map,
      'screen': MapScreen(),
    },
    {
      'title': 'Comunidad',
      'subtitle': 'Eventos y grupos',
      'icon': Icons.group,
      'screen': CommunityScreen(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Más'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: AppTheme.primaryBlue,
                ),
              ),
              title: Text(
                item['title'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
                ),
              ),
              subtitle: Text(
                item['subtitle'] as String,
                style: TextStyle(
                  color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: AppTheme.textLightSecondary),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => item['screen'] as Widget),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
