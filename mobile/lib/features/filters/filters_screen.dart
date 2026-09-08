import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Age range
  RangeValues _ageRange = const RangeValues(18, 40);

  // Max distance (km)
  double _maxDistance = 50;

  // Budget range
  RangeValues _budgetRange = const RangeValues(300, 1000);

  // Gender
  String? _selectedGender;

  // Smoking
  final List<String> _smokingPreferences = [];
  final List<String> _smokingOptions = ['No fumador', 'Fuma fuera', 'Fuma dentro'];

  // Pets
  final List<String> _petsPreferences = [];
  final List<String> _petsOptions = [
    'Me encantan', 'Tengo mascotas', 'No quiero mascotas', 'Soy alérgico',
  ];

  // Work from home
  bool? _workFromHome;

  // Languages
  final List<String> _selectedLanguages = [];
  final List<String> _availableLanguages = [
    'Español', 'Inglés', 'Francés', 'Alemán', 'Italiano', 'Portugués',
    'Catalán', 'Euskera', 'Gallego',
  ];

  // User type
  final List<String> _userTypes = [];
  final List<String> _userTypeOptions = ['Estudiante', 'Profesional', 'Nómada digital'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtros'),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAgeFilter(),
          const SizedBox(height: 24),
          _buildDistanceFilter(),
          const SizedBox(height: 24),
          _buildBudgetFilter(),
          const SizedBox(height: 24),
          _buildGenderFilter(),
          const SizedBox(height: 24),
          _buildSmokingFilter(),
          const SizedBox(height: 24),
          _buildPetsFilter(),
          const SizedBox(height: 24),
          _buildWorkFromHomeFilter(),
          const SizedBox(height: 24),
          _buildLanguagesFilter(),
          const SizedBox(height: 24),
          _buildUserTypeFilter(),
          const SizedBox(height: 32),
          _buildApplyButton(),
        ],
      ),
    );
  }

  Widget _buildAgeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Edad',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_ageRange.start.round()} años'),
            Text('${_ageRange.end.round()} años'),
          ],
        ),
        RangeSlider(
          values: _ageRange,
          min: 18,
          max: 99,
          divisions: 81,
          labels: RangeLabels(
            '${_ageRange.start.round()}',
            '${_ageRange.end.round()}',
          ),
          onChanged: (values) {
            setState(() => _ageRange = values);
          },
        ),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distancia máxima',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text('${_maxDistance.round()} km'),
        Slider(
          value: _maxDistance,
          min: 1,
          max: 200,
          divisions: 199,
          label: '${_maxDistance.round()} km',
          onChanged: (value) {
            setState(() => _maxDistance = value);
          },
        ),
      ],
    );
  }

  Widget _buildBudgetFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Presupuesto mensual',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_budgetRange.start.round()}€'),
            Text('${_budgetRange.end.round()}€'),
          ],
        ),
        RangeSlider(
          values: _budgetRange,
          min: 0,
          max: 10000,
          divisions: 100,
          labels: RangeLabels(
            '${_budgetRange.start.round()}€',
            '${_budgetRange.end.round()}€',
          ),
          onChanged: (values) {
            setState(() => _budgetRange = values);
          },
        ),
      ],
    );
  }

  Widget _buildGenderFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Género',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Masculino', 'Femenino', 'Otro'].map((gender) {
            final isSelected = _selectedGender == gender;
            return FilterChip(
              label: Text(gender),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedGender = selected ? gender : null;
                });
              },
              selectedColor: const Color(0xFF4A90E2).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF4A90E2),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSmokingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tabaco',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _smokingOptions.map((option) {
            final isSelected = _smokingPreferences.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _smokingPreferences.add(option);
                  } else {
                    _smokingPreferences.remove(option);
                  }
                });
              },
              selectedColor: const Color(0xFF4A90E2).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF4A90E2),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPetsFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mascotas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _petsOptions.map((option) {
            final isSelected = _petsPreferences.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _petsPreferences.add(option);
                  } else {
                    _petsPreferences.remove(option);
                  }
                });
              },
              selectedColor: const Color(0xFF4A90E2).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF4A90E2),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWorkFromHomeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teletrabajo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _WorkFromHomeOption(
              label: 'Sí',
              value: true,
              selected: _workFromHome == true,
              onTap: () => setState(() => _workFromHome = true),
            ),
            const SizedBox(width: 12),
            _WorkFromHomeOption(
              label: 'No',
              value: false,
              selected: _workFromHome == false,
              onTap: () => setState(() => _workFromHome = false),
            ),
            const SizedBox(width: 12),
            _WorkFromHomeOption(
              label: 'Todos',
              value: null,
              selected: _workFromHome == null,
              onTap: () => setState(() => _workFromHome = null),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguagesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Idiomas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableLanguages.map((language) {
            final isSelected = _selectedLanguages.contains(language);
            return FilterChip(
              label: Text(language),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedLanguages.add(language);
                  } else {
                    _selectedLanguages.remove(language);
                  }
                });
              },
              selectedColor: const Color(0xFF4A90E2).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF4A90E2),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUserTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de usuario',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _userTypeOptions.map((type) {
            final isSelected = _userTypes.contains(type);
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _userTypes.add(type);
                  } else {
                    _userTypes.remove(type);
                  }
                });
              },
              selectedColor: const Color(0xFF4A90E2).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFF4A90E2),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _applyFilters,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF4A90E2),
        ),
        child: const Text(
          'Aplicar Filtros',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _ageRange = const RangeValues(18, 40);
      _maxDistance = 50;
      _budgetRange = const RangeValues(0, 10000);
      _selectedGender = null;
      _smokingPreferences.clear();
      _petsPreferences.clear();
      _workFromHome = null;
      _selectedLanguages.clear();
      _userTypes.clear();
    });
  }

  Future<void> _applyFilters() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'preferences.ageRange': [_ageRange.start.round(), _ageRange.end.round()],
        'preferences.maxDistance': _maxDistance.round(),
        'preferences.gender': _selectedGender,
        'preferences.budgetMin': _budgetRange.start.round(),
        'preferences.budgetMax': _budgetRange.end.round(),
        'preferences.smokingPreferences': _smokingPreferences,
        'preferences.petsPreferences': _petsPreferences,
        'preferences.workFromHome': _workFromHome,
        'preferences.languages': _selectedLanguages,
        'preferences.userTypes': _userTypes,
      });
    }

    if (mounted) Navigator.pop(context);
  }
}

class _WorkFromHomeOption extends StatelessWidget {
  final String label;
  final bool? value;
  final bool selected;
  final VoidCallback onTap;

  const _WorkFromHomeOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4A90E2) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
