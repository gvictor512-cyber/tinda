import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _professionController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _preferredLocationController = TextEditingController();

  String? _gender;
  List<String> _photos = [];
  List<String> _languages = [];
  bool _isLoading = false;
  bool _isSaving = false;
  
  // Compatibility preferences
  int _cleanlinessLevel = 3;
  String? _scheduleType;
  bool _smoker = false;
  bool _petsAllowed = false;
  bool _nightOwl = false;
  List<String> _interests = [];
  String? _musicPreference;
  int _guestFrequency = 1;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final doc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            _populateFields(data);
          }
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    final profile = data['profile'] as Map<String, dynamic>?;
    final preferences = data['preferences'] as Map<String, dynamic>?;
    
    if (profile != null) {
      _firstNameController.text = profile['firstName'] ?? '';
      _lastNameController.text = profile['lastName'] ?? '';
      _ageController.text = profile['age']?.toString() ?? '';
      _professionController.text = profile['profession'] ?? '';
      _cityController.text = profile['city'] ?? '';
      _bioController.text = profile['bio'] ?? '';
      _gender = profile['gender'];
      _photos = List<String>.from(profile['photos'] ?? []);
      _languages = List<String>.from(profile['languages'] ?? []);
      _interests = List<String>.from(profile['interests'] ?? []);
    }
    
    if (preferences != null) {
      _budgetMinController.text = preferences['budgetMin']?.toString() ?? '';
      _budgetMaxController.text = preferences['budgetMax']?.toString() ?? '';
      _preferredLocationController.text = preferences['preferredLocation'] ?? '';
      _cleanlinessLevel = preferences['cleanlinessLevel'] ?? 3;
      _scheduleType = preferences['scheduleType'];
      _smoker = preferences['smoker'] ?? false;
      _petsAllowed = preferences['petsAllowed'] ?? false;
      _nightOwl = preferences['nightOwl'] ?? false;
      _musicPreference = preferences['musicPreference'];
      _guestFrequency = preferences['guestFrequency'] ?? 1;
    }
  }

  Future<void> _addPhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() => _isSaving = true);
      try {
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          // Upload to Firebase Storage
          final ref = _storage.ref().child('user_photos/${currentUser.uid}/${DateTime.now().millisecondsSinceEpoch}');
          await ref.putFile(File(image.path));
          final url = await ref.getDownloadURL();
          
          setState(() {
            if (_photos.length < 6) {
              _photos.add(url);
            }
            _isSaving = false;
          });
        }
      } catch (e) {
        debugPrint('Error uploading photo: $e');
        // Fallback to mock URL for development
        const mockUrl = 'https://via.placeholder.com/400';
        setState(() {
          if (_photos.length < 6) {
            _photos.add(mockUrl);
          }
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Modo desarrollo - usando URL mock')),
          );
        }
      }
    }
  }

  Future<void> _removePhoto(int index) async {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final profileData = {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'age': int.tryParse(_ageController.text) ?? 0,
          'profession': _professionController.text.trim(),
          'city': _cityController.text.trim(),
          'bio': _bioController.text.trim(),
          'gender': _gender,
          'photos': _photos,
          'languages': _languages,
          'interests': _interests,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final preferencesData = {
          'budgetMin': double.tryParse(_budgetMinController.text) ?? 0,
          'budgetMax': double.tryParse(_budgetMaxController.text) ?? 0,
          'preferredLocation': _preferredLocationController.text.trim(),
          'cleanlinessLevel': _cleanlinessLevel,
          'scheduleType': _scheduleType,
          'smoker': _smoker,
          'petsAllowed': _petsAllowed,
          'nightOwl': _nightOwl,
          'musicPreference': _musicPreference,
          'guestFrequency': _guestFrequency,
        };

        await _firestore.collection('users').doc(currentUser.uid).set({
          'profile': profileData,
          'preferences': preferencesData,
          'email': currentUser.email,
          'uid': currentUser.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil guardado correctamente')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el perfil: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _professionController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _preferredLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos Section
              _buildPhotosSection(),
              const SizedBox(height: 24),
              
              // Basic Info
              _buildSectionTitle('Información Básica'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obligatorio';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Apellidos',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Edad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obligatorio';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age < 18 || age > 100) {
                          return 'Edad no válida';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Género',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Masculino')),
                        DropdownMenuItem(value: 'female', child: Text('Femenino')),
                        DropdownMenuItem(value: 'other', child: Text('Otro')),
                      ],
                      onChanged: (value) {
                        setState(() => _gender = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _professionController,
                decoration: const InputDecoration(
                  labelText: 'Profesión',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Biografía',
                  border: OutlineInputBorder(),
                  hintText: 'Cuéntanos sobre ti...',
                ),
              ),
              const SizedBox(height: 24),

              // Budget Section
              _buildSectionTitle('Presupuesto'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _budgetMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Mínimo (€)',
                        border: OutlineInputBorder(),
                        suffixText: '€',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obligatorio';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _budgetMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Máximo (€)',
                        border: OutlineInputBorder(),
                        suffixText: '€',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Obligatorio';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _preferredLocationController,
                decoration: const InputDecoration(
                  labelText: 'Zona preferida',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Centro, Norte, Sur...',
                ),
              ),
              const SizedBox(height: 24),

              // Languages Section
              _buildSectionTitle('Idiomas'),
              const SizedBox(height: 16),
              _buildLanguageChips(),
              const SizedBox(height: 24),

              // Compatibility Preferences Section
              _buildSectionTitle('Preferencias de Compatibilidad'),
              const SizedBox(height: 16),
              
              // Cleanliness Level
              Text('Nivel de Limpieza: $_cleanlinessLevel/5'),
              Slider(
                value: _cleanlinessLevel.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_cleanlinessLevel',
                onChanged: (value) {
                  setState(() => _cleanlinessLevel = value.toInt());
                },
              ),
              const SizedBox(height: 16),
              
              // Schedule Type
              DropdownButtonFormField<String>(
                initialValue: _scheduleType,
                decoration: const InputDecoration(
                  labelText: 'Horario',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'early_bird', child: Text('Madrugador')),
                  DropdownMenuItem(value: 'night_owl', child: Text('Nocturno')),
                  DropdownMenuItem(value: 'regular', child: Text('Regular')),
                  DropdownMenuItem(value: 'remote_worker', child: Text('Teletrabajo')),
                ],
                onChanged: (value) {
                  setState(() => _scheduleType = value);
                },
              ),
              const SizedBox(height: 16),
              
              // Smoking Preference
              SwitchListTile(
                title: const Text('Fumador'),
                subtitle: const Text('¿Fumas o permites fumar?'),
                value: _smoker,
                onChanged: (value) {
                  setState(() => _smoker = value);
                },
              ),
              
              // Pets Preference
              SwitchListTile(
                title: const Text('Mascotas'),
                subtitle: const Text('¿Tienes o permites mascotas?'),
                value: _petsAllowed,
                onChanged: (value) {
                  setState(() => _petsAllowed = value);
                },
              ),
              
              // Night Owl
              SwitchListTile(
                title: const Text('Vida nocturna'),
                subtitle: const Text('¿Sueles tener actividad nocturna?'),
                value: _nightOwl,
                onChanged: (value) {
                  setState(() => _nightOwl = value);
                },
              ),
              const SizedBox(height: 16),
              
              // Music Preference
              DropdownButtonFormField<String>(
                initialValue: _musicPreference,
                decoration: const InputDecoration(
                  labelText: 'Preferencia musical',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'quiet', child: Text('Silencio')),
                  DropdownMenuItem(value: 'moderate', child: Text('Moderado')),
                  DropdownMenuItem(value: 'loud', child: Text('Alto volumen')),
                ],
                onChanged: (value) {
                  setState(() => _musicPreference = value);
                },
              ),
              const SizedBox(height: 16),
              
              // Guest Frequency
              Text('Frecuencia de visitas: $_guestFrequency/5'),
              Slider(
                value: _guestFrequency.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_guestFrequency',
                onChanged: (value) {
                  setState(() => _guestFrequency = value.toInt());
                },
              ),
              const SizedBox(height: 16),
              
              // Interests Section
              _buildSectionTitle('Intereses'),
              const SizedBox(height: 16),
              _buildInterestChips(),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
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
                          'Guardar Perfil',
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
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Fotos'),
            if (_photos.length < 6)
              TextButton.icon(
                onPressed: _isSaving ? null : _addPhoto,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text('Añadir (${_photos.length}/6)'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_photos.isEmpty)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Añade tu foto principal',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _photos.length + (_photos.length < 6 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _photos.length && _photos.length < 6) {
                return InkWell(
                  onTap: _isSaving ? null : _addPhoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Icon(Icons.add, size: 32, color: Colors.grey),
                  ),
                );
              }

              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _photos[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        onPressed: () => _removePhoto(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Principal',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
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

  Widget _buildLanguageChips() {
    final availableLanguages = [
      'Español', 'Inglés', 'Francés', 'Alemán', 'Italiano', 'Portugués',
      'Catalán', 'Euskera', 'Gallego', 'Chino', 'Japonés', 'Árabe'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableLanguages.map((language) {
        final isSelected = _languages.contains(language);
        return FilterChip(
          label: Text(language),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _languages.add(language);
              } else {
                _languages.remove(language);
              }
            });
          },
          selectedColor: const Color(0xFF4A90E2).withValues(alpha: 0.2),
          checkmarkColor: const Color(0xFF4A90E2),
        );
      }).toList(),
    );
  }

  Widget _buildInterestChips() {
    final availableInterests = [
      'Deportes', 'Música', 'Cine', 'Lectura', 'Viajes', 'Cocina',
      'Tecnología', 'Arte', 'Fotografía', 'Naturaleza', 'Videojuegos',
      'Yoga', 'Running', 'Fiesta', 'Netflix', 'Gaming'
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableInterests.map((interest) {
        final isSelected = _interests.contains(interest);
        return FilterChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _interests.add(interest);
              } else {
                _interests.remove(interest);
              }
            });
          },
          selectedColor: const Color(0xFF4A90E2).withValues(alpha: 0.2),
          checkmarkColor: const Color(0xFF4A90E2),
        );
      }).toList(),
    );
  }
}
