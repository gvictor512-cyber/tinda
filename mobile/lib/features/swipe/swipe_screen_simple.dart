// ignore_for_file: unused_field
import 'package:flutter/material.dart';
import '../../services/matching_service.dart';
import '../../services/limits_service.dart';
import '../../config/theme.dart';
import '../../features/premium/premium_screen.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final MatchingService _matchingService = MatchingService();
  final LimitsService _limitsService = LimitsService();
  
  List<Map<String, dynamic>> _potentialMatches = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  int _todaySwipes = 0;
  int _dailyLimit = 15;

  @override
  void initState() {
    super.initState();
    _loadPotentialMatches();
  }

  Future<void> _loadPotentialMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final matches = await _matchingService.getPotentialMatches();
      final todaySwipes = await _limitsService.getTodaySwipes();
      final limits = await _limitsService.getUserLimits();
      
      setState(() {
        _potentialMatches = matches;
        _currentIndex = 0;
        _isLoading = false;
        _todaySwipes = todaySwipes;
        _dailyLimit = limits.dailySwipes == -1 ? 999 : limits.dailySwipes;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSwipe(bool isLike) async {
    if (_currentIndex >= _potentialMatches.length) return;

    // Check if user can swipe
    final canSwipe = await _limitsService.canSwipe();
    if (!canSwipe) {
      _showSwipeLimitDialog();
      return;
    }

    final currentMatch = _potentialMatches[_currentIndex];
    
    try {
      await _matchingService.recordSwipe(
        swipedId: currentMatch['uid'] as String,
        isLike: isLike,
      );
      await _limitsService.recordSwipe(isLike: isLike);

      setState(() {
        _currentIndex++;
        _todaySwipes++;
      });

      // If we've gone through all matches, load more
      if (_currentIndex >= _potentialMatches.length) {
        await _loadPotentialMatches();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showSwipeLimitDialog() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: AppTheme.warning,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Límite alcanzado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Has alcanzado tu límite de $_dailyLimit me gustas diarios.',
              style: TextStyle(
                color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Actualiza a Premium para obtener me gustas ilimitados y muchas más ventajas.',
              style: TextStyle(
                color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PremiumScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Ver Premium'),
          ),
        ],
      ),
    );
  }

  void _showUndoLimitDialog() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Función Premium'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Deshacer swipes es una función exclusiva de Premium.',
              style: TextStyle(
                color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Actualiza a Premium para deshacer tus últimos swipes y muchas más funciones exclusivas.',
              style: TextStyle(
                color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PremiumScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Ver Premium'),
          ),
        ],
      ),
    );
  }

  Future<void> _activateBoost() async {
    final isBoosted = await _limitsService.isUserBoosted();
    if (isBoosted) {
      _showBoostActiveDialog();
      return;
    }

    final canBoost = await _limitsService.canUseBoost();
    if (!canBoost) {
      _showBoostLimitDialog();
      return;
    }

    // Show boost confirmation dialog
    _showBoostConfirmationDialog();
  }

  void _showBoostActiveDialog() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: AppTheme.accentOrange,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Boost activo'),
          ],
        ),
        content: Text(
          'Ya tienes un Boost activo. Tu perfil está destacado en este momento.',
          style: TextStyle(
            color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showBoostLimitDialog() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Límite alcanzado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Has alcanzado tu límite de Boosts semanales.',
              style: TextStyle(
                color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Actualiza a Premium para obtener más Boosts o espera hasta la próxima semana.',
              style: TextStyle(
                color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PremiumScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Ver Premium'),
          ),
        ],
      ),
    );
  }

  void _showBoostConfirmationDialog() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: AppTheme.accentOrange,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Activar Boost'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu perfil será destacado durante 30 minutos.',
              style: TextStyle(
                color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aparecerás primero en los resultados y recibirás más visitas.',
              style: TextStyle(
                color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _limitsService.recordBoost(durationMinutes: 30);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Ñ¡Boost activado! Tu perfil está destacado.'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
            ),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Descubrir',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppTheme.primaryBlue,
              ),
              onPressed: _loadPotentialMatches,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.rocket_launch_rounded,
                color: AppTheme.accentOrange,
              ),
              onPressed: _activateBoost,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: AppTheme.primaryBlue,
              ),
              onPressed: () {
                // TODO: Open filter screen
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Cargando perfiles...',
                    style: TextStyle(
                      color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 60,
                          color: AppTheme.error,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadPotentialMatches,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                      ),
                    ],
                  ),
                )
              : _potentialMatches.isEmpty
                  ? Center(
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
                              Icons.person_search_rounded,
                              size: 80,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No hay más perfiles',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vuelve más tarde para ver nuevos compañeros',
                            style: TextStyle(
                              color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: _loadPotentialMatches,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Actualizar'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _currentIndex < _potentialMatches.length
                      ? _buildSwipeCard(_potentialMatches[_currentIndex])
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  size: 80,
                                  color: AppTheme.success,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'ÑÂ¡Has visto todos los perfiles!',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Vuelve más tarde para ver nuevos compañeros',
                                style: TextStyle(
                                  color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                                ),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: _loadPotentialMatches,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Actualizar'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
    );
  }

  Widget _buildSwipeCard(Map<String, dynamic> userData) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final compatibility = (userData['compatibility'] as double?)?.toStringAsFixed(0) ?? '0';
    final profile = userData['profile'] as Map<String, dynamic>?;
    final photos = profile?['photos'] as List?;
    final bio = profile?['bio'] as String? ?? '';
    final interests = profile?['interests'] as List?;
    final name = userData['name'] as String? ?? 'Usuario';
    final age = profile?['age'] as num?;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  children: [
                    // Photo section
                    Expanded(
                      flex: 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                            ),
                            child: photos != null && photos.isNotEmpty
                                ? Image.network(
                                    photos.first as String,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.person_rounded,
                                          size: 100,
                                          color: Colors.white.withValues(alpha: 0.5),
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 100,
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                          ),
                          // Gradient overlay
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Compatibility badge
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.successGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.success.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$compatibility%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Info section
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (age != null)
                              Text(
                                '$age años',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 12),
                            if (bio.isNotEmpty)
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    bio,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            if (interests != null && interests.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: interests
                                    .take(5)
                                    .map((interest) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            interest.toString(),
                                            style: const TextStyle(
                                              color: AppTheme.primaryBlue,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.close_rounded,
                color: AppTheme.error,
                onPressed: () => _handleSwipe(false),
                heroTag: 'pass',
              ),
              _buildActionButton(
                icon: Icons.undo_rounded,
                color: AppTheme.warning,
                onPressed: () async {
                  // Check if user can undo swipe (Premium feature)
                  final canUndo = await _limitsService.canUndoSwipe();
                  if (!canUndo) {
                    _showUndoLimitDialog();
                    return;
                  }

                  try {
                    await _matchingService.undoSwipe();
                    setState(() {
                      if (_currentIndex > 0) _currentIndex--;
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                heroTag: 'undo',
              ),
              _buildSuperLikeButton(),
              _buildActionButton(
                icon: Icons.favorite_rounded,
                color: AppTheme.success,
                onPressed: () => _handleSwipe(true),
                heroTag: 'like',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String heroTag,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: heroTag,
        onPressed: onPressed,
        backgroundColor: color,
        elevation: 0,
        child: Icon(icon, size: 32),
      ),
    );
  }

  Widget _buildSuperLikeButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPink.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'superlike',
        onPressed: _handleSuperLike,
        backgroundColor: AppTheme.accentPink,
        elevation: 0,
        child: const Icon(Icons.star_rounded, size: 32),
      ),
    );
  }

  Future<void> _handleSuperLike() async {
    if (_currentIndex >= _potentialMatches.length) return;

    // Check if user can swipe
    final canSwipe = await _limitsService.canSwipe();
    if (!canSwipe) {
      _showSwipeLimitDialog();
      return;
    }

    final currentMatch = _potentialMatches[_currentIndex];
    
    try {
      await _matchingService.sendSuperLike(currentMatch['uid'] as String);
      await _limitsService.recordSwipe(isLike: true);

      setState(() {
        _currentIndex++;
        _todaySwipes++;
      });

      // If we've gone through all matches, load more
      if (_currentIndex >= _potentialMatches.length) {
        await _loadPotentialMatches();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ÑÂ¡Super Like enviado!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppTheme.accentPink,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}



