import 'package:flutter/material.dart';
import '../../config/theme.dart';

class CompatibilityBadge extends StatelessWidget {
  final int score;

  const CompatibilityBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getScoreIcon(score),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$score%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return AppTheme.primaryGreen;
    if (score >= 70) return AppTheme.primaryBlue;
    if (score >= 50) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  IconData _getScoreIcon(int score) {
    if (score >= 85) return Icons.favorite;
    if (score >= 70) return Icons.favorite;
    if (score >= 50) return Icons.remove;
    return Icons.warning;
  }
}
