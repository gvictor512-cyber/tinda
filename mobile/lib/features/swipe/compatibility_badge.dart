import 'package:flutter/material.dart';

class CompatibilityBadge extends StatelessWidget {
  final int score;

  const CompatibilityBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(score);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 2,
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
          const SizedBox(width: 4),
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
    if (score >= 85) return const Color(0xFF27AE60);
    if (score >= 70) return const Color(0xFF4A90E2);
    if (score >= 50) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  IconData _getScoreIcon(int score) {
    if (score >= 85) return Icons.star;
    if (score >= 70) return Icons.thumb_up;
    if (score >= 50) return Icons.remove;
    return Icons.warning;
  }
}
