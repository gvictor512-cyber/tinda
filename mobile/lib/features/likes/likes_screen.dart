import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../services/limits_service.dart';
import '../../services/auth_service.dart';
import '../premium/premium_screen.dart';

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  final LimitsService _limitsService = LimitsService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _isPremium = false;
  List<Map<String, dynamic>> _likers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final canSee = await _limitsService.canSeeWhoLikedYou();
      final likers = await _fetchLikers();
      if (!mounted) return;
      setState(() {
        _isPremium = canSee;
        _likers = likers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLikers() async {
    final user = _authService.currentUser;
    if (user == null) return [];

    // Avoid any Firestore index requirement by fetching recent swipes and filtering client-side.
    final snapshot = await _firestore
        .collection('swipes')
        .limit(500)
        .get();

    final filtered = snapshot.docs
        .where((d) {
          final data = d.data();
          return data['swipedId'] == user.uid && data['isLike'] == true;
        })
        .toList();
    filtered.sort((a, b) {
      final t1 = a.data()['timestamp'] as Timestamp?;
      final t2 = b.data()['timestamp'] as Timestamp?;
      if (t1 == null || t2 == null) return 0;
      return t2.compareTo(t1);
    });

    final seen = <String>{};
    final likers = <Map<String, dynamic>>[];

    for (final doc in filtered) {
      final swiperId = doc.data()['swiperId'] as String?;
      if (swiperId == null || swiperId == user.uid || seen.contains(swiperId)) {
        continue;
      }
      seen.add(swiperId);

      final userDoc = await _firestore.collection('users').doc(swiperId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        data['uid'] = swiperId;
        data['swipeTimestamp'] = doc.data()['timestamp'];
        likers.add(data);
      }
    }

    return likers;
  }

  void _goToPremium() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PremiumScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Likes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      if (!_isPremium) _buildPremiumBanner(isDarkMode),
                      _buildLikersList(isDarkMode),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPremiumBanner(bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Descubre quién te ha dado like',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Solo los usuarios Premium pueden ver los perfiles de las personas que les han dado like.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _goToPremium,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Suscribirse a Premium',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikersList(bool isDarkMode) {
    if (_likers.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 64,
                color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Aún nadie te ha dado like',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final liker = _likers[index];
          return _buildLikerTile(liker, isDarkMode);
        },
        childCount: _likers.length,
      ),
    );
  }

  Widget _buildLikerTile(Map<String, dynamic> liker, bool isDarkMode) {
    final profile = liker['profile'] as Map<String, dynamic>?;
    final photos = profile?['photos'] as List<dynamic>?;
    final photoUrl = photos != null && photos.isNotEmpty ? photos[0] as String : null;
    final name = liker['name']?.toString() ?? 'Usuario';
    final city = profile?['city']?.toString() ?? '';

    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
        child: photoUrl == null
            ? const Icon(Icons.person, color: AppTheme.primaryBlue)
            : null,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDarkMode ? AppTheme.textLight : AppTheme.textDark,
        ),
      ),
      subtitle: city.isNotEmpty
          ? Text(
              city,
              style: TextStyle(
                color: isDarkMode ? AppTheme.textLightSecondary : AppTheme.textDarkSecondary,
              ),
            )
          : null,
    );

    if (_isPremium) return tile;

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: tile,
    );
  }
}
