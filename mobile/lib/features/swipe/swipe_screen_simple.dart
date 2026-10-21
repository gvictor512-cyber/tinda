// ignore_for_file: unused_field
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/matching_service.dart';
import '../../services/limits_service.dart';
import '../../services/analytics_service.dart';
import '../../utils/secure_logger.dart';
import '../../config/theme.dart';
import '../../features/premium/premium_screen.dart';
import '../../features/filters/filters_screen.dart';
import '../chat/chat_list_screen_simple.dart';
import '../../app.dart';
import 'match_overlay.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});
  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with TickerProviderStateMixin {
  final MatchingService _matchingService = MatchingService();
  final LimitsService _limitsService = LimitsService();

  late final AnimationController _swipeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  // Single animation object — updated per swipe, never recreated mid-flight.
  // One permanent listener drives _cardPosition, so swipes can't stack
  // duplicate callbacks the way per-call CurvedAnimation listeners did.
  late Animation<Offset> _swipeAnimation =
      ConstantTween<Offset>(Offset.zero).animate(_swipeController);
  // Single source of truth for the card position (drag + fling animation).
  // Using a ValueNotifier avoids rebuilding the whole screen every frame.
  final ValueNotifier<Offset> _cardPosition = ValueNotifier(Offset.zero);
  int _currentPhotoIndex = 0;

  List<Map<String, dynamic>> _potentialMatches = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  int _todaySwipes = 0;
  int _dailyLimit = 15;
  bool _isSeeding = false;
  bool _autoSeedAttempted = false;
  bool _isSwipeInFlight = false;
  @override
  void initState() {
    super.initState();
    // The ONLY listener on the controller — routes animation frames into
    // _cardPosition. Per-call listeners leaked before and re-fired
    // _handleSwipe once per past swipe.
    _swipeController.addListener(() {
      _cardPosition.value = _swipeAnimation.value;
    });
    _loadPotentialMatches();
  }

  /// Whether this build may auto-seed demo data. Same gate that decides
  /// who can see seeded `isDemo` content: debug builds always; release
  /// only for the App Review demo account and the developer's own
  /// account so manual testing always has data.
  bool get _canAutoSeed => MatchingService.canSeeDemoContent;

  @override
  void dispose() {
    _cardPosition.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_swipeController.isAnimating || _isSwipeInFlight) return;
    _cardPosition.value += details.delta;
  }

  void _onDragEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final vx = details.velocity.pixelsPerSecond.dx;
    final dx = _cardPosition.value.dx;
    if (dx > screenWidth * 0.3 || vx > 800) {
      unawaited(_animateCardTo(
          Offset(screenWidth * 1.5, _cardPosition.value.dy),
          isLike: true));
    } else if (dx < -screenWidth * 0.3 || vx < -800) {
      unawaited(_animateCardTo(
          Offset(-screenWidth * 1.5, _cardPosition.value.dy),
          isLike: false));
    } else {
      unawaited(_animateCardTo(Offset.zero));
    }
  }

  /// Animates the top card to [target]. When [isLike] is provided the card
  /// flies off-screen and the swipe is recorded once the animation lands.
  /// [isSuperLike] routes the completion through _handleSuperLike instead.
  /// Awaits forward() directly — no per-call listeners that could stack.
  Future<void> _animateCardTo(Offset target,
      {bool? isLike, bool isSuperLike = false}) async {
    if (_swipeController.isAnimating || _isSwipeInFlight) return;
    if (isLike != null) _isSwipeInFlight = true;
    _swipeAnimation = Tween<Offset>(begin: _cardPosition.value, end: target)
        .animate(
            CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));
    var consumed = true;
    try {
      await _swipeController.forward(from: 0);
      if (isSuperLike) {
        consumed = await _handleSuperLike();
      } else if (isLike != null) {
        consumed = await _handleSwipe(isLike);
      }
    } on TickerCanceled {
      return;
    } finally {
      _isSwipeInFlight = false;
    }
    if (!mounted) return;
    if (consumed) {
      // Order matters: reset() fires the controller listener once more,
      // writing the OLD tween's `begin` (the drag-release offset) into
      // _cardPosition — the next card would appear displaced, stamped
      // with the previous LIKE/NOPE. Reset first, then center.
      _swipeController.reset();
      _cardPosition.value = Offset.zero;
      return;
    }
    // Swipe was rejected (e.g. daily limit): slide the card back to
    // center instead of leaving it off-screen or snapping it abruptly.
    _swipeAnimation = Tween<Offset>(begin: target, end: Offset.zero).animate(
        CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));
    try {
      await _swipeController.forward(from: 0);
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    _swipeController.reset();
    _cardPosition.value = Offset.zero;
  }

  /// Card fly-off triggered by the action buttons — same visual path as
  /// a real drag so taps feel identical to gestures.
  void _buttonSwipe(bool isLike) {
    final screenWidth = MediaQuery.of(context).size.width;
    _animateCardTo(
      Offset(isLike ? screenWidth * 1.5 : -screenWidth * 1.5,
          _cardPosition.value.dy),
      isLike: isLike,
    );
  }

  /// Super like sends the card flying upward, Tinder-style.
  void _buttonSuperLike() {
    final screenHeight = MediaQuery.of(context).size.height;
    _animateCardTo(
      Offset(_cardPosition.value.dx, -screenHeight * 1.2),
      isLike: true,
      isSuperLike: true,
    );
  }

  Future<void> _loadPotentialMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final (matches, todaySwipes, limits) = await (
        _matchingService.getPotentialMatches(),
        _limitsService.getTodaySwipes(),
        _limitsService.getUserLimits(),
      ).wait;

      setState(() {
        _potentialMatches = matches;
        _currentIndex = 0;
        _currentPhotoIndex = 0;
        _isLoading = false;
        _todaySwipes = todaySwipes;
        _dailyLimit = limits.dailySwipes == -1 ? 999 : limits.dailySwipes;
      });
      _precacheUpcomingPhotos();

      // Auto-seed when the deck is empty, holds stale demo profiles
      // (older seedVersion), or this account simply has no test
      // interactions yet (seed may have run under another account or
      // failed silently before the rules were fixed).
      if (_canAutoSeed && !_autoSeedAttempted) {
        final hasStaleDemo = matches.any((m) =>
            m['isDemo'] == true &&
            (m['seedVersion'] as num? ?? 0) < MatchingService.demoSeedVersion);
        final needsSeed = matches.isEmpty ||
            hasStaleDemo ||
            !await _matchingService.hasTestInteractions();
        if (needsSeed) {
          _autoSeedAttempted = true;
          await _matchingService.seedDemoProfiles();
          await _loadPotentialMatches();
        }
      }
    } catch (e) {
      SecureLogger.error('Failed to load potential matches', error: e);
      setState(() {
        // Friendly copy — raw exception text leaks internals to the UI.
        _errorMessage =
            'No se pudieron cargar los perfiles. Revisa tu conexión e inténtalo de nuevo.';
        _isLoading = false;
      });
    }
  }

  /// Records a swipe. Returns true when the swipe was consumed and the
  /// card can stay off-screen; false when it must return to the deck.
  Future<bool> _handleSwipe(bool isLike) async {
    if (_currentIndex >= _potentialMatches.length) return false;
    // Local limit check (synced on load) - avoids two Firestore reads per swipe
    if (!_canAutoSeed && _todaySwipes >= _dailyLimit) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PremiumScreen(),
          ),
        );
      }
      return false;
    }
    final currentMatch = _potentialMatches[_currentIndex];

    try {
      final isMatch = await _matchingService.recordSwipe(
        swipedId: currentMatch['uid'] as String,
        isLike: isLike,
      );
      unawaited(HapticFeedback.lightImpact());

      // Log analytics
      unawaited(AnalyticsService().logSwipe(
        isLike: isLike,
        profileId: currentMatch['uid'] as String,
      ));

      // Limits bookkeeping is secondary — never surface its errors
      // after the swipe itself already succeeded.
      try {
        await _limitsService.recordSwipe(isLike: isLike);
      } catch (e) {
        debugPrint('Limits recordSwipe failed: $e');
      }
      setState(() {
        _currentIndex++;
        _currentPhotoIndex = 0;
        _todaySwipes++;
      });
      _precacheUpcomingPhotos();
      if (isMatch && mounted) {
        unawaited(HapticFeedback.mediumImpact());
        _showMatchOverlay(currentMatch);
      }
      // If we've gone through all matches, load more
      if (_currentIndex >= _potentialMatches.length) {
        await _loadPotentialMatches();
      }
      return true;
    } catch (e) {
      SecureLogger.error('Swipe failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'No se pudo registrar el swipe. Inténtalo de nuevo.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return false;
    }
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
                color: isDarkMode
                    ? AppTheme.textLightSecondary
                    : AppTheme.textDarkSecondary,
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
                color: AppTheme.secondaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: AppTheme.secondaryPurple,
                size: 40,
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
                color: isDarkMode
                    ? AppTheme.textLightSecondary
                    : AppTheme.textDarkSecondary,
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
                color: AppTheme.secondaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: AppTheme.secondaryPurple,
                size: 40,
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
                color: isDarkMode
                    ? AppTheme.textLightSecondary
                    : AppTheme.textDarkSecondary,
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
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          '¡Boost activado! Tu perfil está destacado.'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                SecureLogger.error('Boost activation failed', error: e);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'No se pudo activar el boost. Inténtalo de nuevo.'),
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
              backgroundColor: AppTheme.secondaryPurple,
            ),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }

  Future<void> _seedDemoProfiles() async {
    if (_isSeeding) return;
    setState(() => _isSeeding = true);
    try {
      final created = await _matchingService.seedDemoProfiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$created perfiles de prueba creados')),
        );
      }
      await _loadPotentialMatches();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creando perfiles: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _isLoading
                  ? _buildCardSkeleton(isDarkMode)
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
                                  color: isDarkMode
                                      ? AppTheme.textLight
                                      : AppTheme.textDark,
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 16),
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
                                      color: AppTheme.primaryBlue
                                          .withValues(alpha: 0.1),
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
                                      color: isDarkMode
                                          ? AppTheme.textLight
                                          : AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Vuelve más tarde para ver nuevos compañeros',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? AppTheme.textLightSecondary
                                          : AppTheme.textDarkSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  ElevatedButton.icon(
                                    onPressed: _loadPotentialMatches,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Actualizar'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                    ),
                                  ),
                                  if (kDebugMode) ...[
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed:
                                          _isSeeding ? null : _seedDemoProfiles,
                                      icon: const Icon(Icons.group_add_rounded),
                                      label: Text(_isSeeding
                                          ? 'Creando...'
                                          : 'Generar perfiles de prueba'),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : _currentIndex < _potentialMatches.length
                              ? _buildSwipeCard(
                                  _potentialMatches[_currentIndex])
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: AppTheme.success
                                              .withValues(alpha: 0.1),
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
                                        '¡Has visto todos los perfiles!',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? AppTheme.textLight
                                              : AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Vuelve más tarde para ver nuevos compañeros',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? AppTheme.textLightSecondary
                                              : AppTheme.textDarkSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      ElevatedButton.icon(
                                        onPressed: _loadPotentialMatches,
                                        icon: const Icon(Icons.refresh_rounded),
                                        label: const Text('Actualizar'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 32, vertical: 16),
                                        ),
                                      ),
                                      if (kDebugMode) ...[
                                        const SizedBox(height: 12),
                                        TextButton.icon(
                                          onPressed: _isSeeding
                                              ? null
                                              : _seedDemoProfiles,
                                          icon: const Icon(
                                              Icons.group_add_rounded),
                                          label: Text(_isSeeding
                                              ? 'Creando...'
                                              : 'Generar perfiles de prueba'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(Map<String, dynamic> userData) {
    final reasons = [
      'Contenido inapropiado',
      'Perfil falso',
      'Spam',
      'Comportamiento abusivo',
      'Otro',
    ];

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Reportar perfil'),
        children: [
          ...reasons.map((reason) => SimpleDialogOption(
                child: Text(reason),
                onPressed: () {
                  Navigator.of(context).pop();
                  _reportUser(userData, reason);
                },
              )),
          SimpleDialogOption(
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _reportUser(Map<String, dynamic> userData, String reason) async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': FirebaseAuth.instance.currentUser?.uid,
        'reportedId': userData['uid'] as String?,
        'reason': reason,
        'status': 'open',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Log analytics
      unawaited(AnalyticsService().logReport(
        reportedId: userData['uid'] as String? ?? '',
        reason: reason,
        reporterId: FirebaseAuth.instance.currentUser?.uid,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte enviado. Gracias.')),
        );
      }
    } catch (e) {
      SecureLogger.error('Report failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('No se pudo enviar el reporte. Inténtalo de nuevo.')),
        );
      }
    }
  }

  Future<void> _blockUser(Map<String, dynamic> userData) async {
    final userId = userData['uid'] as String?;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (userId == null || currentUser == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear usuario'),
        content: const Text(
          '¿Bloquear a este usuario? No volverás a verlo ni a recibir mensajes suyos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'blockedUsers': FieldValue.arrayUnion([userId]),
      });
      // Also write to blocked_users collection so isBlocked() checks (messaging) work
      await FirebaseFirestore.instance.collection('blocked_users').add({
        'blockerId': currentUser.uid,
        'blockedId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _potentialMatches.removeWhere((m) => m['uid'] == userId);
          _currentIndex = _currentIndex.clamp(0, _potentialMatches.length - 1);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario bloqueado.')),
        );
      }
    } catch (e) {
      SecureLogger.error('Block failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('No se pudo bloquear al usuario. Inténtalo de nuevo.')),
        );
      }
    }
  }

  void _precacheUpcomingPhotos() {
    if (!mounted) return;
    for (int i = _currentIndex + 1;
        i < _potentialMatches.length && i <= _currentIndex + 2;
        i++) {
      final profile = _potentialMatches[i]['profile'] as Map<String, dynamic>?;
      final photos = profile?['photos'] as List?;
      if (photos == null) continue;
      for (final photo in photos.take(2)) {
        if (photo is String) {
          precacheImage(CachedNetworkImageProvider(photo), context).ignore();
        }
      }
    }
  }

  Widget _buildCardSkeleton(bool isDarkMode) {
    final cardBg = isDarkMode ? AppTheme.darkSurface : Colors.white;
    final block =
        isDarkMode ? const Color(0xFF2E2E47) : const Color(0xFFE2E8F0);
    Widget line(double width, double height) => Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: block,
            borderRadius: BorderRadius.circular(8),
          ),
        );
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(color: block),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      line(170, 22),
                      const SizedBox(height: 12),
                      line(240, 14),
                      const SizedBox(height: 8),
                      line(200, 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Full-screen match celebration. The overlay itself runs the
  /// animation (floating hearts, spring entrance, pulsing badge) and
  /// offers three exits: open the chat directly, jump to the Mensajes
  /// tab, or keep swiping.
  void _showMatchOverlay(Map<String, dynamic> otherUser) {
    final profile = otherUser['profile'] as Map<String, dynamic>?;
    final photos = profile?['photos'] as List?;
    final otherPhoto =
        photos != null && photos.isNotEmpty ? photos.first as String : null;
    final otherName = otherUser['name'] as String? ?? 'Usuario';
    final otherUid = otherUser['uid'] as String;
    final myPhoto = FirebaseAuth.instance.currentUser?.photoURL;

    showGeneralDialog(
      context: context,
      // The overlay paints its own full-screen gradient; a button must
      // decide where the user lands next, so barrier taps don't dismiss.
      barrierDismissible: false,
      barrierLabel: 'match',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim, anim2) {
        return MatchOverlay(
          otherName: otherName,
          myPhotoUrl: myPhoto,
          otherPhotoUrl: otherPhoto,
          onSendMessage: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  userId: otherUid,
                  userName: otherName,
                  userPhoto: otherPhoto,
                ),
              ),
            );
          },
          onViewChats: () {
            Navigator.of(dialogContext).pop();
            MainScreen.selectTab(MainScreen.tabMessages);
          },
          onKeepSwiping: () => Navigator.of(dialogContext).pop(),
        );
      },
      transitionBuilder: (context, anim, anim2, child) {
        return FadeTransition(
          opacity: anim,
          child: child,
        );
      },
    );
  }

  Widget _buildSwipeCard(Map<String, dynamic> userData) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final compatibility =
        (userData['compatibility'] as double?)?.toStringAsFixed(0) ?? '0';
    final profile = userData['profile'] as Map<String, dynamic>?;
    final personalPhotos = profile?['photos'] as List?;
    final apartment = userData['apartment'] as Map<String, dynamic>?;
    final propertyPhotos = apartment?['photos'] as List?;
    final personalCount = personalPhotos?.length ?? 0;
    final photos = <dynamic>[
      ...?personalPhotos,
      ...?propertyPhotos,
    ];
    final name = userData['name'] as String? ?? 'Usuario';
    final age = profile?['age'] as num?;
    final city = profile?['city'] as String? ?? '';
    final bio = profile?['bio'] as String? ?? '';
    final interests = (profile?['interests'] as List?) ?? const [];
    final distanceKm = (userData['distanceKm'] as num?)?.toDouble();
    final isNear = distanceKm != null && distanceKm <= 10;
    final distanceLabel = distanceKm != null
        ? (distanceKm < 1
            ? 'A menos de 1 km de distancia'
            : 'A ${distanceKm.round()} km de distancia')
        : null;
    final textColor = isDarkMode ? AppTheme.textLight : AppTheme.textDark;
    final secondary =
        isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: AnimatedBuilder(
                animation: _cardPosition,
                builder: (context, card) {
                  final offset = _cardPosition.value;
                  return Transform.translate(
                    offset: offset,
                    child: Transform.rotate(
                      angle: offset.dx / 2000,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          card!,
                          if (offset.dx.abs() > 8)
                            Positioned(
                              top: 28,
                              left: offset.dx > 0 ? 24 : null,
                              right: offset.dx > 0 ? null : 24,
                              child: Transform.rotate(
                                angle: offset.dx > 0 ? -0.4 : 0.4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: offset.dx > 0
                                          ? AppTheme.success
                                          : AppTheme.error,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    offset.dx > 0 ? 'LIKE' : 'NOPE',
                                    style: TextStyle(
                                      color: offset.dx > 0
                                          ? AppTheme.success
                                          : AppTheme.error,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                child: RepaintBoundary(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDarkMode ? 0.3 : 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: ColoredBox(
                        color: isDarkMode ? AppTheme.darkSurface : Colors.white,
                        // Perfil completo desplegado: se baja con scroll
                        // para ver bio, intereses, vivienda y todas las fotos.
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            // Foto principal con overlay de nombre/info
                            _cardPhoto(
                              url: photos.isNotEmpty
                                  ? photos[0] as String
                                  : null,
                              isProperty: personalCount == 0,
                              overlay: Stack(
                                children: [
                                  // Degradado inferior estilo Tinder
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 220,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black
                                                .withValues(alpha: 0.85),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Badge de compatibilidad
                                  Positioned(
                                    top: 16,
                                    right: 14,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.successGradient,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.success
                                                .withValues(alpha: 0.4),
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
                                            size: 15,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '$compatibility%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Info del perfil sobre la foto
                                  Positioned(
                                    left: 18,
                                    right: 18,
                                    bottom: 20,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isNear)
                                          Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Text(
                                              'Cerca',
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                            ),
                                            if (age != null) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                '$age',
                                                style: const TextStyle(
                                                  fontSize: 27,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (city.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          _buildCardInfoLine(
                                            Icons.home_rounded,
                                            'Vive en $city',
                                          ),
                                        ],
                                        if (distanceLabel != null) ...[
                                          const SizedBox(height: 4),
                                          _buildCardInfoLine(
                                            Icons.location_on_rounded,
                                            distanceLabel,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Secciones del perfil
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (bio.isNotEmpty) ...[
                                    _cardSectionTitle('Sobre mí', textColor),
                                    const SizedBox(height: 6),
                                    Text(
                                      bio,
                                      style: TextStyle(
                                        color: secondary,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  if (interests.isNotEmpty) ...[
                                    _cardSectionTitle('Intereses', textColor),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: interests
                                          .map(
                                            (interest) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryBlue
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: AppTheme.primaryBlue
                                                      .withValues(alpha: 0.2),
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
                                            ),
                                          )
                                          .toList(),
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  if (apartment != null) ...[
                                    _cardSectionTitle('Vivienda', textColor),
                                    const SizedBox(height: 8),
                                    if ((apartment['title'] as String? ?? '')
                                        .isNotEmpty)
                                      _detailLine(
                                        Icons.home_work_rounded,
                                        apartment['title'] as String,
                                        secondary,
                                      ),
                                    if (apartment['price'] != null)
                                      _detailLine(
                                        Icons.euro_rounded,
                                        '${apartment['price']}€ / mes',
                                        secondary,
                                      ),
                                    if ((apartment['location'] as String? ?? '')
                                        .isNotEmpty)
                                      _detailLine(
                                        Icons.place_rounded,
                                        apartment['location'] as String,
                                        secondary,
                                      ),
                                    if ((apartment['description'] as String? ??
                                            '')
                                        .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          apartment['description'] as String,
                                          style: TextStyle(
                                            color: secondary,
                                            fontSize: 14,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 18),
                                  ],
                                ],
                              ),
                            ),
                            // Resto de fotos en cascada — con badge
                            // "Vivienda" cuando son del inmueble
                            for (var i = 1; i < photos.length; i++)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: _cardPhoto(
                                    url: photos[i] as String,
                                    isProperty: i >= personalCount,
                                  ),
                                ),
                              ),
                            // Reportar / bloquear al final del perfil
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                              child: Column(
                                children: [
                                  Divider(
                                    color: secondary.withValues(alpha: 0.25),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () =>
                                            _showReportDialog(userData),
                                        icon: const Icon(
                                          Icons.flag_outlined,
                                          color: AppTheme.error,
                                          size: 20,
                                        ),
                                        label: const Text(
                                          'Reportar',
                                          style:
                                              TextStyle(color: AppTheme.error),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _blockUser(userData),
                                        icon: const Icon(
                                          Icons.block,
                                          color: AppTheme.error,
                                          size: 20,
                                        ),
                                        label: const Text(
                                          'Bloquear',
                                          style:
                                              TextStyle(color: AppTheme.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Botones de acción estilo Tinder
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCircleButton(
                icon: Icons.undo_rounded,
                color: AppTheme.warning,
                size: 46,
                iconSize: 24,
                onPressed: _onUndoPressed,
              ),
              _buildCircleButton(
                icon: Icons.close_rounded,
                color: AppTheme.accentPink,
                size: 60,
                iconSize: 34,
                onPressed: () => _buttonSwipe(false),
              ),
              _buildCircleButton(
                icon: Icons.star_rounded,
                color: AppTheme.primaryBlue,
                size: 50,
                iconSize: 28,
                onPressed: _buttonSuperLike,
              ),
              _buildCircleButton(
                icon: Icons.favorite_rounded,
                color: AppTheme.primaryGreen,
                size: 60,
                iconSize: 32,
                onPressed: () => _buttonSwipe(true),
              ),
              _buildCircleButton(
                icon: Icons.rocket_launch_rounded,
                color: AppTheme.secondaryPurple,
                size: 46,
                iconSize: 26,
                onPressed: _activateBoost,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardInfoLine(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Botón circular de acción — fill surface, icono con color de marca.
  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 52,
    double iconSize = 26,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        customBorder: const CircleBorder(),
        splashColor: color.withValues(alpha: 0.2),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppTheme.darkSurface : Colors.white,
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
      ),
    );
  }

  /// Barra superior estilo Tinder: filtros a la izquierda, pestaña
  /// "Para ti" centrada y accesos rápidos a la derecha.
  Widget _buildTopBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Row(
        children: [
          _buildTopIconButton(
            icon: Icons.tune_rounded,
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => const FiltersScreen(),
                    ),
                  )
                  .then((_) => _loadPotentialMatches());
            },
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue
                  .withValues(alpha: isDarkMode ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Para ti',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const Spacer(),
          _buildTopIconButton(
            icon: Icons.refresh_rounded,
            color: AppTheme.primaryBlue,
            onPressed: _loadPotentialMatches,
          ),
          const SizedBox(width: 10),
          _buildTopIconButton(
            icon: Icons.rocket_launch_rounded,
            color: AppTheme.secondaryPurple,
            onPressed: _activateBoost,
          ),
          if (kDebugMode) ...[
            const SizedBox(width: 10),
            _buildTopIconButton(
              icon: Icons.group_add_rounded,
              color: AppTheme.accentPink,
              onPressed: _isSeeding ? () {} : _seedDemoProfiles,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDarkMode ? AppTheme.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: color ?? (isDarkMode ? AppTheme.textLight : AppTheme.textDark),
        ),
        iconSize: 21,
        splashRadius: 22,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        onPressed: onPressed,
      ),
    );
  }

  /// Una foto del perfil dentro del scroll de la tarjeta (ratio 4:5),
  /// con badge "Vivienda" opcional y overlay libre (usado en la primera
  /// foto para nombre, edad, ciudad…).
  Widget _cardPhoto({
    required String? url,
    required bool isProperty,
    Widget? overlay,
  }) {
    return AspectRatio(
      aspectRatio: 0.8,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: url != null
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    memCacheWidth: 1080,
                    fadeInDuration: const Duration(milliseconds: 200),
                    progressIndicatorBuilder: (context, url, progress) =>
                        Center(
                      child: CircularProgressIndicator(
                        value: progress.progress,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.person_rounded,
                      size: 100,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
          ),
          if (isProperty)
            Positioned(
              top: 16,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Vivienda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (overlay != null) overlay,
        ],
      ),
    );
  }

  /// Título de sección dentro del scroll del perfil ("Sobre mí",
  /// "Intereses", "Vivienda").
  Widget _cardSectionTitle(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  /// Deshace el último swipe (función Premium).
  Future<void> _onUndoPressed() async {
    if (_currentIndex <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hay ningún swipe que deshacer'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    final canUndo = await _limitsService.canUndoSwipe();
    if (!mounted) return;
    if (!canUndo) {
      _showUndoLimitDialog();
      return;
    }
    try {
      await _matchingService.undoSwipe();
      if (!mounted) return;
      setState(() {
        _currentIndex--;
        if (_todaySwipes > 0) _todaySwipes--;
        _currentPhotoIndex = 0;
      });
    } catch (e) {
      SecureLogger.error('Undo swipe failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo deshacer. Inténtalo de nuevo.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _detailLine(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 14.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Sends a super like. Same consumed/not-consumed contract as
  /// [_handleSwipe].
  Future<bool> _handleSuperLike() async {
    if (_currentIndex >= _potentialMatches.length) return false;
    // Local limit check (synced on load) - avoids two Firestore reads per swipe
    if (!_canAutoSeed && _todaySwipes >= _dailyLimit) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PremiumScreen(),
          ),
        );
      }
      return false;
    }
    final currentMatch = _potentialMatches[_currentIndex];

    try {
      await _matchingService.sendSuperLike(currentMatch['uid'] as String);
      unawaited(HapticFeedback.lightImpact());
      await _limitsService.recordSwipe(isLike: true);
      setState(() {
        _currentIndex++;
        _currentPhotoIndex = 0;
        _todaySwipes++;
      });
      _precacheUpcomingPhotos();
      // If we've gone through all matches, load more
      if (_currentIndex >= _potentialMatches.length) {
        await _loadPotentialMatches();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Super Like enviado!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppTheme.accentPink,
          ),
        );
      }
      return true;
    } catch (e) {
      SecureLogger.error('Super like failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'No se pudo enviar el super like. Inténtalo de nuevo.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return false;
    }
  }
}
