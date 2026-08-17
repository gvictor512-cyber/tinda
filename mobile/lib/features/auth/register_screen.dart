import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _authService = AuthService();
  DateTime? _selectedBirthDate;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String? _errorMessage;
  String _userType = 'tenant';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _launchLegalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
      await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        userType: _userType,
        birthDate: _selectedBirthDate!,
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
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.home_outlined,
                    size: 40,
                    color: Colors.white,
                  ),
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
                    color: AppTheme.textDarkSecondary,
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
                    if (value == null || value.isEmpty) {
                      return 'Por favor introduce tu correo electrónico';
                    }
                    if (!value.contains('@')) {
                      return 'Introduce un correo electrónico válido';
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
                              color: AppTheme.textDark,
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
