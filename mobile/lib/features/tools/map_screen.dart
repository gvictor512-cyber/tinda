import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../services/matching_service.dart';

/// Browse real listings: landlord profiles expose an `apartment` map in the
/// public `profiles` collection (synced by PublicProfileService).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<QuerySnapshot> _listingsFuture = _fetchListings();

  Future<QuerySnapshot> _fetchListings() {
    return FirebaseFirestore.instance
        .collection('profiles')
        .where('userType', isEqualTo: 'landlord')
        .limit(50)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pisos disponibles'),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _listingsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No se pudieron cargar los pisos.'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final listings = snapshot.data?.docs
                  .where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    // Seeded demo listings only show for demo/dev accounts.
                    if (!MatchingService.canSeeDemoContent &&
                        data['isDemo'] == true) {
                      return false;
                    }
                    return data['apartment'] is Map;
                  })
                  .toList() ??
              [];

          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work_outlined,
                      size: 64,
                      color: isDarkMode
                          ? AppTheme.textLightSecondary
                          : AppTheme.textDarkSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no hay pisos publicados',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? AppTheme.textLightSecondary
                          : AppTheme.textDarkSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _listingsFuture = _fetchListings());
              await _listingsFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final data = listings[index].data() as Map<String, dynamic>;
                final apartment =
                    (data['apartment'] as Map).cast<String, dynamic>();
                return _buildListingCard(data, apartment, isDarkMode);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> profile,
      Map<String, dynamic> apartment, bool isDarkMode) {
    final photos = apartment['photos'] as List?;
    final photoUrl =
        photos != null && photos.isNotEmpty ? photos[0] as String : null;
    final title = apartment['title']?.toString() ?? 'Piso compartido';
    final location = apartment['location']?.toString() ?? '';
    final price = apartment['price'];
    final ownerName = profile['name']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholder(),
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isDarkMode ? AppTheme.textLight : AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (location.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppTheme.primaryBlue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode
                                  ? AppTheme.textLightSecondary
                                  : AppTheme.textDarkSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price is num
                            ? '${price.toStringAsFixed(0)}€/mes'
                            : 'Consultar',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (ownerName.isNotEmpty)
                        Text(
                          ownerName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? AppTheme.textLightSecondary
                                : AppTheme.textDarkSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.home_outlined, color: AppTheme.primaryBlue, size: 36),
      ),
    );
  }
}
