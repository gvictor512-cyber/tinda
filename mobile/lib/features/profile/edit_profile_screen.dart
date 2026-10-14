import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/public_profile_service.dart';

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
  final _professionController = TextEditingController();
  final Set<String> _selectedInterests = {};
  final _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isLoading = false;
  String? _photoUrl;
  List<String> _photos = [];
  List<String> _propertyPhotos = [];
  bool _isLandlord = false;
  bool _hasApartment = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  /// Catálogo de intereses seleccionables — los guardados se usan en
  /// matching (afinidad por intereses compartidos) y se publican en
  /// profiles/{uid} vía PublicProfileService.
  static const List<String> _interestCatalog = [
    'Deporte',
    'Gimnasio',
    'Música',
    'Viajes',
    'Cine',
    'Series',
    'Lectura',
    'Cocina',
    'Mascotas',
    'Fiesta',
    'Estudio',
    'Tecnología',
    'Arte',
    'Naturaleza',
    'Gaming',
    'Fotografía',
    'Yoga',
    'Senderismo',
  ];

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
        _professionController.text = profile?['profession']?.toString() ?? '';
        _selectedInterests
          ..clear()
          ..addAll(
            (profile?['interests'] as List?)?.map((e) => e.toString()) ??
                const [],
          );
        _photoUrl =
            photos != null && photos.isNotEmpty ? photos[0].toString() : null;
        _photos = photos?.map((e) => e.toString()).toList() ?? [];
        _isLandlord = data['userType'] == 'landlord';
        final apartment = data['apartment'] as Map<String, dynamic>?;
        _hasApartment = apartment != null;
        _propertyPhotos = (apartment?['photos'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
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
      final ref = _storage.ref().child(
          'users/$uid/profile/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(
        await AuthService.compressImage(picked.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();

      await _firestore.collection('users').doc(uid).update({
        'profile.photos': FieldValue.arrayUnion([url]),
        'profile.updatedAt': FieldValue.serverTimestamp(),
      });
      unawaited(PublicProfileService.sync(uid));

      if (mounted) {
        setState(() {
          _photos.add(url);
          _photoUrl = _photos.first;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto añadida correctamente')),
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

  Future<void> _removePhoto(String url) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).update({
        'profile.photos': FieldValue.arrayRemove([url]),
      });
      unawaited(PublicProfileService.sync(uid));
      if (mounted) {
        setState(() {
          _photos.remove(url);
          _photoUrl = _photos.isNotEmpty ? _photos.first : null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la foto: $e')),
        );
      }
    }
  }

  Future<void> _addPropertyPhotos() async {
    if (_propertyPhotos.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Máximo 10 fotos del inmueble')),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      final urls = <String>[];
      final ts = DateTime.now().millisecondsSinceEpoch;
      final remaining = 10 - _propertyPhotos.length;
      for (var i = 0; i < picked.length && i < remaining; i++) {
        final ref = _storage.ref().child('users/$uid/apartment/${ts}_$i.jpg');
        await ref.putData(
          await AuthService.compressImage(picked[i].path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
        urls.add(await ref.getDownloadURL());
      }
      if (urls.isEmpty) return;
      if (_hasApartment) {
        await _firestore.collection('users').doc(uid).update({
          'apartment.photos': FieldValue.arrayUnion(urls),
        });
      } else {
        await _firestore.collection('users').doc(uid).set(
          {
            'apartment': {'photos': urls}
          },
          SetOptions(merge: true),
        );
      }
      if (mounted) {
        setState(() => _propertyPhotos.addAll(urls));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotos del inmueble actualizadas')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir fotos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removePropertyPhoto(String url) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null || !_hasApartment) return;
    try {
      await _firestore.collection('users').doc(uid).update({
        'apartment.photos': FieldValue.arrayRemove([url]),
      });
      if (mounted) {
        setState(() => _propertyPhotos.remove(url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la foto: $e')),
        );
      }
    }
  }

  Widget _buildPhotoSection({
    required String title,
    required List<String> urls,
    required VoidCallback onAdd,
    required Future<void> Function(String url) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...urls.map((url) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        memCacheWidth: 300,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => onRemove(url),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )),
            GestureDetector(
              onTap: _isLoading ? null : onAdd,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppTheme.primaryBlue,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Selector multi-chip de intereses — alimenta la afinidad de
  /// matching y la sección "Mis intereses" del perfil.
  Widget _buildInterestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mis intereses',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final interest in _interestCatalog)
              FilterChip(
                label: Text(interest),
                selected: _selectedInterests.contains(interest),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _selectedInterests.add(interest);
                  } else {
                    _selectedInterests.remove(interest);
                  }
                }),
                selectedColor: AppTheme.secondaryPurple.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.secondaryPurple,
                labelStyle: TextStyle(
                  color: _selectedInterests.contains(interest)
                      ? AppTheme.secondaryPurple
                      : AppTheme.textLightSecondary,
                  fontWeight: _selectedInterests.contains(interest)
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
                side: BorderSide(
                  color: _selectedInterests.contains(interest)
                      ? AppTheme.secondaryPurple.withValues(alpha: 0.5)
                      : AppTheme.textLightSecondary.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();
    final city = _cityController.text.trim();
    final profession = _professionController.text.trim();
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
        'profile.profession': profession,
        'profile.interests': _selectedInterests.toList(),
        'profile.updatedAt': FieldValue.serverTimestamp(),
      });
      unawaited(PublicProfileService.sync(uid));

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
                        backgroundColor:
                            AppTheme.primaryBlue.withValues(alpha: 0.1),
                        backgroundImage: _photoUrl != null
                            ? CachedNetworkImageProvider(_photoUrl!,
                                maxWidth: 400)
                            : null,
                        child: _photoUrl == null
                            ? const Icon(Icons.person,
                                size: 50, color: AppTheme.primaryBlue)
                            : null,
                      ),
                      if (_isLoading)
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
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
                              border: Border.all(
                                  color: AppTheme.darkBackground, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  user?.email ?? 'support@roommatematchapp.com',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, color: AppTheme.textLightSecondary),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Introduce tu nombre'
                      : null,
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
                const SizedBox(height: 20),
                TextFormField(
                  controller: _professionController,
                  decoration: const InputDecoration(
                    labelText: 'Profesión',
                    prefixIcon: Icon(Icons.work_outline_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                _buildInterestsSection(),
                const SizedBox(height: 24),
                _buildPhotoSection(
                  title: 'Mis fotos',
                  urls: _photos,
                  onAdd: _pickAndUploadPhoto,
                  onRemove: _removePhoto,
                ),
                if (_isLandlord || _hasApartment) ...[
                  const SizedBox(height: 24),
                  _buildPhotoSection(
                    title: 'Fotos del inmueble',
                    urls: _propertyPhotos,
                    onAdd: _addPropertyPhotos,
                    onRemove: _removePropertyPhoto,
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white)),
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
