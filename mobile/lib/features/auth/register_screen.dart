import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../app.dart';
import 'login_screen.dart';
import '../../config/theme.dart';
import '../settings/legal_document_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _propertyTitleController = TextEditingController();
  final _propertyLocationController = TextEditingController();
  final _propertyPriceController = TextEditingController();
  final _propertyDescriptionController = TextEditingController();
  final _authService = AuthService();
  DateTime? _selectedBirthDate;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String? _errorMessage;
  String _userType = 'tenant';

  final List<XFile> _profilePhotos = [];
  final List<XFile> _propertyPhotos = [];
  final Map<String, bool> _propertyConditions = {
    'Estudiantes': true,
    'Trabajadores': true,
    'Mascotas': false,
    'Fumadores': false,
    'Parejas': false,
    'Ruido nocturno': false,
    'Visitantes frecuentes': true,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    _propertyTitleController.dispose();
    _propertyLocationController.dispose();
    _propertyPriceController.dispose();
    _propertyDescriptionController.dispose();
    super.dispose();
  }

  void _openLegalDocument(BuildContext context, String title, String assetPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LegalDocumentScreen(
          title: title,
          assetPath: assetPath,
        ),
      ),
    );
  }

  Future<void> _pickProfilePhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _profilePhotos.addAll(picked);
        if (_profilePhotos.length > 6) {
          _profilePhotos.removeRange(6, _profilePhotos.length);
        }
      });
    }
  }

  Future<void> _pickPropertyPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _propertyPhotos.addAll(picked);
        if (_propertyPhotos.length > 10) {
          _propertyPhotos.removeRange(10, _propertyPhotos.length);
        }
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = 'Debes aceptar los términos, la privacidad y ser mayor de 18 años';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic>? apartment;
      if (_userType == 'landlord') {
        final price = double.tryParse(_propertyPriceController.text.trim()) ?? 0.0;
        apartment = {
          'title': _propertyTitleController.text.trim(),
          'location': _propertyLocationController.text.trim(),
          'price': price,
          'description': _propertyDescriptionController.text.trim(),
          'conditions': _propertyConditions,
        };
      }

      await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        userType: _userType,
        birthDate: _selectedBirthDate!,
        profilePhotos: _profilePhotos,
        propertyPhotos: _propertyPhotos,
        apartment: apartment,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryBlue,
      ),
    );
  }

  Widget _buildPhotoPicker({
    required List<XFile> photos,
    required Future<void> Function() onPick,
    required int maxPhotos,
    required String emptyLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photos.isEmpty)
          Text(
            emptyLabel,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        if (photos.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(photos[index].path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => photos.removeAt(index)),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (photos.length < maxPhotos)
          OutlinedButton.icon(
            onPressed: () { onPick(); },
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Añadir fotos'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo
                Image.asset(
                  'assets/images/logo_symbol.png',
                  height: 130,
                  fit: BoxFit.contain,
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Únete a RoomMate Match',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textLightSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // User type selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Soy:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Busco piso'),
                            value: 'tenant',
                            groupValue: _userType,
                            onChanged: (value) {
                              setState(() {
                                _userType = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Ofrezco piso'),
                            value: 'landlord',
                            groupValue: _userType,
                            onChanged: (value) {
                              setState(() {
                                _userType = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outlined, color: AppTheme.primaryBlue),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor introduce tu nombre';
                    }
                    if (value.length < 2) {
                      return 'El nombre debe tener al menos 2 caracteres';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryBlue),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El correo electrónico es obligatorio';
                    }
                    final email = value.trim();
                    if (email.contains(' ')) {
                      return 'El correo no puede contener espacios';
                    }
                    if (!email.contains('@')) {
                      return 'Falta el símbolo @ en el correo';
                    }
                    final parts = email.split('@');
                    if (parts.length != 2 || parts[0].isEmpty) {
                      return 'Falta el nombre del correo antes de @';
                    }
                    final domain = parts[1];
                    if (domain.isEmpty) {
                      return 'Falta el dominio después de @';
                    }
                    if (!domain.contains('.')) {
                      return 'El dominio del correo debe tener un punto (por ejemplo, gmail.com)';
                    }
                    final domainParts = domain.split('.');
                    if (domainParts.last.length < 2) {
                      return 'La extensión del dominio es demasiado corta (por ejemplo, .com, .es)';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Confirm email field
                TextFormField(
                  controller: _confirmEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryBlue),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Debes confirmar tu correo electrónico';
                    }
                    if (value.trim() != _emailController.text.trim()) {
                      return 'Los correos electrónicos no coinciden';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.primaryBlue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppTheme.primaryBlue,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor introduce tu contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.primaryBlue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppTheme.primaryBlue,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Birth date field
                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Fecha de nacimiento',
                    hintText: 'DD/MM/AAAA',
                    prefixIcon: Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(now.year - 18, now.month, now.day),
                      firstDate: DateTime(now.year - 120),
                      lastDate: DateTime(now.year - 18, now.month, now.day),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedBirthDate = picked;
                        _birthDateController.text =
                            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                      });
                    }
                  },
                  validator: (value) {
                    if (_selectedBirthDate == null) {
                      return 'Por favor introduce tu fecha de nacimiento';
                    }
                    final age = DateTime.now().year - _selectedBirthDate!.year;
                    if (age < 18) {
                      return 'Debes ser mayor de 18 años';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Profile photos
                _buildSectionTitle('Fotos de perfil'),
                const SizedBox(height: 8),
                _buildPhotoPicker(
                  photos: _profilePhotos,
                  onPick: _pickProfilePhotos,
                  maxPhotos: 6,
                  emptyLabel: 'Añade hasta 6 fotos de perfil',
                ),
                
                const SizedBox(height: 24),
                
                // Property details (only for landlords)
                if (_userType == 'landlord') ...[
                  _buildSectionTitle('Datos del piso/habitación'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _propertyTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Título del anuncio',
                      prefixIcon: Icon(Icons.title, color: AppTheme.primaryBlue),
                    ),
                    validator: (value) {
                      if (_userType == 'landlord' && (value == null || value.trim().isEmpty)) {
                        return 'Introduce un título para el anuncio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _propertyLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación',
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue),
                    ),
                    validator: (value) {
                      if (_userType == 'landlord' && (value == null || value.trim().isEmpty)) {
                        return 'Introduce la ubicación';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _propertyPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Precio mensual (€)',
                      prefixIcon: Icon(Icons.euro, color: AppTheme.primaryBlue),
                    ),
                    validator: (value) {
                      if (_userType == 'landlord' && (value == null || value.trim().isEmpty)) {
                        return 'Introduce el precio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _propertyDescriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción del inmueble',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description_outlined, color: AppTheme.primaryBlue),
                    ),
                    validator: (value) {
                      if (_userType == 'landlord' && (value == null || value.trim().isEmpty)) {
                        return 'Introduce una descripción';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Fotos del inmueble'),
                  const SizedBox(height: 8),
                  _buildPhotoPicker(
                    photos: _propertyPhotos,
                    onPick: _pickPropertyPhotos,
                    maxPhotos: 10,
                    emptyLabel: 'Añade hasta 10 fotos del inmueble',
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Condiciones del inmueble'),
                  const SizedBox(height: 8),
                  ..._propertyConditions.entries.map((entry) {
                    return SwitchListTile(
                      title: Text(entry.key),
                      value: entry.value,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (value) {
                        setState(() {
                          _propertyConditions[entry.key] = value;
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 24),
                ],
                
                // Terms and conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreeToTerms = !_agreeToTerms;
                          });
                        },
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(text: 'He leído y acepto los '),
                              TextSpan(
                                text: 'Términos de Uso',
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.none,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _openLegalDocument(
                                        context,
                                        'Términos de Servicio',
                                        'assets/legal/terms_of_service.md',
                                      ),
                              ),
                              const TextSpan(text: ' y la '),
                              TextSpan(
                                text: 'Política de Privacidad',
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.none,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _openLegalDocument(
                                        context,
                                        'Política de Privacidad',
                                        'assets/legal/privacy_policy.md',
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.error, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_errorMessage != null) const SizedBox(height: 16),
                
                // Register button
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Crear Cuenta'),
                ),
                
                const SizedBox(height: 24),
                
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya tienes cuenta? '),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text('Inicia Sesión'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Back button
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
