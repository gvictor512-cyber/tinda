import 'package:flutter/material.dart';
import '../../config/theme.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  final List<Map<String, String>> _markers = const [
    {'title': 'Piso en Gracia', 'price': '650€', 'type': 'Piso'},
    {'title': 'Habitación Eixample', 'price': '400€', 'type': 'Habitación'},
    {'title': 'Ático Sants', 'price': '850€', 'type': 'Piso'},
    {'title': 'Piso compartido', 'price': '350€', 'type': 'Habitación'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de pisos'),
      ),
      body: Stack(
        children: [
          Container(
            color: isDarkMode ? AppTheme.darkBackground : const Color(0xFFE0E7FF),
            child: Center(
              child: Icon(
                Icons.map,
                size: 120,
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildFilters(isDarkMode),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _markers.length,
                itemBuilder: (context, index) => _buildMarkerCard(_markers[index], isDarkMode),
              ),
            ),
          ),
          ..._buildMockPins(),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterChip('Radio', Icons.radar),
          const SizedBox(width: 8),
          _buildFilterChip('Precio', Icons.euro),
          const SizedBox(width: 8),
          _buildFilterChip('Estancia', Icons.timelapse),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 18, color: AppTheme.primaryBlue),
      label: Text(label),
      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
      side: BorderSide.none,
    );
  }

  Widget _buildMarkerCard(Map<String, String> marker, bool isDarkMode) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            marker['title']!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            marker['price']!,
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            marker['type']!,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMockPins() {
    return [
      Positioned(top: 120, left: 80, child: _pinIcon()),
      Positioned(top: 200, left: 220, child: _pinIcon()),
      Positioned(top: 340, left: 140, child: _pinIcon()),
      Positioned(top: 260, left: 300, child: _pinIcon()),
    ];
  }

  Widget _pinIcon() {
    return const Icon(
      Icons.location_pin,
      color: AppTheme.primaryBlue,
      size: 36,
    );
  }
}
