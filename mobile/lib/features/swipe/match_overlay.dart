import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Full-screen celebratory overlay shown when two users match.
///
/// The background paints a brand gradient with floating hearts rising
/// endlessly, the title pops in with a spring, both avatars slide in
/// from opposite sides and the action buttons fade in last.
class MatchOverlay extends StatefulWidget {
  final String otherName;
  final String? myPhotoUrl;
  final String? otherPhotoUrl;
  final VoidCallback onSendMessage;
  final VoidCallback onViewChats;
  final VoidCallback onKeepSwiping;

  const MatchOverlay({
    super.key,
    required this.otherName,
    required this.onSendMessage,
    required this.onViewChats,
    required this.onKeepSwiping,
    this.myPhotoUrl,
    this.otherPhotoUrl,
  });

  @override
  State<MatchOverlay> createState() => _MatchOverlayState();
}

class _HeartSpec {
  final double x;
  final double size;
  final double delay;
  final double drift;
  final Color color;

  const _HeartSpec({
    required this.x,
    required this.size,
    required this.delay,
    required this.drift,
    required this.color,
  });
}

class _MatchOverlayState extends State<MatchOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  // Endless loop driving the floating hearts.
  late final AnimationController _hearts = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  // Heartbeat pulse behind the title.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  late final List<_HeartSpec> _heartSpecs = _buildHearts();

  static List<_HeartSpec> _buildHearts() {
    final random = Random();
    return List.generate(
      16,
      (i) => _HeartSpec(
        x: random.nextDouble(),
        size: 12 + random.nextDouble() * 22,
        delay: random.nextDouble(),
        drift: (random.nextDouble() - 0.5) * 0.12,
        color: i.isEven ? Colors.white : AppTheme.accentPink,
      ),
    );
  }

  @override
  void dispose() {
    _entry.dispose();
    _hearts.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Animation<double> _staggered(double start, double end, Curve curve) {
    return CurvedAnimation(
      parent: _entry,
      curve: Interval(start, end, curve: curve),
    );
  }

  Widget _buildFloatingHearts() {
    return AnimatedBuilder(
      animation: _hearts,
      builder: (context, _) {
        final size = MediaQuery.of(context).size;
        return Stack(
          fit: StackFit.expand,
          children: [
            for (final heart in _heartSpecs)
              _positionedHeart(heart, size),
          ],
        );
      },
    );
  }

  Widget _positionedHeart(_HeartSpec heart, Size size) {
    final progress = (_hearts.value + heart.delay) % 1.0;
    // Fade in at the bottom, out near the top.
    final opacity = (progress < 0.15)
        ? progress / 0.15
        : (progress > 0.75 ? (1 - progress) / 0.25 : 1.0);
    final wobble = sin(progress * 2 * pi) * heart.drift * size.width;
    return Positioned(
      left: heart.x * size.width + wobble,
      top: size.height * (1.05 - progress * 1.2),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0) * 0.7,
        child: Icon(
          Icons.favorite_rounded,
          size: heart.size,
          color: heart.color,
        ),
      ),
    );
  }

  late final Animation<Offset> _myAvatarSlide = Tween<Offset>(
    begin: const Offset(-1.6, 0),
    end: Offset.zero,
  ).animate(_staggered(0.25, 0.75, Curves.easeOutBack));

  late final Animation<Offset> _otherAvatarSlide = Tween<Offset>(
    begin: const Offset(1.6, 0),
    end: Offset.zero,
  ).animate(_staggered(0.3, 0.8, Curves.easeOutBack));

  @override
  Widget build(BuildContext context) {
    final titleScale = _staggered(0.0, 0.55, Curves.elasticOut);
    final subtitleFade = _staggered(0.45, 0.8, Curves.easeOut);
    final buttonsFade = _staggered(0.6, 1.0, Curves.easeOut);

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient scrim
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryBlueDark,
                  AppTheme.primaryBlue,
                  AppTheme.secondaryPurple,
                ],
              ),
            ),
          ),
          // Floating hearts
          _buildFloatingHearts(),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Pulsing heart badge
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ScaleTransition(
                    scale: titleScale,
                    child: const Text(
                      '¡Es un match!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: subtitleFade,
                    child: Text(
                      'Tú y ${widget.otherName} os habéis gustado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Both avatars slide in and overlap in the middle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SlideTransition(
                        position: _myAvatarSlide,
                        child: _avatar(widget.myPhotoUrl),
                      ),
                      Transform.translate(
                        offset: const Offset(-16, 0),
                        child: SlideTransition(
                          position: _otherAvatarSlide,
                          child: _avatar(widget.otherPhotoUrl),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: buttonsFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: widget.onSendMessage,
                          icon: const Icon(Icons.chat_bubble_rounded),
                          label: const Text('Enviar mensaje'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryBlueDark,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: widget.onViewChats,
                          icon: const Icon(Icons.forum_outlined),
                          label: const Text('Ver mis conversaciones'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onKeepSwiping,
                          child: const Text(
                            'Seguir explorando',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String? photoUrl) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 52,
        backgroundColor: Colors.white.withValues(alpha: 0.25),
        backgroundImage: photoUrl != null
            ? CachedNetworkImageProvider(photoUrl, maxWidth: 240)
            : null,
        child: photoUrl == null
            ? const Icon(Icons.person_rounded, size: 48, color: Colors.white)
            : null,
      ),
    );
  }
}
