import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  bool _emailVerified = false;
  bool _phoneVerified = false;
  bool _selfieVerified = false;
  bool _documentVerified = false;
  bool _isLoading = false;

  String? _phoneNumber;
  String? _smsCode;
  String? _selfieUrl;
  String? _documentUrl;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Load verification status from API
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyEmail() async {
    // TODO: Implement email verification
    setState(() => _emailVerified = true);
  }

  Future<void> _sendPhoneVerification() async {
    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un número de teléfono')),
      );
      return;
    }

    // TODO: Send SMS verification code
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código enviado a tu teléfono')),
    );
  }

  Future<void> _verifyPhone() async {
    if (_smsCode == null || _smsCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el código SMS')),
      );
      return;
    }

    // TODO: Verify phone with API
    setState(() => _phoneVerified = true);
  }

  Future<void> _takeSelfie() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      imageQuality: 85,
    );

    if (image != null) {
      // TODO: Upload selfie and verify
      setState(() {
        _selfieUrl = image.path;
        _selfieVerified = true;
      });
    }
  }

  Future<void> _uploadDocument() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 90,
    );

    if (image != null) {
      // TODO: Upload document and verify
      setState(() {
        _documentUrl = image.path;
        _documentVerified = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildEmailVerification(),
          const SizedBox(height: 24),
          _buildPhoneVerification(),
          const SizedBox(height: 24),
          _buildSelfieVerification(),
          const SizedBox(height: 24),
          _buildDocumentVerification(),
          const SizedBox(height: 24),
          _buildVerificationLevel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final verificationsCompleted = [
      _emailVerified,
      _phoneVerified,
      _selfieVerified,
      _documentVerified,
    ].where((v) => v).length;

    return Column(
      children: [
        Icon(
          Icons.verified_user,
          size: 80,
          color: verificationsCompleted >= 3 ? Colors.green : Colors.grey[400],
        ),
        const SizedBox(height: 16),
        const Text(
          'Verifica tu perfil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Completa la verificación para aumentar tu confianza',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: verificationsCompleted / 4,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            verificationsCompleted >= 3 ? Colors.green : const Color(0xFF4A90E2),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$verificationsCompleted de 4 verificaciones completadas',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailVerification() {
    return _buildVerificationCard(
      icon: Icons.email,
      title: 'Verificar Email',
      description: 'Confirma tu dirección de correo electrónico',
      isVerified: _emailVerified,
      onTap: _emailVerified ? null : _verifyEmail,
    );
  }

  Widget _buildPhoneVerification() {
    if (_phoneVerified) {
      return _buildVerificationCard(
        icon: Icons.phone,
        title: 'Teléfono Verificado',
        description: 'Tu número de teléfono está verificado',
        isVerified: true,
        onTap: null,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.phone, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verificar Teléfono',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Confirma tu número de teléfono',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Número de teléfono',
                prefixText: '+34 ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onChanged: (value) => _phoneNumber = value,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _sendPhoneVerification,
              child: const Text('Enviar código'),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Código SMS',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _smsCode = value,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _verifyPhone,
              child: const Text('Verificar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfieVerification() {
    return _buildVerificationCard(
      icon: Icons.camera_alt,
      title: 'Verificar Selfie',
      description: 'Toma una selfie para verificar tu identidad',
      isVerified: _selfieVerified,
      onTap: _selfieVerified ? null : _takeSelfie,
      imageUrl: _selfieUrl,
    );
  }

  Widget _buildDocumentVerification() {
    return _buildVerificationCard(
      icon: Icons.description,
      title: 'Verificar Documento',
      description: 'Sube tu documento de identidad (opcional)',
      isVerified: _documentVerified,
      onTap: _documentVerified ? null : _uploadDocument,
      imageUrl: _documentUrl,
    );
  }

  Widget _buildVerificationCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isVerified,
    VoidCallback? onTap,
    String? imageUrl,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isVerified ? Colors.green.withValues(alpha: 0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isVerified ? Colors.green : Colors.grey[600],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (imageUrl != null) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imageUrl),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationLevel() {
    final verificationsCompleted = [
      _emailVerified,
      _phoneVerified,
      _selfieVerified,
      _documentVerified,
    ].where((v) => v).length;

    String level;
    Color levelColor;
    String levelDescription;

    if (verificationsCompleted >= 3) {
      level = 'Avanzada';
      levelColor = Colors.green;
      levelDescription = 'Perfil completamente verificado';
    } else if (verificationsCompleted >= 2) {
      level = 'Estándar';
      levelColor = const Color(0xFF4A90E2);
      levelDescription = 'Perfil parcialmente verificado';
    } else {
      level = 'Básica';
      levelColor = Colors.orange;
      levelDescription = 'Completa más verificaciones';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: levelColor),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: levelColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nivel: $level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: levelColor,
                  ),
                ),
                Text(
                  levelDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
