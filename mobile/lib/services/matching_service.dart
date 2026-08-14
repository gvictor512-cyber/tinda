import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../utils/input_sanitizer.dart';
import '../utils/rate_limiter.dart';
import '../utils/secure_logger.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Minimum compatibility threshold (percentage)
  static const double MIN_COMPATIBILITY_THRESHOLD = 50.0;

  // Budget tolerance percentage
  static const double BUDGET_TOLERANCE_PERCENTAGE = 0.2;

  // Earth radius in km for distance calculation
  static const double EARTH_RADIUS_KM = 6371.0;

  // Calculate compatibility score between two users
  double calculateCompatibility(Map<String, dynamic> user1, Map<String, dynamic> user2) {
    double score = 0.0;
    int factors = 0;

    // Factor 1: User type compatibility
    final type1 = user1['userType'] as String?;
    final type2 = user2['userType'] as String?;
    if (type1 != null && type2 != null && type1 != type2) {
      score += 30; // Roommate seeker matches with roommate offer
    }
    factors++;

    // Factor 2: Location proximity
    final loc1 = user1['preferences']?['location'] as GeoPoint?;
    final loc2 = user2['preferences']?['location'] as GeoPoint?;
    if (loc1 != null && loc2 != null) {
      final distance = _calculateDistance(loc1, loc2);
      final maxDistance = (user1['preferences']?['maxDistance'] as num?)?.toDouble() ?? 50.0;
      if (distance <= maxDistance) {
        score += 20 * (1 - distance / maxDistance);
      }
    }
    factors++;

    // Factor 3: Age range compatibility
    final age1 = user1['profile']?['age'] as num?;
    final age2 = user2['profile']?['age'] as num?;
    if (age1 != null && age2 != null) {
      final ageRange1 = user1['preferences']?['ageRange'] as List?;
      final ageRange2 = user2['preferences']?['ageRange'] as List?;
      
      if (ageRange1 != null && ageRange2 != null && ageRange1.length >= 2 && ageRange2.length >= 2) {
        final min1 = ageRange1[0] as num;
        final max1 = ageRange1[1] as num;
        final min2 = ageRange2[0] as num;
        final max2 = ageRange2[1] as num;
        
        if (age2 >= min1 && age2 <= max1 && age1 >= min2 && age1 <= max2) {
          score += 15;
        }
      }
    }
    factors++;

    // Factor 4: Gender preference
    final gender1 = user1['preferences']?['gender'] as String?;
    final gender2 = user2['profile']?['gender'] as String?;
    if (gender1 != null && gender2 != null) {
      if (gender1 == 'all' || gender1 == gender2) {
        score += 10;
      }
    }
    factors++;

    // Factor 5: Shared interests
    final interests1 = user1['profile']?['interests'] as List?;
    final interests2 = user2['profile']?['interests'] as List?;
    if (interests1 != null && interests2 != null && interests1.isNotEmpty && interests2.isNotEmpty) {
      final shared = interests1.where((i) => interests2.contains(i)).length;
      final total = max(interests1.length, interests2.length);
      if (total > 0) {
        score += 15 * (shared / total);
      }
    }
    factors++;

    // Factor 6: Budget compatibility
    final budget1 = user1['preferences']?['budget'] as num?;
    final budget2 = user2['preferences']?['budget'] as num?;
    if (budget1 != null && budget2 != null) {
      final difference = (budget1 - budget2).abs();
      final tolerance = max(budget1, budget2) * BUDGET_TOLERANCE_PERCENTAGE;
      if (difference <= tolerance) {
        score += 10;
      }
    }
    factors++;

    // Normalize score
    return factors > 0 ? score / factors * 100 : 0;
  }

  // Calculate distance between two GeoPoints in km
  double _calculateDistance(GeoPoint loc1, GeoPoint loc2) {
    final lat1 = loc1.latitude * pi / 180;
    final lat2 = loc2.latitude * pi / 180;
    final deltaLat = (loc2.latitude - loc1.latitude) * pi / 180;
    final deltaLon = (loc2.longitude - loc1.longitude) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * asin(sqrt(a));

    return EARTH_RADIUS_KM * c;
  }

  // Get potential matches for current user
  Future<List<Map<String, dynamic>>> getPotentialMatches() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Usuario no autenticado - devolviendo lista vacía');
        return [];
      }

      final userData = await _firestore.collection('users').doc(currentUser.uid).get();
      final userPreferences = userData.data()?['preferences'] as Map<String, dynamic>?;
      final userType = userData.data()?['userType'] as String?;

      if (userPreferences == null) return [];

      // Get users who haven't been swiped by current user
      final swipesSnapshot = await _firestore
          .collection('swipes')
          .where('swiperId', isEqualTo: currentUser.uid)
          .get();

      final swipedUserIds = swipesSnapshot.docs.map((doc) => doc.data()['swipedId'] as String?).where((id) => id != null).toSet();

      // Get users who haven't matched with current user
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('users', arrayContains: currentUser.uid)
          .get();

      final matchedUserIds = <String>{};
      for (var doc in matchesSnapshot.docs) {
        final users = doc.data()['users'] as List?;
        if (users != null) {
          for (var userId in users) {
            if (userId != currentUser.uid) {
              matchedUserIds.add(userId as String);
            }
          }
        }
      }

      // Query potential candidates
      final candidatesQuery = _firestore.collection('users')
          .where('uid', isNotEqualTo: currentUser.uid)
          .where('userType', isNotEqualTo: userType); // Match opposite types

      final candidatesSnapshot = await candidatesQuery.get();

      List<Map<String, dynamic>> potentialMatches = [];

      for (var doc in candidatesSnapshot.docs) {
        final candidateData = doc.data();
        final candidateId = candidateData['uid'] as String?;

        if (candidateId == null) continue;

        // Skip if already swiped or matched
        if (swipedUserIds.contains(candidateId) || matchedUserIds.contains(candidateId)) {
          continue;
        }

        // Calculate compatibility
        final compatibility = calculateCompatibility(userData.data()!, candidateData);

        // Only include if compatibility meets threshold
        if (compatibility > MIN_COMPATIBILITY_THRESHOLD) {
          candidateData['compatibility'] = compatibility;
          candidateData['documentId'] = doc.id;
          potentialMatches.add(candidateData);
        }
      }

      // Sort by compatibility (highest first)
      potentialMatches.sort((a, b) => (b['compatibility'] as double).compareTo(a['compatibility'] as double));

      return potentialMatches;
    } catch (e) {
      debugPrint('Error getting potential matches: $e');
      rethrow;
    }
  }

  // Record a swipe action
  Future<void> recordSwipe({
    required String swipedId,
    required bool isLike,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        SecureLogger.warning('Unauthenticated swipe attempt');
        throw Exception('Usuario no autenticado');
      }

      // Check rate limiting for swipes
      final rateLimitResult = await RateLimiter.canSwipe(currentUser.uid);
      if (!rateLimitResult.allowed) {
        throw Exception(rateLimitResult.message);
      }

      // Validate swiped ID
      if (swipedId.isEmpty || swipedId == currentUser.uid) {
        throw Exception('ID de usuario inválido');
      }

      SecureLogger.debug('Recording swipe', data: {
        'swiper': currentUser.uid,
        'swiped': swipedId,
        'isLike': isLike,
      });

      await _firestore.collection('swipes').add({
        'swiperId': currentUser.uid,
        'swipedId': swipedId,
        'isLike': isLike,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // If it's a like, check if there's a mutual like
      if (isLike) {
        await _checkForMatch(swiperId: currentUser.uid, swipedId: swipedId);
      }
    } catch (e) {
      SecureLogger.error('Failed to record swipe', error: e);
      rethrow;
    }
  }

  // Check if there's a mutual match
  Future<void> _checkForMatch({required String swiperId, required String swipedId}) async {
    try {
      // Check if the other user has also liked this user
      final mutualSwipeQuery = await _firestore
          .collection('swipes')
          .where('swiperId', isEqualTo: swipedId)
          .where('swipedId', isEqualTo: swiperId)
          .where('isLike', isEqualTo: true)
          .get();

      if (mutualSwipeQuery.docs.isNotEmpty) {
        // It's a match! Create match document
        await _firestore.collection('matches').add({
          'users': [swiperId, swipedId],
          'timestamp': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'unreadCount': {
            swiperId: 0,
            swipedId: 0,
          },
        });

        // Create chat room
        await _firestore.collection('chats').add({
          'participants': [swiperId, swipedId],
          'lastMessage': null,
          'lastMessageTimestamp': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error checking for match: $e');
      rethrow;
    }
  }

  // Get all matches for current user
  Future<List<Map<String, dynamic>>> getMatches() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Usuario no autenticado - devolviendo lista vacía');
        return [];
      }

      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('users', arrayContains: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> matches = [];

      for (var doc in matchesSnapshot.docs) {
        final matchData = doc.data();
        final users = matchData['users'] as List?;
        
        if (users == null || users.isEmpty) continue;
        
        // Get the other user's data
        final otherUserId = users.firstWhere((id) => id != currentUser.uid, orElse: () => null);
        if (otherUserId == null) continue;
        
        final otherUserDoc = await _firestore.collection('users').doc(otherUserId as String).get();
        
        if (otherUserDoc.exists) {
          final otherUserData = otherUserDoc.data();
          if (otherUserData != null) {
            otherUserData['matchId'] = doc.id;
            otherUserData['matchTimestamp'] = matchData['timestamp'];
            matches.add(otherUserData);
          }
        }
      }

      return matches;
    } catch (e) {
      debugPrint('Error getting matches: $e');
      rethrow;
    }
  }

  // Get users who liked the current user (Premium feature)
  Future<List<Map<String, dynamic>>> getWhoLikedYou() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Usuario no autenticado - devolviendo lista vacía');
        return [];
      }

      // Get all swipes where the current user was swiped and it was a like
      final likesSnapshot = await _firestore
          .collection('swipes')
          .where('swipedId', isEqualTo: currentUser.uid)
          .where('isLike', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> likedByUsers = [];
      Set<String> processedUserIds = {};

      for (var doc in likesSnapshot.docs) {
        final swipeData = doc.data();
        final swiperId = swipeData['swiperId'] as String?;
        
        if (swiperId == null || processedUserIds.contains(swiperId)) continue;
        processedUserIds.add(swiperId);

        // Get the swiper's user data
        final userDoc = await _firestore.collection('users').doc(swiperId).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            userData['swipeTimestamp'] = swipeData['timestamp'];
            userData['swipeId'] = doc.id;
            likedByUsers.add(userData);
          }
        }
      }

      return likedByUsers;
    } catch (e) {
      debugPrint('Error getting who liked you: $e');
      rethrow;
    }
  }

  // Undo last swipe
  Future<void> undoSwipe() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Usuario no autenticado - no se puede deshacer swipe');
        return;
      }

      final lastSwipeQuery = await _firestore
          .collection('swipes')
          .where('swiperId', isEqualTo: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (lastSwipeQuery.docs.isNotEmpty) {
        await _firestore.collection('swipes').doc(lastSwipeQuery.docs.first.id).delete();
      }
    } catch (e) {
      debugPrint('Error undoing swipe: $e');
      rethrow;
    }
  }

  // Send a Super Like (special notification)
  Future<void> sendSuperLike(String swipedId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        SecureLogger.warning('Unauthenticated super like attempt');
        throw Exception('Usuario no autenticado');
      }

      // Check rate limiting
      final rateLimitResult = await RateLimiter.canSwipe(currentUser.uid);
      if (!rateLimitResult.allowed) {
        throw Exception(rateLimitResult.message);
      }

      // Validate swiped ID
      if (swipedId.isEmpty || swipedId == currentUser.uid) {
        throw Exception('ID de usuario inválido');
      }

      SecureLogger.debug('Sending super like', data: {
        'swiper': currentUser.uid,
        'swiped': swipedId,
      });

      await _firestore.collection('swipes').add({
        'swiperId': currentUser.uid,
        'swipedId': swipedId,
        'isLike': true,
        'isSuperLike': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Check if there's a mutual like
      await _checkForMatch(swiperId: currentUser.uid, swipedId: swipedId);
    } catch (e) {
      SecureLogger.error('Failed to send super like', error: e);
      rethrow;
    }
  }

  // Get swipe statistics
  Future<Map<String, int>> getSwipeStats() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Usuario no autenticado - devolviendo estadísticas vacías');
        return {'likes': 0, 'passes': 0, 'total': 0};
      }

      final swipesSnapshot = await _firestore
          .collection('swipes')
          .where('swiperId', isEqualTo: currentUser.uid)
          .get();

      int likes = 0;
      int passes = 0;

      for (var doc in swipesSnapshot.docs) {
        final isLike = doc.data()['isLike'] as bool?;
        if (isLike == true) {
          likes++;
        } else {
          passes++;
        }
      }

      return {
        'likes': likes,
        'passes': passes,
        'total': likes + passes,
      };
    } catch (e) {
      debugPrint('Error getting swipe stats: $e');
      rethrow;
    }
  }

  // Update user preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        SecureLogger.warning('Unauthenticated preferences update attempt');
        throw Exception('Usuario no autenticado');
      }

      // Validate and sanitize preferences
      final sanitizedPreferences = _sanitizePreferences(preferences);

      SecureLogger.debug('Updating user preferences', userId: currentUser.uid);

      await _firestore.collection('users').doc(currentUser.uid).update({
        'preferences': sanitizedPreferences,
      });
    } catch (e) {
      SecureLogger.error('Failed to update preferences', error: e);
      rethrow;
    }
  }

  // Sanitize user preferences
  Map<String, dynamic> _sanitizePreferences(Map<String, dynamic> preferences) {
    final sanitized = <String, dynamic>{};

    for (final entry in preferences.entries) {
      final key = entry.key;
      final value = entry.value;

      switch (key) {
        case 'ageRange':
          if (value is List && value.length >= 2) {
            final minAge = value[0] as num?;
            final maxAge = value[1] as num?;
            if (minAge != null && maxAge != null && minAge >= 18 && maxAge <= 100 && minAge <= maxAge) {
              sanitized[key] = [minAge.toInt(), maxAge.toInt()];
            }
          }
          break;
        case 'gender':
          if (value is String && ['male', 'female', 'all'].contains(value)) {
            sanitized[key] = value;
          }
          break;
        case 'maxDistance':
          if (value is num && value >= 1 && value <= 500) {
            sanitized[key] = value.toInt();
          }
          break;
        case 'budget':
          if (value is num && value >= 0) {
            sanitized[key] = value.toDouble();
          }
          break;
        case 'location':
          if (value is GeoPoint) {
            sanitized[key] = value;
          }
          break;
        default:
          // Sanitize other fields
          if (value is String) {
            sanitized[key] = InputSanitizer.sanitizeString(value);
          } else {
            sanitized[key] = value;
          }
      }
    }

    return sanitized;
  }

  // Get user preferences
  Future<Map<String, dynamic>?> getPreferences() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('Usuario no autenticado - devolviendo null');
        return null;
      }

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      
      return userData?['preferences'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting preferences: $e');
      rethrow;
    }
  }
}
