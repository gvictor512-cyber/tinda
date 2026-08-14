import 'package:flutter/material.dart';

class CompatibilitySettingsScreen extends StatefulWidget {
  const CompatibilitySettingsScreen({super.key});

  @override
  State<CompatibilitySettingsScreen> createState() => _CompatibilitySettingsScreenState();
}

class _CompatibilitySettingsScreenState extends State<CompatibilitySettingsScreen> {
  bool _isLoading = false;
  bool _isSaving = false;

  // Schedule
  String? _scheduleType;
  final List<String> _scheduleOptions = [
    'madrugador', 'nocturno', 'trabajo_remoto', 'turnos', 'estudiante'
  ];

  // Cleanliness
  int _cleanlinessLevel = 3;

  // Smoking
  String? _smokingPreference;
  final List<String> _smokingOptions = ['no_fuma', 'fuma_fuera', 'fuma_dentro'];

  // Pets
  String? _petsPreference;
  final List<String> _petsOptions = [
    'me_encantan', 'tengo_mascotas', 'no_quiero_mascotas', 'soy_alergico'
  ];

  // Personality traits
  final List<String> _personalityTraits = [];
  final List<String> _availableTraits = [
    'Deportista', 'Gamer', 'Cocinar', 'Cine', 'Música', 'Viajar',
    'Lectura', 'Fiesta', 'Tranquilo', 'Sociable'
  ];

  // Living habits
  String? _guestsFrequency;
  final List<String> _frequencyOptions = ['nunca', 'a_veces', 'frecuentemente'];

  String? _cookingFrequency;
  String? _musicVolume;
  bool _workFromHome = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Load settings from Firestore
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      // TODO: Save to Firestore
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Compatibilidad'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Schedule
            _buildSectionTitle('Horarios'),
            const SizedBox(height: 12),
            _buildRadioGroup(
              '¿Cuál es tu horario habitual?',
              _scheduleOptions,
              _scheduleType,
              (value) => setState(() => _scheduleType = value),
              labels: const {
                'madrugador': 'Madrugador',
                'nocturno': 'Nocturno',
                'trabajo_remoto': 'Trabajo remoto',
                'turnos': 'Turnos',
                'estudiante': 'Estudiante',
              },
            ),
            const SizedBox(height: 24),

            // Cleanliness
            _buildSectionTitle('Limpieza'),
            const SizedBox(height: 12),
            Text(
              'Nivel de orden: $_cleanlinessLevel',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _cleanlinessLevel.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: _getCleanlinessLabel(_cleanlinessLevel),
              onChanged: (value) {
                setState(() => _cleanlinessLevel = value.toInt());
              },
            ),
            Text(
              _getCleanlinessDescription(_cleanlinessLevel),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Smoking
            _buildSectionTitle('Tabaco'),
            const SizedBox(height: 12),
            _buildRadioGroup(
              '¿Fumas?',
              _smokingOptions,
              _smokingPreference,
              (value) => setState(() => _smokingPreference = value),
              labels: const {
                'no_fuma': 'No fumo',
                'fuma_fuera': 'Fumo fuera',
                'fuma_dentro': 'Fumo dentro',
              },
            ),
            const SizedBox(height: 24),

            // Pets
            _buildSectionTitle('Mascotas'),
            const SizedBox(height: 12),
            _buildRadioGroup(
              '¿Qué opinas de las mascotas?',
              _petsOptions,
              _petsPreference,
              (value) => setState(() => _petsPreference = value),
              labels: const {
                'me_encantan': 'Me encantan',
                'tengo_mascotas': 'Tengo mascotas',
                'no_quiero_mascotas': 'No quiero mascotas',
                'soy_alergico': 'Soy alérgico',
              },
            ),
            const SizedBox(height: 24),

            // Personality
            _buildSectionTitle('Personalidad e Intereses'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTraits.map((trait) {
                final isSelected = _personalityTraits.contains(trait);
                return FilterChip(
                  label: Text(trait),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _personalityTraits.add(trait);
                      } else {
                        _personalityTraits.remove(trait);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF4A90E2).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF4A90E2),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Living habits
            _buildSectionTitle('Hábitos de Convivencia'),
            const SizedBox(height: 12),
            _buildRadioGroup(
              '¿Invitas gente a casa?',
              _frequencyOptions,
              _guestsFrequency,
              (value) => setState(() => _guestsFrequency = value),
              labels: const {
                'nunca': 'Nunca',
                'a_veces': 'A veces',
                'frecuentemente': 'Frecuentemente',
              },
            ),
            const SizedBox(height: 16),
            _buildRadioGroup(
              '¿Te gusta cocinar?',
              _frequencyOptions,
              _cookingFrequency,
              (value) => setState(() => _cookingFrequency = value),
              labels: const {
                'nunca': 'Nunca',
                'ocasionalmente': 'Ocasionalmente',
                'todos_los_dias': 'Todos los días',
              },
            ),
            const SizedBox(height: 16),
            _buildRadioGroup(
              '¿Escuchas música alta?',
              ['nunca', 'a_veces', 'mucho'],
              _musicVolume,
              (value) => setState(() => _musicVolume = value),
              labels: const {
                'nunca': 'Nunca',
                'a_veces': 'A veces',
                'mucho': 'Mucho',
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Trabajo desde casa'),
              subtitle: const Text('Teletrabajo o trabajo remoto'),
              value: _workFromHome,
              onChanged: (value) {
                setState(() => _workFromHome = value);
              },
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF4A90E2),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Guardar Configuración',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildRadioGroup(
    String question,
    List<String> options,
    String? selectedValue,
    Function(String) onChanged, {
    Map<String, String>? labels,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ...options.map((option) {
          return RadioListTile<String>(
            title: Text(labels?[option] ?? option),
            value: option,
            groupValue: selectedValue,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  String _getCleanlinessLabel(int level) {
    switch (level) {
      case 1: return 'Muy relajado';
      case 2: return 'Relajado';
      case 3: return 'Normal';
      case 4: return 'Ordenado';
      case 5: return 'Extremadamente ordenado';
      default: return '';
    }
  }

  String _getCleanlinessDescription(int level) {
    switch (level) {
      case 1: return 'No me importa el desorden';
      case 2: return 'Prefiero mantener cierto orden pero no soy estricto';
      case 3: return 'Equilibrio entre orden y flexibilidad';
      case 4: return 'Mantengo todo ordenado y limpio';
      case 5: return 'Todo debe estar siempre perfecto';
      default: return '';
    }
  }
}
