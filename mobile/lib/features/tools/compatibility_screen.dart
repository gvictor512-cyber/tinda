import 'package:flutter/material.dart';
import '../../config/theme.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  final Map<String, int> _answers = {};

  final List<Map<String, dynamic>> _questions = const [
    {
      'key': 'cleaning',
      'question': '¿Qué tan ordenado/a eres?',
      'options': ['Muy ordenado', 'Ordenado', 'Desordenado'],
    },
    {
      'key': 'schedule',
      'question': '¿Qué horario sigues?',
      'options': ['Madrugador', 'Horario regular', 'Nocturno'],
    },
    {
      'key': 'parties',
      'question': '¿Con qué frecuencia haces fiestas?',
      'options': ['Nunca', 'A veces', 'Frecuentemente'],
    },
    {
      'key': 'pets',
      'question': '¿Qué opinas de las mascotas?',
      'options': ['Me encantan', 'Indiferente', 'No quiero'],
    },
    {
      'key': 'remote',
      'question': '¿Trabajas desde casa?',
      'options': ['Siempre', 'A veces', 'Nunca'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compatibilidad IA'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Cuestionario de convivencia',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Responde y descubre tu compatibilidad con potenciales compañeros.',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ..._questions.map((q) => _buildQuestion(q, isDarkMode)),
          const SizedBox(height: 24),
          _buildResultCard(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildQuestion(Map<String, dynamic> question, bool isDarkMode) {
    final key = question['key'] as String;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'] as String,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (question['options'] as List<dynamic>).map<Widget>((option) {
            final isSelected = _answers[key] == option.hashCode;
            return FilterChip(
              label: Text(option as String),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _answers[key] = option.hashCode;
                });
              },
              selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primaryBlue,
              labelStyle: TextStyle(
                color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResultCard(bool isDarkMode) {
    final percentage = _answers.length == _questions.length
        ? (_answers.values.reduce((a, b) => a + b) % 100).abs()
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.psychology,
            size: 48,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(height: 12),
          Text(
            'Match de convivencia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _answers.length == _questions.length
                ? '$percentage% de compatibilidad estimada'
                : 'Completa todas las preguntas para calcular tu match',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
