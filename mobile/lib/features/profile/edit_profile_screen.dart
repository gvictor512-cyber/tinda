import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isLoading = false;
  String? _photoUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);
      final data = await _authService.getUserData();
      if (data != null) {
        final profile = data['profile'] as Map<String, dynamic>?;
        final photos = profile?['photos'] as List<dynamic>?;
        _nameController.text = data['name']?.toString() ?? '';
        _bioController.text = profile?['bio']?.toString() ?? '';
        _cityController.text = profile?['city']?.toString() ?? '';
        _photoUrl = photos != null && photos.isNotEmpty ? photos[0].toString() : null;
      } else {
        _nameController.text = _authService.currentUser?.displayName ?? '';
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No estás autenticado')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ref = _storage.ref().child('users/$uid/profile/0.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      await _firestore.collection('users').doc(uid).update({
        'profile.photos': [url],
        'profile.updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _photoUrl = url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();
    final city = _cityController.text.trim();
    final uid = _authService.currentUser?.uid;

    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No estás autenticado')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.updateUserProfile(displayName: name);
      await _firestore.collection('users').doc(uid).update({
        'name': name,
        'profile.bio': bio,
        'profile.city': city,
        'profile.updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil guardado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isLoading ? null : _pickAndUploadPhoto,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                        child: _photoUrl == null
                            ? const Icon(Icons.person, size: 50, color: AppTheme.primaryBlue)
                            : null,
                      ),
                      if (_isLoading)
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      if (!_isLoading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.darkBackground, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  user?.email ?? 'support@roommatematchapp.com',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppTheme.textLightSecondary),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Introduce tu nombre' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Sobre ti',
                    prefixIcon: Icon(Icons.edit_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ciudad',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
