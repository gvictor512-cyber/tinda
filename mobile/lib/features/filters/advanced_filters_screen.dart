import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/limits_service.dart';

class AdvancedFiltersScreen extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;

  const AdvancedFiltersScreen({
    super.key,
    this.initialFilters,
  });

  @override
  State<AdvancedFiltersScreen> createState() => _AdvancedFiltersScreenState();
}

class _AdvancedFiltersScreenState extends State<AdvancedFiltersScreen> {
  final LimitsService _limitsService = LimitsService();
  
  bool _hasAccess = false;
  bool _isLoading = true;

  // Filter values
  int? _minAge;
  int? _maxAge;
  int? _minIncome;
  String? _profession;
  bool? _petsAllowed;
  bool? _smokersAllowed;
  bool? _remoteWork;
  String? _language;
  String? _stayDuration;
  String? _gender;
  bool? _studentsOnly;
  bool? _workersOnly;

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _loadInitialFilters();
  }

  Future<void> _checkAccess() async {
    final hasAccess = await _limitsService.hasAdvancedFilters();
    setState(() {
      _hasAccess = hasAccess;
      _isLoading = false;
    });
  }

  void _loadInitialFilters() {
    if (widget.initialFilters != null) {
      final filters = widget.initialFilters!;
      setState(() {
        _minAge = filters['minAge'];
        _maxAge = filters['maxAge'];
        _minIncome = filters['minIncome'];
        _profession = filters['profession'];
        _petsAllowed = filters['petsAllowed'];
        _smokersAllowed = filters['smokersAllowed'];
        _remoteWork = filters['remoteWork'];
        _language = filters['language'];
        _stayDuration = filters['stayDuration'];
        _gender = filters['gender'];
        _studentsOnly = filters['studentsOnly'];
        _workersOnly = filters['workersOnly'];
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
          'Filtros Avanzados',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Limpiar'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasAccess
              ? _buildPremiumUpsell(isDarkMode)
              : _buildFiltersContent(isDarkMode),
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
                Icons.workspace_premium_rounded,
                size: 80,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Filtros Avanzados',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Los filtros avanzados son exclusivos para usuarios Premium.\n\nFiltra por edad, ingresos, profesión, mascotas, teletrabajo y más.',
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

  Widget _buildFiltersContent(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Age range
          _buildSectionTitle('Rango de edad', isDarkMode),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: 'Mínima',
                  value: _minAge,
                  onChanged: (value) => setState(() => _minAge = value),
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildNumberField(
                  label: 'Máxima',
                  value: _maxAge,
                  onChanged: (value) => setState(() => _maxAge = value),
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Income
          _buildSectionTitle('Ingresos mínimos (€/mes)', isDarkMode),
          const SizedBox(height: 12),
          _buildNumberField(
            label: 'Ingresos mínimos',
            value: _minIncome,
            onChanged: (value) => setState(() => _minIncome = value),
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 24),

          // Profession
          _buildSectionTitle('Profesión', isDarkMode),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Profesión',
            value: _profession,
            items: const [
              'Cualquiera',
              'Estudiante',
              'Trabajador',
              'Autónomo',
              'Empresario',
              'Jubilado',
            ],
            onChanged: (value) => setState(() => _profession = value),
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 24),

          // Boolean filters
          _buildSectionTitle('Preferencias', isDarkMode),
          const SizedBox(height: 12),
          _buildBooleanFilter(
            icon: Icons.pets_rounded,
            label: 'Permite mascotas',
            value: _petsAllowed,
            onChanged: (value) => setState(() => _petsAllowed = value),
            isDarkMode: isDarkMode,
          ),
          _buildBooleanFilter(
            icon: Icons.smoking_rooms_rounded,
            label: 'Permite fumadores',
            value: _smokersAllowed,
            onChanged: (value) => setState(() => _smokersAllowed = value),
            isDarkMode: isDarkMode,
          ),
          _buildBooleanFilter(
            icon: Icons.work_rounded,
            label: 'Teletrabajo',
            value: _remoteWork,
            onChanged: (value) => setState(() => _remoteWork = value),
            isDarkMode: isDarkMode,
          ),
          _buildBooleanFilter(
            icon: Icons.school_rounded,
            label: 'Solo estudiantes',
            value: _studentsOnly,
            onChanged: (value) => setState(() => _studentsOnly = value),
            isDarkMode: isDarkMode,
          ),
          _buildBooleanFilter(
            icon: Icons.business_center_rounded,
            label: 'Solo trabajadores',
            value: _workersOnly,
            onChanged: (value) => setState(() => _workersOnly = value),
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 24),

          // Language
          _buildSectionTitle('Idioma', isDarkMode),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Idioma',
            value: _language,
            items: const [
              'Cualquiera',
              'Español',
              'Inglés',
              'Francés',
              'Alemán',
              'Italiano',
              'Portugués',
            ],
            onChanged: (value) => setState(() => _language = value),
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 24),

          // Stay duration
          _buildSectionTitle('Duración de estancia', isDarkMode),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Duración',
            value: _stayDuration,
            items: const [
              'Cualquiera',
              'Corta (1-3 meses)',
              'Media (3-6 meses)',
              'Larga (6-12 meses)',
              'Indefinida',
            ],
            onChanged: (value) => setState(() => _stayDuration = value),
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 24),

          // Gender
          _buildSectionTitle('Género', isDarkMode),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Género',
            value: _gender,
            items: const [
              'Cualquiera',
              'Hombre',
              'Mujer',
              'No binario',
            ],
            onChanged: (value) => setState(() => _gender = value),
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 32),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Aplicar Filtros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required int? value,
    required Function(int?) onChanged,
    required bool isDarkMode,
  }) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
        ),
        filled: true,
        fillColor: isDarkMode ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: TextStyle(
        color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
      ),
      onChanged: (text) {
        final intValue = int.tryParse(text);
        onChanged(intValue);
      },
      controller: TextEditingController(text: value?.toString()),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item == 'Cualquiera' ? null : item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: isDarkMode ? AppTheme.darkSurface : Colors.white,
        style: TextStyle(
          color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
        ),
      ),
    );
  }

  Widget _buildBooleanFilter({
    required IconData icon,
    required String label,
    required bool? value,
    required Function(bool?) onChanged,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (value == null) {
              onChanged(true);
            } else if (value == true) {
              onChanged(false);
            } else {
              onChanged(null);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value == true
                    ? AppTheme.primaryBlue
                    : (value == false
                        ? AppTheme.error
                        : (isDarkMode ? Colors.black12 : Colors.grey.withValues(alpha: 0.2))),
                width: value != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: value == true
                      ? AppTheme.primaryBlue
                      : (value == false
                          ? AppTheme.error
                          : (isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (value == true)
                  const Icon(Icons.check_circle_rounded, color: AppTheme.primaryBlue)
                else if (value == false)
                  const Icon(Icons.cancel_rounded, color: AppTheme.error)
                else
                  Icon(Icons.radio_button_unchecked,
                      color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _minAge = null;
      _maxAge = null;
      _minIncome = null;
      _profession = null;
      _petsAllowed = null;
      _smokersAllowed = null;
      _remoteWork = null;
      _language = null;
      _stayDuration = null;
      _gender = null;
      _studentsOnly = null;
      _workersOnly = null;
    });
  }

  void _applyFilters() {
    final filters = {
      'minAge': _minAge,
      'maxAge': _maxAge,
      'minIncome': _minIncome,
      'profession': _profession,
      'petsAllowed': _petsAllowed,
      'smokersAllowed': _smokersAllowed,
      'remoteWork': _remoteWork,
      'language': _language,
      'stayDuration': _stayDuration,
      'gender': _gender,
      'studentsOnly': _studentsOnly,
      'workersOnly': _workersOnly,
    };

    Navigator.of(context).pop(filters);
  }
}
