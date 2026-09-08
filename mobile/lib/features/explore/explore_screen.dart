import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  final List<_Category> _categories = const [
    _Category(
      label: 'Busco piso',
      sublabel: 'Encuentra habitación',
      icon: Icons.search,
      color: Color(0xFF4A90E2),
      bgColor: Color(0xFFE3F2FD),
    ),
    _Category(
      label: 'Ofrezco piso',
      sublabel: 'Publica tu habitación',
      icon: Icons.home,
      color: Color(0xFF4CAF50),
      bgColor: Color(0xFFE8F5E9),
    ),
    _Category(
      label: 'Compañero de piso',
      sublabel: 'Busca personas afines',
      icon: Icons.people,
      color: Color(0xFFFF9800),
      bgColor: Color(0xFFFFF3E0),
    ),
    _Category(
      label: 'Estancias cortas',
      sublabel: 'Meses de alquiler',
      icon: Icons.luggage,
      color: Color(0xFF9C27B0),
      bgColor: Color(0xFFF3E5F5),
    ),
    _Category(
      label: 'Estancias largas',
      sublabel: 'Año o más',
      icon: Icons.apartment,
      color: Color(0xFF009688),
      bgColor: Color(0xFFE0F2F1),
    ),
    _Category(
      label: 'Solo estudiantes',
      sublabel: 'Universitarios',
      icon: Icons.school,
      color: Color(0xFFE91E63),
      bgColor: Color(0xFFFCE4EC),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Qué estás buscando?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige una categoría para filtrar perfiles',
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                itemCount: _categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) => _buildCategoryCard(context, _categories[index], isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, _Category category, bool isDarkMode) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Explorando: ${category.label}')),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurface : category.bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category.icon,
                size: 44,
                color: category.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.sublabel,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Category {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _Category({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
