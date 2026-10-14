import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/public_profile_service.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';
import 'profile_details_screen.dart';
import '../premium/premium_screen.dart';
import '../../config/theme.dart';
import '../../models/premium_plan.dart';
import '../../services/auth_service.dart';
import '../../services/limits_service.dart';
import '../auth/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final LimitsService _limitsService = LimitsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String? _photoUrl;
  List<String> _photos = [];
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  UserSubscription? _subscription;
  int _weeklyBoostsUsed = 0;
  int _superLikesLeft = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadPremiumStats();
  }

  /// Loads the data behind the premium card: subscription status,
  /// boosts used this week and super likes remaining today.
  Future<void> _loadPremiumStats() async {
    try {
      final uid = _authService.currentUser?.uid;
      if (uid == null) return;

      final subscription = await _limitsService.getUserSubscription();
      final boostsUsed = await _limitsService.getWeeklyBoosts();

      var superLikesLeft = 0;
      // Premium has unlimited super likes — only count for free users.
      if (subscription?.isPremium != true) {
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final results = await Future.wait([
          _firestore
              .collection('swipes')
              .where('swiperId', isEqualTo: uid)
              .where('isSuperLike', isEqualTo: true)
              .where('timestamp',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
              .get(),
          _firestore.collection('users').doc(uid).get(),
        ]);
        final usedToday = (results[0] as QuerySnapshot).docs.length;
        final userData =
            (results[1] as DocumentSnapshot).data() as Map<String, dynamic>?;
        final credits =
            (userData?['superLikesAvailable'] as num?)?.toInt() ?? 0;
        // 1 free super like per day + purchased credits.
        superLikesLeft = (1 - usedToday).clamp(0, 1) + credits;
      }

      if (mounted) {
        setState(() {
          _subscription = subscription;
          _weeklyBoostsUsed = boostsUsed;
          _superLikesLeft = superLikesLeft;
        });
      }
    } catch (e) {
      debugPrint('Error loading premium stats: $e');
    }
  }

  Future<void> _openPremium() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PremiumScreen()),
    );
    // Plan/quota may have changed while on the paywall.
    unawaited(_loadPremiumStats());
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _authService.getUserData();
      if (data == null || !mounted) return;
      final profile = data['profile'] as Map<String, dynamic>?;
      final photos =
          (profile?['photos'] as List?)?.map((e) => e.toString()).toList() ??
              <String>[];
      setState(() {
        _userData = data;
        _photos = photos;
        _photoUrl = photos.isNotEmpty
            ? photos.first
            : _authService.currentUser?.photoURL;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  /// Edad real: profile.age si existe (perfiles semilla), si no se
  /// calcula desde birthDate (usuarios reales).
  int? get _age {
    final profile = _userData?['profile'] as Map<String, dynamic>?;
    final stored = profile?['age'] as num?;
    if (stored != null) return stored.toInt();
    final bd = _userData?['birthDate'];
    if (bd is! Timestamp) return null;
    final birth = bd.toDate();
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  Future<void> _openEditProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
    // Avatar, nombre o campos pueden haber cambiado — refrescar.
    if (mounted) await _loadProfile();
  }

  /// Vista previa del propio perfil, tal como lo ven los demás.
  void _openPreview() {
    final profile = _userData?['profile'] as Map<String, dynamic>? ?? {};
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileDetailsScreen(
          profile: <String, dynamic>{
            'uid': _authService.currentUser?.uid,
            'name': _userData?['name'] ??
                _authService.currentUser?.displayName ??
                'Usuario',
            'age': _age,
            'profession': profile['profession'],
            'bio': profile['bio'],
            'photos': _photos,
            'badges': profile['badges'],
          },
        ),
      ),
    );
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

      // Replace the avatar (index 0) but keep the rest of the photos —
      // assigning `[url]` wiped every other photo the user had uploaded.
      final current = await _firestore.collection('users').doc(uid).get();
      final existing =
          (current.data()?['profile']?['photos'] as List?)?.cast<dynamic>() ??
              const [];
      final photos = [url, ...existing.skip(1)];

      await _firestore.collection('users').doc(uid).update({
        'profile.photos': photos,
        'profile.updatedAt': FieldValue.serverTimestamp(),
      });
      unawaited(PublicProfileService.sync(uid));

      if (mounted) {
        setState(() {
          _photoUrl = url;
          if (_photos.isNotEmpty) {
            _photos[0] = url;
          } else {
            _photos.add(url);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo subir la foto. Inténtalo de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? AppTheme.textLight : AppTheme.textDark;
    final secondary =
        isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary;

    final storedName = _userData?['name']?.toString().trim();
    final displayName = (storedName != null && storedName.isNotEmpty)
        ? storedName
        : (_authService.currentUser?.displayName ?? 'Usuario');
    final isVerified = _userData?['isVerified'] == true;
    final profile = _userData?['profile'] as Map<String, dynamic>?;
    final city = profile?['city']?.toString() ?? '';
    final bio = profile?['bio']?.toString() ?? '';
    final profession = profile?['profession']?.toString() ?? '';
    final interests =
        (profile?['interests'] as List?)?.whereType<String>().toList() ??
            const <String>[];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Iconos circulares flotantes: editar · ajustes
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildCircleIcon(
                      Icons.edit_rounded,
                      _openEditProfile,
                      isDarkMode,
                    ),
                    const SizedBox(width: 10),
                    _buildCircleIcon(
                      Icons.settings_rounded,
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      ),
                      isDarkMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Cabecera: miniatura + nombre + vista previa
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _isLoading ? null : _pickAndUploadPhoto,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                          child: _photoUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: _photoUrl!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 300,
                                )
                              : Center(
                                  child: Text(
                                    displayName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 20,
                                  color: AppTheme.primaryBlue,
                                ),
                              ],
                            ],
                          ),
                          InkWell(
                            onTap: _openPreview,
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Vista previa',
                                  style:
                                      TextStyle(fontSize: 14, color: secondary),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: secondary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Chips de datos rápidos — todos abren Editar perfil
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      icon: Icons.home_rounded,
                      color: AppTheme.primaryBlue,
                      label: city.isNotEmpty ? city : 'Vivo en',
                      filled: city.isNotEmpty,
                      isDarkMode: isDarkMode,
                    ),
                    _buildInfoChip(
                      icon: Icons.cake_rounded,
                      color: AppTheme.accentPink,
                      label: _age != null ? '$_age años' : 'Edad',
                      filled: _age != null,
                      isDarkMode: isDarkMode,
                    ),
                    _buildInfoChip(
                      icon: Icons.work_outline_rounded,
                      color: AppTheme.accentOrange,
                      label: profession.isNotEmpty ? profession : 'Trabajo',
                      filled: profession.isNotEmpty,
                      isDarkMode: isDarkMode,
                    ),
                    _buildInfoChip(
                      icon: Icons.notes_rounded,
                      color: AppTheme.secondaryPurple,
                      label: bio.isNotEmpty ? 'Sobre mí' : 'Más sobre mí',
                      filled: bio.isNotEmpty,
                      isDarkMode: isDarkMode,
                    ),
                    _buildInfoChip(
                      icon: Icons.auto_awesome_rounded,
                      color: AppTheme.primaryGreen,
                      label: interests.isNotEmpty
                          ? '${interests.length} intereses'
                          : 'Intereses',
                      filled: interests.isNotEmpty,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Mis fotos', isDarkMode),
              const SizedBox(height: 10),
              _buildPhotosCard(isDarkMode),
              const SizedBox(height: 24),
              _buildSectionTitle(
                'Mis intereses',
                isDarkMode,
                alert: interests.isEmpty,
              ),
              if (interests.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Agrega intereses para mejores matches',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentPink,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              _buildInterestsCard(interests, isDarkMode),
              const SizedBox(height: 24),
              // RoomMate Match Premium — banner + contadores
              _buildPremiumSection(isDarkMode),
              const SizedBox(height: 24),
              // Menu items
              _buildMenuItem(
                icon: Icons.edit_rounded,
                title: 'Editar perfil',
                subtitle: 'Actualiza tu información personal',
                onTap: _openEditProfile,
                isDarkMode: isDarkMode,
              ),
              _buildMenuItem(
                icon: Icons.star_rounded,
                title: 'Premium',
                subtitle: 'Obtén beneficios exclusivos',
                onTap: _openPremium,
                isDarkMode: isDarkMode,
              ),
              _buildMenuItem(
                icon: Icons.help_rounded,
                title: 'Ayuda y soporte',
                subtitle: 'Resuelve tus dudas',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HelpSupportScreen(),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
              ),
              _buildMenuItem(
                icon: Icons.info_rounded,
                title: 'Acerca de',
                subtitle: 'Información de la app',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 24),
              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppTheme.errorGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.error.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _authService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const WelcomeScreen()),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Botón circular flotante estilo Tinder (editar, ajustes).
  Widget _buildCircleIcon(
    IconData icon,
    VoidCallback onTap,
    bool isDarkMode,
  ) {
    final iconColor = isDarkMode ? AppTheme.textLight : AppTheme.textDark;
    return Material(
      color: isDarkMode ? AppTheme.darkSurface : Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: iconColor),
        ),
      ),
    );
  }

  /// Título de sección ("Mis fotos", "Mis intereses") con alerta
  /// roja opcional cuando falta contenido — como en Tinder.
  Widget _buildSectionTitle(String title, bool isDarkMode,
      {bool alert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
              letterSpacing: -0.4,
            ),
          ),
          if (alert) ...[
            const SizedBox(width: 6),
            const Icon(Icons.error_rounded, size: 18, color: AppTheme.error),
          ],
        ],
      ),
    );
  }

  /// Chip de dato rápido: icono coloreado + etiqueta (+ si está vacío).
  /// Todos navegan a Editar perfil.
  Widget _buildInfoChip({
    required IconData icon,
    required Color color,
    required String label,
    required bool filled,
    required bool isDarkMode,
  }) {
    final textColor = isDarkMode ? AppTheme.textLight : AppTheme.textDark;
    final secondary =
        isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary;
    return GestureDetector(
      onTap: _openEditProfile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode
                ? AppTheme.darkSurface
                : Colors.grey.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            if (!filled) ...[
              const SizedBox(width: 4),
              Icon(Icons.add_rounded, size: 15, color: secondary),
            ],
          ],
        ),
      ),
    );
  }

  /// Tarjeta "Mis fotos": tira horizontal de fotos + tile de añadir,
  /// consejo inferior y botón Editar — como la captura de Tinder.
  Widget _buildPhotosCard(bool isDarkMode) {
    final secondary =
        isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary;
    final tip = _photos.length < 3
        ? 'Consejo: Añade más fotos para destacar'
        : 'Consejo: Añade fotos más variadas';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? AppTheme.darkSurface
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final url in _photos)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 84,
                        height: 110,
                        fit: BoxFit.cover,
                        memCacheWidth: 300,
                      ),
                    ),
                  ),
                // Tile "+" — abre el editor completo de fotos
                GestureDetector(
                  onTap: _openEditProfile,
                  child: Container(
                    width: 84,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppTheme.primaryBlue,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  tip,
                  style: TextStyle(fontSize: 12.5, color: secondary),
                ),
              ),
              GestureDetector(
                onTap: _openEditProfile,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? AppTheme.textLight
                        : AppTheme.primaryBlueDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Editar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? AppTheme.textDark : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tarjeta "Mis intereses": chips de los intereses actuales más un
  /// "+" para editar; vacía muestra una invitación a añadir.
  Widget _buildInterestsCard(List<String> interests, bool isDarkMode) {
    final secondary =
        isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode
              ? AppTheme.darkSurface
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: interests.isEmpty
          ? GestureDetector(
              onTap: _openEditProfile,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppTheme.secondaryPurple,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Añade tus intereses',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: secondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final interest in interests)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      interest,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryPurple,
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: _openEditProfile,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.secondaryPurple.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: AppTheme.secondaryPurple,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Sección premium estilo Tinder: banner "RoomMate Match Premium"
  /// pulsable sobre una tarjeta con los contadores de Super Likes,
  /// Boosts y el tiempo restante de suscripción.
  Widget _buildPremiumSection(bool isDarkMode) {
    final isPremium = _subscription?.isPremium ?? false;
    final weeklyBoosts = _subscription?.limits.weeklyBoosts ?? 0;
    final boostsLeft =
        (weeklyBoosts - _weeklyBoostsUsed).clamp(0, weeklyBoosts);

    final superLikesText = isPremium ? '∞' : '$_superLikesLeft';
    final boostsText = isPremium ? '$boostsLeft' : '0';

    String subscriptionText;
    if (isPremium) {
      final end = _subscription?.endDate;
      if (end == null) {
        subscriptionText = 'Activa';
      } else {
        final days = end.difference(DateTime.now()).inDays;
        subscriptionText = days > 0 ? '$days días' : 'Último día';
      }
    } else {
      subscriptionText = 'Básico';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Banner pulsable → pantalla Premium
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openPremium,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.secondaryPurple,
                      AppTheme.accentPink,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryPurple.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'RoomMate Match',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'PREMIUM',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPremium
                                ? 'Disfruta de todos tus beneficios.'
                                : 'Descubre a quién le gustas. Haz match más rápido.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Tarjeta de contadores: Super Likes · Boosts · Suscripción
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDarkMode ? AppTheme.darkSurface : Colors.white,
              border: Border.all(
                color: isDarkMode
                    ? AppTheme.darkSurface
                    : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  icon: Icons.star_rounded,
                  color: AppTheme.primaryBlue,
                  value: superLikesText,
                  label: 'Super Likes',
                  isDarkMode: isDarkMode,
                ),
                _buildStatItem(
                  icon: Icons.rocket_launch_rounded,
                  color: AppTheme.secondaryPurple,
                  value: boostsText,
                  label: 'Boosts',
                  isDarkMode: isDarkMode,
                ),
                _buildStatItem(
                  icon: Icons.workspace_premium_rounded,
                  color: AppTheme.accentPink,
                  value: subscriptionText,
                  label: 'Suscripción',
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Un contador de la tarjeta premium: icono + valor + etiqueta.
  /// Toda la sección navega a Premium al pulsarla.
  Widget _buildStatItem({
    IconData? icon,
    required Color color,
    required String value,
    required String label,
    required bool isDarkMode,
  }) {
    final textColor = isDarkMode ? AppTheme.textLight : AppTheme.textDark;
    final secondary =
        isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openPremium,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(fontSize: 11.5, color: secondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDarkMode ? AppTheme.darkSurface : Colors.white,
              border: Border.all(
                color: isDarkMode
                    ? AppTheme.darkSurface
                    : Colors.grey.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? AppTheme.textLight
                              : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode
                              ? AppTheme.textLightSecondary
                              : AppTheme.textDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDarkMode
                      ? AppTheme.textLightSecondary
                      : AppTheme.textDarkSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
