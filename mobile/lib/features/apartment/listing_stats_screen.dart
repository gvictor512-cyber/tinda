import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../services/listing_service.dart';
import '../../services/limits_service.dart';

class ListingStatsScreen extends StatefulWidget {
  final String listingId;
  final String listingTitle;

  const ListingStatsScreen({
    super.key,
    required this.listingId,
    required this.listingTitle,
  });

  @override
  State<ListingStatsScreen> createState() => _ListingStatsScreenState();
}

class _ListingStatsScreenState extends State<ListingStatsScreen> {
  final ListingService _listingService = ListingService();
  final LimitsService _limitsService = LimitsService();

  bool _isLoading = true;
  bool _hasFullAccess = false;
  Map<String, dynamic> _stats = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final hasFullAccess = await _limitsService.hasFullStatistics();
      final stats = await _listingService.getListingStats(widget.listingId);

      setState(() {
        _hasFullAccess = hasFullAccess;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estadísticas',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView(isDarkMode)
              : _buildStatsView(isDarkMode),
    );
  }

  Widget _buildErrorView(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: AppTheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar estadísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Ha ocurrido un error desconocido',
            style: TextStyle(
              color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsView(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            widget.listingTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasFullAccess ? 'Estadísticas completas' : 'Estadísticas básicas',
            style: TextStyle(
              fontSize: 14,
              color: _hasFullAccess ? AppTheme.primaryBlue : AppTheme.textDarkSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          // Basic stats (available to all)
          _buildSectionTitle('Visibilidad', isDarkMode),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.visibility_rounded,
                  label: 'Vistas',
                  value: _stats['views']?.toString() ?? '0',
                  color: AppTheme.primaryBlue,
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.favorite_rounded,
                  label: 'Likes',
                  value: _stats['likes']?.toString() ?? '0',
                  color: AppTheme.accentPink,
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),

          if (_hasFullAccess) ...[
            const SizedBox(height: 32),

            // Premium stats
            _buildSectionTitle('Interacción', isDarkMode),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.share_rounded,
                    label: 'Compartidos',
                    value: _stats['shares']?.toString() ?? '0',
                    color: AppTheme.secondaryPurple,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.message_rounded,
                    label: 'Contactos',
                    value: _stats['contactRequests']?.toString() ?? '0',
                    color: AppTheme.primaryGreen,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            _buildSectionTitle('Rendimiento', isDarkMode),
            const SizedBox(height: 16),
            _buildStatCard(
              icon: Icons.star_rounded,
              label: 'Valoración media',
              value: (_stats['averageRating'] as num?)?.toStringAsFixed(1) ?? 'N/A',
              color: AppTheme.accentOrange,
              isDarkMode: isDarkMode,
              subtitle: '${_stats['totalRatings'] ?? 0} valoraciones',
            ),

            const SizedBox(height: 24),
            _buildStatCard(
              icon: Icons.access_time_rounded,
              label: 'Última vista',
              value: _formatDate(_stats['lastViewed']),
              color: AppTheme.textDarkSecondary,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 32),

            _buildSectionTitle('Historial', isDarkMode),
            const SizedBox(height: 16),
            _buildTimelineCard(
              title: 'Publicado',
              date: _formatDate(_stats['createdAt']),
              icon: Icons.publish_rounded,
              color: AppTheme.primaryBlue,
              isDarkMode: isDarkMode,
            ),
          ] else ...[
            const SizedBox(height: 32),
            _buildPremiumUpsell(isDarkMode),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDarkMode,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineCard({
    required String title,
    required String date,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumUpsell(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 16),
          const Text(
            'Estadísticas Completas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Actualiza a Premium para ver estadísticas detalladas de tu anuncio: compartidos, contactos, valoraciones y más.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to premium screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Próximamente: Pantalla de suscripción'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Ver Premium',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    
    DateTime dateTime;
    if (date is DateTime) {
      dateTime = date;
    } else if (date is Timestamp) {
      dateTime = date.toDate();
    } else {
      return 'N/A';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
