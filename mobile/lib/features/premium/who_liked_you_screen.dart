import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/matching_service.dart';
import '../../services/limits_service.dart';
import '../../features/premium/premium_subscription_screen.dart';

class WhoLikedYouScreen extends StatefulWidget {
  const WhoLikedYouScreen({super.key});

  @override
  State<WhoLikedYouScreen> createState() => _WhoLikedYouScreenState();
}

class _WhoLikedYouScreenState extends State<WhoLikedYouScreen> {
  final MatchingService _matchingService = MatchingService();
  final LimitsService _limitsService = LimitsService();
  
  bool _isLoading = true;
  bool _hasAccess = false;
  List<Map<String, dynamic>> _likedByUsers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAccessAndLoadData();
  }

  Future<void> _checkAccessAndLoadData() async {
    final hasAccess = await _limitsService.canSeeWhoLikedYou();
    
    if (!hasAccess) {
      setState(() {
        _isLoading = false;
        _hasAccess = false;
      });
      return;
    }

    setState(() {
      _hasAccess = true;
    });

    try {
      final users = await _matchingService.getWhoLikedYou();
      setState(() {
        _likedByUsers = users;
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
          'Te han dado like',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasAccess
              ? _buildPremiumUpsell(isDarkMode)
              : _errorMessage != null
                  ? _buildErrorView(isDarkMode)
                  : _likedByUsers.isEmpty
                      ? _buildEmptyView(isDarkMode)
                      : _buildUsersList(isDarkMode),
    );
  }

  Widget _buildPremiumUpsell(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 80,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¿Quién te ha dado like?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Saber quién te ha dado like antes del match es exclusivo para usuarios Premium.\n\nDescubre quién está interesado en ti y toma el control.',
              style: TextStyle(
                color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PremiumSubscriptionScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('Actualiza a Premium'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
            'Error al cargar datos',
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
            onPressed: _checkAccessAndLoadData,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 80,
            color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            'Aún nadie te ha dado like',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sigue swiping para encontrar tu match perfecto',
            style: TextStyle(
              color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(bool isDarkMode) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _likedByUsers.length,
      itemBuilder: (context, index) {
        final user = _likedByUsers[index];
        return _buildUserCard(user, isDarkMode);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, bool isDarkMode) {
    final profile = user['profile'] as Map<String, dynamic>? ?? {};
    final name = user['name'] as String? ?? 'Usuario';
    final age = profile['age'] as num?;
    final photoUrl = profile['photoURL'] as String?;
    final bio = profile['bio'] as String? ?? '';
    final interests = profile['interests'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to user profile
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDarkMode ? AppTheme.darkSurface : Colors.white,
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
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
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    backgroundColor: isDarkMode ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
                    child: photoUrl == null
                        ? Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                              fontSize: 24,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
                            ),
                          ),
                          if (age != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '$age años',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (bio.isNotEmpty)
                        Text(
                          bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                          ),
                        ),
                      if (interests.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: interests.take(3).map((interest) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                interest.toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppTheme.error,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
