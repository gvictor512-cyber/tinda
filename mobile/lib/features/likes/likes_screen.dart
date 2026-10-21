import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../services/limits_service.dart';
import '../../services/auth_service.dart';
import '../../services/matching_service.dart';
import '../premium/premium_screen.dart';
import '../profile/profile_details_screen.dart';

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
  // Blurred teaser cards for non-premium users — demo profiles plus
  // placeholder cards make the section look populated even before
  // anyone has actually liked the account.
  List<Map<String, dynamic>> _teasers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Fetch all in parallel instead of sequentially
      final (canSee, likers, teasers) = await (
        _limitsService.canSeeWhoLikedYou(),
        _fetchLikers(),
        _fetchTeaserProfiles(),
      ).wait;
      if (!mounted) return;
      setState(() {
        _isPremium = canSee;
        _likers = likers;
        _teasers = teasers;
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

    // Server-side filter on swipedId (no composite index needed).
    // isLike still filtered client-side to keep it index-free.
    final snapshot = await _firestore
        .collection('swipes')
        .where('swipedId', isEqualTo: user.uid)
        .limit(500)
        .get();

    final filtered = snapshot.docs
        .where((d) => d.data()['isLike'] == true)
        .toList();
    filtered.sort((a, b) {
      final t1 = a.data()['timestamp'] as Timestamp?;
      final t2 = b.data()['timestamp'] as Timestamp?;
      if (t1 == null || t2 == null) return 0;
      return t2.compareTo(t1);
    });

    // Collect unique swiper ids, then fetch all user docs in parallel
    final seen = <String>{};
    final swiperIds = <String>[];
    final swipeDocsByUser = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in filtered) {
      final swiperId = doc.data()['swiperId'] as String?;
      if (swiperId == null || swiperId == user.uid || seen.contains(swiperId)) {
        continue;
      }
      seen.add(swiperId);
      swiperIds.add(swiperId);
      swipeDocsByUser[swiperId] = doc;
    }

    final userDocs = await Future.wait(
      swiperIds.map((id) => _firestore.collection('profiles').doc(id).get()),
    );

    final likers = <Map<String, dynamic>>[];
    for (var i = 0; i < userDocs.length; i++) {
      final userDoc = userDocs[i];
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        // Seeded demo likers only show for the demo/dev accounts.
        if (!MatchingService.canSeeDemoContent && data['isDemo'] == true) {
          continue;
        }
        data['uid'] = swiperIds[i];
        data['swipeTimestamp'] = swipeDocsByUser[swiperIds[i]]!.data()['timestamp'];
        likers.add(data);
      }
    }

    return likers;
  }

  /// Profiles used as blurred teasers for non-premium users. The demo
  /// account prefers seeded demo profiles (they can't leak to real
  /// users); everyone else sees real profiles only. Failures are
  /// non-fatal — the grid pads itself with placeholder cards.
  Future<List<Map<String, dynamic>>> _fetchTeaserProfiles() async {
    final user = _authService.currentUser;
    if (user == null) return [];
    final canSeeDemo = MatchingService.canSeeDemoContent;
    try {
      // Real users only ever see people who actually liked them — the grid
      // fills with placeholder cards instead of pretending random profiles
      // are likes. Only demo/dev accounts get seeded teaser profiles.
      if (!canSeeDemo) return [];
      var snapshot = await _firestore
          .collection('profiles')
          .where('isDemo', isEqualTo: true)
          .limit(18)
          .get();
      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore.collection('profiles').limit(18).get();
      }
      return snapshot.docs
          .map((d) => d.data())
          .where((data) =>
              data['uid'] != user.uid && data['banned'] != true)
          .toList();
    } catch (e) {
      debugPrint('Teaser profiles failed: $e');
      return [];
    }
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No se pudieron cargar los likes',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    slivers: [
                      if (!_isPremium) _buildPremiumBanner(isDarkMode),
                      _isPremium
                          ? _buildLikersList(isDarkMode)
                          : _buildTeaserGrid(isDarkMode),
                    ],
                  ),
                ),
    );
  }

  /// Banner premium con la misma identidad que la tarjeta del perfil:
  /// gradiente morado→rosa, contador real de likes y CTA blanco.
  Widget _buildPremiumBanner(bool isDarkMode) {
    final count = _likers.length;
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _goToPremium,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              count > 0
                                  ? 'A $count ${count == 1 ? 'persona le' : 'personas les'} gustas'
                                  : 'Descubre quién te ha dado like',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Hazte Premium y desbloquea sus perfiles.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _goToPremium,
                      icon: const Icon(Icons.workspace_premium_rounded,
                          size: 18),
                      label: const Text(
                        'Hazte Premium',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.secondaryPurple,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Blurred grid shown to non-premium users: real likers first, then
  /// demo profiles, then placeholder cards — always looks populated,
  /// which also helps demo the upsell flow.
  Widget _buildTeaserGrid(bool isDarkMode) {
    final cards = <Map<String, dynamic>?>[
      ..._likers,
      ..._teasers.where(
          (t) => !_likers.any((l) => l['uid'] == t['uid'])),
    ];
    while (cards.length < 9) {
      cards.add(null);
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildTeaserCard(cards[index], isDarkMode),
          childCount: cards.length,
        ),
      ),
    );
  }

  Widget _buildTeaserCard(Map<String, dynamic>? user, bool isDarkMode) {
    final profile = user?['profile'] as Map<String, dynamic>?;
    final photos = profile?['photos'] as List?;
    final photoUrl = (user?['photoURL'] as String?) ??
        (photos != null && photos.isNotEmpty ? photos.first as String : null);

    final image = photoUrl != null
        ? CachedNetworkImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            memCacheWidth: 400,
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          )
        : Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Center(
              child: Icon(
                Icons.person_rounded,
                size: 48,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: isDarkMode ? AppTheme.darkSurface : const Color(0xFFF1F5F9),
        child: InkWell(
          onTap: _goToPremium,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Blurred photo — enough to hint at a person, never readable
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: image,
              ),
              // Darkening veil so the card reads as "locked"
              Container(color: Colors.black.withValues(alpha: 0.15)),
              // Like badge
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentPink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
              // Fake hidden name
              Positioned(
                left: 8,
                right: 24,
                bottom: 10,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
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
        backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl, maxWidth: 200) : null,
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
      onTap: () {
        if (_isPremium) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfileDetailsScreen(profile: liker),
            ),
          );
        } else {
          _goToPremium();
        }
      },
    );

    if (_isPremium) return tile;

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: tile,
    );
  }
}
