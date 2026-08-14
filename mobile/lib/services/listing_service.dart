import 'package:cloud_firestore/cloud_firestore.dart';
import 'limits_service.dart';
import 'auth_service.dart';
import 'package:roommatematch/debug_print.dart';

/// Service to manage apartment listings
class ListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final LimitsService _limitsService = LimitsService();

  /// Check if user can create a new listing
  Future<bool> canCreateListing() async {
    return await _limitsService.canCreateListing();
  }

  /// Get active listings count for current user
  Future<int> getActiveListingsCount() async {
    return await _limitsService.getActiveListingsCount();
  }

  /// Create a new listing
  Future<String> createListing(Map<String, dynamic> listingData) async {
    try {
      // Check if user can create listing
      final canCreate = await canCreateListing();
      if (!canCreate) {
        final limits = await _limitsService.getUserLimits();
        throw Exception(
          'Has alcanzado tu límite de ${limits.activeListings} anuncios activos. Actualiza a Premium para publicar hasta 10 anuncios.',
        );
      }

      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Add listing data
      final listingRef = await _firestore.collection('listings').add({
        ...listingData,
        'userId': user.uid,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'views': 0,
        'likes': 0,
        'isBoosted': false,
      });

      return listingRef.id;
    } catch (e) {
      debugPrint('Error creating listing: $e');
      rethrow;
    }
  }

  /// Update an existing listing
  Future<void> updateListing(String listingId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating listing: $e');
      rethrow;
    }
  }

  /// Deactivate a listing (soft delete)
  Future<void> deactivateListing(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error deactivating listing: $e');
      rethrow;
    }
  }

  /// Permanently delete a listing
  Future<void> deleteListing(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).delete();
    } catch (e) {
      debugPrint('Error deleting listing: $e');
      rethrow;
    }
  }

  /// Get user's listings
  Future<List<Map<String, dynamic>>> getUserListings() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('listings')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting user listings: $e');
      return [];
    }
  }

  /// Get user's active listings
  Future<List<Map<String, dynamic>>> getActiveListings() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('listings')
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting active listings: $e');
      return [];
    }
  }

  /// Get listing by ID
  Future<Map<String, dynamic>?> getListing(String listingId) async {
    try {
      final doc = await _firestore.collection('listings').doc(listingId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data != null) {
        data['id'] = doc.id;
      }
      return data;
    } catch (e) {
      debugPrint('Error getting listing: $e');
      return null;
    }
  }

  /// Increment listing views
  Future<void> incrementViews(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  /// Boost a listing (highlight for 24 hours)
  Future<void> boostListing(String listingId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // Check if user can boost
      final canBoost = await _limitsService.canUseBoost();
      if (!canBoost) {
        throw Exception('Has alcanzado tu límite de Boosts semanales. Actualiza a Premium para obtener más.');
      }

      // Record boost usage
      await _limitsService.recordBoost(durationMinutes: 1440); // 24 hours

      // Update listing
      final boostEndTime = DateTime.now().add(const Duration(hours: 24));
      await _firestore.collection('listings').doc(listingId).update({
        'isBoosted': true,
        'boostEndTime': Timestamp.fromDate(boostEndTime),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error boosting listing: $e');
      rethrow;
    }
  }

  /// Get listing statistics
  Future<Map<String, dynamic>> getListingStats(String listingId) async {
    try {
      final listing = await getListing(listingId);
      if (listing == null) return {};

      final hasFullStats = await _limitsService.hasFullStatistics();

      if (hasFullStats) {
        // Return full statistics for premium users
        return {
          'views': listing['views'] ?? 0,
          'likes': listing['likes'] ?? 0,
          'shares': listing['shares'] ?? 0,
          'contactRequests': listing['contactRequests'] ?? 0,
          'createdAt': listing['createdAt'],
          'lastViewed': listing['lastViewed'],
          'averageRating': listing['averageRating'] ?? 0.0,
          'totalRatings': listing['totalRatings'] ?? 0,
        };
      } else {
        // Return basic statistics for free users
        return {
          'views': listing['views'] ?? 0,
          'likes': listing['likes'] ?? 0,
        };
      }
    } catch (e) {
      debugPrint('Error getting listing stats: $e');
      return {};
    }
  }

  /// Search listings with filters
  Future<List<Map<String, dynamic>>> searchListings({
    String? city,
    int? minPrice,
    int? maxPrice,
    int? minBedrooms,
    int? maxBedrooms,
    bool? petsAllowed,
    bool? smokersAllowed,
    bool? studentsAllowed,
    bool? workersAllowed,
  }) async {
    try {
      Query query = _firestore.collection('listings').where('isActive', isEqualTo: true);

      if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }

      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }

      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }

      if (minBedrooms != null) {
        query = query.where('bedrooms', isGreaterThanOrEqualTo: minBedrooms);
      }

      if (maxBedrooms != null) {
        query = query.where('bedrooms', isLessThanOrEqualTo: maxBedrooms);
      }

      // Advanced filters (premium only)
      final hasAdvancedFilters = await _limitsService.hasAdvancedFilters();

      if (hasAdvancedFilters) {
        if (petsAllowed != null) {
          query = query.where('conditions.pets', isEqualTo: petsAllowed);
        }
        if (smokersAllowed != null) {
          query = query.where('conditions.smokers', isEqualTo: smokersAllowed);
        }
        if (studentsAllowed != null) {
          query = query.where('conditions.students', isEqualTo: studentsAllowed);
        }
        if (workersAllowed != null) {
          query = query.where('conditions.workers', isEqualTo: workersAllowed);
        }
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map<dynamic, dynamic>);
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error searching listings: $e');
      return [];
    }
  }
}
