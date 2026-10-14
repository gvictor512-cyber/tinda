import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'analytics_service.dart';
import 'api_service.dart';
import '../utils/input_sanitizer.dart';
import '../utils/rate_limiter.dart';
import '../utils/geohash.dart';
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

  // Calculate compatibility score between two users (0-100).
  // Each factor only counts toward the maximum when both users provide data.
  double calculateCompatibility(
      Map<String, dynamic> user1, Map<String, dynamic> user2) {
    double score = 0.0;
    double maxScore = 0.0;

    // Factor 1: User type compatibility
    final type1 = user1['userType'] as String?;
    final type2 = user2['userType'] as String?;
    if (type1 != null && type2 != null) {
      maxScore += 30;
      if (type1 != type2) {
        score += 30; // Roommate seeker matches with roommate offer
      }
    }

    // Factor 2: Location proximity
    final loc1 = user1['preferences']?['location'] as GeoPoint?;
    final loc2 = user2['preferences']?['location'] as GeoPoint?;
    if (loc1 != null && loc2 != null) {
      maxScore += 20;
      final distance = _calculateDistance(loc1, loc2);
      final maxDistance =
          (user1['preferences']?['maxDistance'] as num?)?.toDouble() ?? 50.0;
      if (distance <= maxDistance) {
        score += 20 * (1 - distance / maxDistance);
      }
    }

    // Factor 3: Age range compatibility
    final age1 = user1['profile']?['age'] as num?;
    final age2 = user2['profile']?['age'] as num?;
    final ageRange1 = user1['preferences']?['ageRange'] as List?;
    final ageRange2 = user2['preferences']?['ageRange'] as List?;
    if (age1 != null &&
        age2 != null &&
        ageRange1 != null &&
        ageRange2 != null &&
        ageRange1.length >= 2 &&
        ageRange2.length >= 2) {
      maxScore += 15;
      final min1 = ageRange1[0] as num;
      final max1 = ageRange1[1] as num;
      final min2 = ageRange2[0] as num;
      final max2 = ageRange2[1] as num;
      if (age2 >= min1 && age2 <= max1 && age1 >= min2 && age1 <= max2) {
        score += 15;
      }
    }

    // Factor 4: Gender preference
    final gender1 = user1['preferences']?['gender'] as String?;
    final gender2 = user2['profile']?['gender'] as String?;
    if (gender1 != null && gender2 != null) {
      maxScore += 10;
      if (gender1 == 'all' || gender1 == gender2) {
        score += 10;
      }
    }

    // Factor 5: Shared interests
    final interests1 = user1['profile']?['interests'] as List?;
    final interests2 = user2['profile']?['interests'] as List?;
    if (interests1 != null &&
        interests2 != null &&
        interests1.isNotEmpty &&
        interests2.isNotEmpty) {
      maxScore += 15;
      final shared = interests1.where((i) => interests2.contains(i)).length;
      final total = max(interests1.length, interests2.length);
      if (total > 0) {
        score += 15 * (shared / total);
      }
    }

    // Factor 6: Budget compatibility
    final budget1 = user1['preferences']?['budget'] as num?;
    final budget2 = user2['preferences']?['budget'] as num?;
    if (budget1 != null && budget2 != null) {
      maxScore += 10;
      final difference = (budget1 - budget2).abs();
      final tolerance = max(budget1, budget2) * BUDGET_TOLERANCE_PERCENTAGE;
      if (difference <= tolerance) {
        score += 10;
      }
    }

    return maxScore > 0 ? (score / maxScore * 100).clamp(0.0, 100.0) : 0;
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

      // Fetch user doc and all exclusion lists in parallel
      final userDocFuture =
          _firestore.collection('users').doc(currentUser.uid).get();
      final swipesFuture = _firestore
          .collection('swipes')
          .where('swiperId', isEqualTo: currentUser.uid)
          .get();
      final matchesFuture = _firestore
          .collection('matches')
          .where('users', arrayContains: currentUser.uid)
          .get();
      final blockedByMeFuture = _firestore
          .collection('blocked_users')
          .where('blockerId', isEqualTo: currentUser.uid)
          .get();
      final blockedMeFuture = _firestore
          .collection('blocked_users')
          .where('blockedId', isEqualTo: currentUser.uid)
          .get();
      // Incoming likes: profiles that already liked us go first in the
      // deck, so liking them produces an instant match.
      final likedMeFuture = _firestore
          .collection('swipes')
          .where('swipedId', isEqualTo: currentUser.uid)
          .where('isLike', isEqualTo: true)
          .get();
      final userData = await userDocFuture;
      final userPreferences =
          userData.data()?['preferences'] as Map<String, dynamic>?;
      final userType = userData.data()?['userType'] as String?;

      // Bounded query: when we know the user's coarse location we only
      // fetch profiles in the geohash cell covering maxDistance instead of
      // scanning the whole collection. Falls back to a cap otherwise.
      Query<Map<String, dynamic>> candidatesQuery =
          _firestore.collection('profiles');
      final myLoc = userPreferences?['location'] as GeoPoint?;
      final maxDist = (userPreferences?['maxDistance'] as num?)?.toDouble();
      if (myLoc != null) {
        final prefixLen = GeoHash.prefixForRadius(maxDist ?? 50);
        final prefix = GeoHash.encode(
          myLoc.latitude,
          myLoc.longitude,
          precision: prefixLen,
        );
        candidatesQuery = candidatesQuery.orderBy('geohash').startAt(
            [prefix]).endAt([GeoHash.prefixUpperBound(prefix)]).limit(200);
      } else {
        candidatesQuery = candidatesQuery.limit(100);
      }
      final candidatesFuture = candidatesQuery.get();

      if (userPreferences == null) return [];

      final swipesSnapshot = await swipesFuture;
      final matchesSnapshot = await matchesFuture;
      final blockedByMeSnapshot = await blockedByMeFuture;
      final blockedMeSnapshot = await blockedMeFuture;
      final candidatesSnapshot = await candidatesFuture;
      // Non-fatal: a missing index or rules denial must not kill the deck.
      Set<String> likedMeIds = {};
      try {
        final likedMeSnapshot = await likedMeFuture;
        likedMeIds = likedMeSnapshot.docs
            .map((d) => d.data()['swiperId'] as String?)
            .whereType<String>()
            .toSet();
      } catch (e) {
        debugPrint('likedMe query skipped: $e');
      }

      // Fallback: the bounded geohash cell may be empty for users at cell
      // edges or until profiles re-sync the geohash field — merge a broad
      // query so the deck never starves.
      var candidateDocs = candidatesSnapshot.docs;
      if (myLoc != null && candidateDocs.length < 15) {
        final broad = await _firestore.collection('profiles').limit(100).get();
        final seen = candidateDocs.map((d) => d.id).toSet();
        candidateDocs = [
          ...candidateDocs,
          ...broad.docs.where((d) => !seen.contains(d.id)),
        ];
      }

      // Get users who haven't been swiped by current user
      final swipedUserIds = swipesSnapshot.docs
          .map((doc) => doc.data()['swipedId'] as String?)
          .where((id) => id != null)
          .toSet();

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

      // Users blocked in either direction (blocked_users collection)
      final blockedUserIds = <String>{};
      for (var doc in blockedByMeSnapshot.docs) {
        final blockedId = doc.data()['blockedId'] as String?;
        if (blockedId != null) blockedUserIds.add(blockedId);
      }
      for (var doc in blockedMeSnapshot.docs) {
        final blockerId = doc.data()['blockerId'] as String?;
        if (blockerId != null) blockedUserIds.add(blockerId);
      }
      // Legacy array-based blocks stored on the user document
      final blockedArray = userData.data()?['blockedUsers'] as List?;
      if (blockedArray != null) {
        blockedUserIds.addAll(blockedArray.whereType<String>());
      }

      List<Map<String, dynamic>> potentialMatches = [];

      for (var doc in candidateDocs) {
        final candidateData = doc.data();
        final candidateId = candidateData['uid'] as String?;

        if (candidateId == null) continue;
        if (candidateId == currentUser.uid) continue;
        if (userType != null && candidateData['userType'] == userType) continue;
        if (candidateData['banned'] == true) continue;

        // Hard distance filter when both locations are known
        if (myLoc != null && maxDist != null) {
          final candLoc = (candidateData['preferences']
              as Map<String, dynamic>?)?['location'] as GeoPoint?;
          if (candLoc != null && _calculateDistance(myLoc, candLoc) > maxDist) {
            continue;
          }
        }

        // Skip if blocked in either direction
        if (blockedUserIds.contains(candidateId)) continue;

        // Skip if already swiped or matched
        if (swipedUserIds.contains(candidateId) ||
            matchedUserIds.contains(candidateId)) {
          continue;
        }

        // Calculate compatibility
        final compatibility =
            calculateCompatibility(userData.data()!, candidateData);

        // Only include if compatibility meets threshold
        if (compatibility > MIN_COMPATIBILITY_THRESHOLD) {
          candidateData['compatibility'] = compatibility;
          candidateData['documentId'] = doc.id;
          // Distance in km for the card's "A N km" line — only set when
          // both locations are known.
          final candidateLoc = (candidateData['preferences']
              as Map<String, dynamic>?)?['location'] as GeoPoint?;
          if (myLoc != null && candidateLoc != null) {
            candidateData['distanceKm'] =
                _calculateDistance(myLoc, candidateLoc);
          }
          potentialMatches.add(candidateData);
        }
      }

      // Likers first (instant match on a like), then by compatibility.
      potentialMatches.sort((a, b) {
        final aLikes = likedMeIds.contains(a['uid']);
        final bLikes = likedMeIds.contains(b['uid']);
        if (aLikes != bLikes) return aLikes ? -1 : 1;
        return (b['compatibility'] as double)
            .compareTo(a['compatibility'] as double);
      });

      return potentialMatches;
    } catch (e) {
      debugPrint('Error getting potential matches: $e');
      rethrow;
    }
  }

  // Record a swipe action. Returns true if the swipe resulted in a new match.
  Future<bool> recordSwipe({
    required String swipedId,
    required bool isLike,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        SecureLogger.warning('Unauthenticated swipe attempt');
        throw Exception('Usuario no autenticado');
      }

      // Local rate limiting is best-effort: a Keychain/storage hiccup
      // must never block a legitimate swipe.
      try {
        final rateLimitResult = await RateLimiter.canSwipe(currentUser.uid);
        if (!rateLimitResult.allowed) {
          throw Exception(rateLimitResult.message);
        }
      } on Exception catch (e) {
        if (e.toString().contains('límite de swipes')) rethrow;
        SecureLogger.warning('Swipe rate limiter skipped',
            data: {'error': e.toString()});
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

      // Deterministic doc id prevents duplicate swipes and lets the
      // security rules verify mutual likes for match/chat creation.
      // If the Firestore write fails (rules, network), fall back to the
      // backend endpoint which runs with the Admin SDK.
      try {
        await _firestore
            .collection('swipes')
            .doc('${currentUser.uid}_$swipedId')
            .set({
          'swiperId': currentUser.uid,
          'swipedId': swipedId,
          'isLike': isLike,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        return await _recordSwipeViaBackend(
          uid: currentUser.uid,
          swipedId: swipedId,
          isLike: isLike,
        );
      }

      // If it's a like, check if there's a mutual like. If the match
      // creation itself fails (rules deny the batch), the backend
      // endpoint resolves the whole swipe+match idempotently.
      if (isLike) {
        try {
          return await _checkForMatch(
              swiperId: currentUser.uid, swipedId: swipedId);
        } catch (e) {
          debugPrint('Match check failed, resolving via backend: $e');
          return await _recordSwipeViaBackend(
            uid: currentUser.uid,
            swipedId: swipedId,
            isLike: isLike,
          );
        }
      }
      return false;
    } catch (e) {
      SecureLogger.error('Failed to record swipe', error: e);
      rethrow;
    }
  }

  /// Fallback path: records the swipe (and resolves the match) through
  /// the backend Admin SDK when the direct Firestore write is rejected.
  Future<bool> _recordSwipeViaBackend({
    required String uid,
    required String swipedId,
    required bool isLike,
    bool isSuperLike = false,
  }) async {
    final user = _auth.currentUser;
    final token = await user?.getIdToken();
    if (token == null) throw Exception('Usuario no autenticado');
    final api = ApiService();
    api.setAuthToken(token);
    try {
      final res = await api.post('/users/me/swipe', data: {
        'swipedId': swipedId,
        'isLike': isLike,
        'isSuperLike': isSuperLike,
      });
      return res.data?['matched'] == true;
    } finally {
      api.clearAuthToken();
    }
  }

  // Check if there's a mutual match. Returns true if a new match was created.
  Future<bool> _checkForMatch(
      {required String swiperId, required String swipedId}) async {
    try {
      // Deterministic swipe id lets us check the mutual like with a
      // single document read instead of a query.
      bool hasMutualLike;
      try {
        final mutualSwipe = await _firestore
            .collection('swipes')
            .doc('${swipedId}_$swiperId')
            .get();
        hasMutualLike =
            mutualSwipe.exists && mutualSwipe.data()?['isLike'] == true;
      } on FirebaseException {
        // Rules deny the read when the doc does not exist (resource.data
        // is null during rule evaluation) — that simply means "no like
        // back", not an error worth surfacing.
        hasMutualLike = false;
      }

      if (hasMutualLike) {
        // Match and chat share the same deterministic id (sorted uids),
        // matching the security rules' expectations.
        final pairId = swiperId.compareTo(swipedId) < 0
            ? '${swiperId}_$swipedId'
            : '${swipedId}_$swiperId';

        final batch = _firestore.batch();
        batch.set(_firestore.collection('matches').doc(pairId), {
          'users': [swiperId, swipedId],
          'timestamp': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'unreadCount': {
            swiperId: 0,
            swipedId: 0,
          },
        });
        batch.set(_firestore.collection('chats').doc(pairId), {
          'participants': [swiperId, swipedId],
          'lastMessage': null,
          'lastMessageTimestamp': null,
          'lastMessageSender': null,
          'createdAt': FieldValue.serverTimestamp(),
          'unreadCounts': {swiperId: 0, swipedId: 0},
        });
        await batch.commit();

        // Notify the other user about the new match
        await NotificationService().sendMatchNotification(swipedId);
        unawaited(AnalyticsService().logMatch(swipedId));

        return true;
      }
      return false;
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

      // Collect other user ids, then fetch all user docs in parallel
      final otherUserIds = <String>[];
      final matchDocsByUser =
          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (var doc in matchesSnapshot.docs) {
        final users = doc.data()['users'] as List?;
        if (users == null || users.isEmpty) continue;
        final otherUserId =
            users.firstWhere((id) => id != currentUser.uid, orElse: () => null);
        if (otherUserId == null) continue;
        otherUserIds.add(otherUserId as String);
        matchDocsByUser[otherUserId] = doc;
      }

      final otherUserDocs = await Future.wait(
        otherUserIds
            .map((id) => _firestore.collection('profiles').doc(id).get()),
      );

      List<Map<String, dynamic>> matches = [];
      for (var i = 0; i < otherUserDocs.length; i++) {
        final otherUserDoc = otherUserDocs[i];
        final matchDoc = matchDocsByUser[otherUserIds[i]]!;
        if (otherUserDoc.exists) {
          final otherUserData = otherUserDoc.data();
          if (otherUserData != null) {
            otherUserData['matchId'] = matchDoc.id;
            otherUserData['matchTimestamp'] = matchDoc.data()['timestamp'];
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

      // Query only swipes targeting the current user — Firestore rules
      // (swipes/{id} read requires swiperId or swipedId == auth.uid)
      // reject unfiltered collection scans, so the previous
      // collection('swipes').get() + client filter always failed.
      final likesSnapshot = await _firestore
          .collection('swipes')
          .where('swipedId', isEqualTo: currentUser.uid)
          .where('isLike', isEqualTo: true)
          .limit(500)
          .get();

      final likesDocs = likesSnapshot.docs.toList();
      likesDocs.sort((a, b) {
        final t1 = a.data()['timestamp'] as Timestamp?;
        final t2 = b.data()['timestamp'] as Timestamp?;
        if (t1 == null || t2 == null) return 0;
        return t2.compareTo(t1);
      });

      // Collect unique swiper ids, then fetch user docs in parallel
      final swiperIds = <String>[];
      final swipeDocsByUser =
          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (var doc in likesDocs) {
        final swiperId = doc.data()['swiperId'] as String?;
        if (swiperId == null || swipeDocsByUser.containsKey(swiperId)) continue;
        swiperIds.add(swiperId);
        swipeDocsByUser[swiperId] = doc;
      }

      final userDocs = await Future.wait(
        swiperIds.map((id) => _firestore.collection('profiles').doc(id).get()),
      );

      List<Map<String, dynamic>> likedByUsers = [];
      for (var i = 0; i < userDocs.length; i++) {
        final userDoc = userDocs[i];
        final swipeDoc = swipeDocsByUser[swiperIds[i]]!;
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            userData['swipeTimestamp'] = swipeDoc.data()['timestamp'];
            userData['swipeId'] = swipeDoc.id;
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
          .limit(50)
          .get();

      final docs = lastSwipeQuery.docs.toList();
      docs.sort((a, b) {
        final t1 = a.data()['timestamp'] as Timestamp?;
        final t2 = b.data()['timestamp'] as Timestamp?;
        if (t1 == null || t2 == null) return 0;
        return t2.compareTo(t1);
      });

      if (docs.isNotEmpty) {
        final swipedId = docs.first.data()['swipedId'] as String?;
        if (swipedId != null) {
          await _firestore
              .collection('swipes')
              .doc('${currentUser.uid}_$swipedId')
              .delete();

          // If the swipe already created a match + chat, remove them too —
          // otherwise the other user keeps an orphaned match they can
          // still open and message. Deletes are attempted independently
          // because a missing doc fails rules evaluation and would abort
          // a batch.
          final pairId = currentUser.uid.compareTo(swipedId) < 0
              ? '${currentUser.uid}_$swipedId'
              : '${swipedId}_${currentUser.uid}';
          try {
            await _firestore.collection('matches').doc(pairId).delete();
          } catch (e) {
            debugPrint('undoSwipe: no match to remove ($e)');
          }
          try {
            await _firestore.collection('chats').doc(pairId).delete();
          } catch (e) {
            debugPrint('undoSwipe: no chat to remove ($e)');
          }
        }
      }
    } catch (e) {
      debugPrint('Error undoing swipe: $e');
      rethrow;
    }
  }

  // Send a Super Like (special notification). Returns true if a new match was created.
  Future<bool> sendSuperLike(String swipedId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        SecureLogger.warning('Unauthenticated super like attempt');
        throw Exception('Usuario no autenticado');
      }

      // Local rate limiting is best-effort — never blocks a swipe.
      try {
        final rateLimitResult = await RateLimiter.canSwipe(currentUser.uid);
        if (!rateLimitResult.allowed) {
          throw Exception(rateLimitResult.message);
        }
      } on Exception catch (e) {
        if (e.toString().contains('límite de swipes')) rethrow;
        SecureLogger.warning('Rate limiter skipped',
            data: {'error': e.toString()});
      }

      // Validate swiped ID
      if (swipedId.isEmpty || swipedId == currentUser.uid) {
        throw Exception('ID de usuario inválido');
      }

      // Super-like quota: premium is unlimited; free tier gets 1/day and
      // can spend purchased superLikesAvailable credits beyond that.
      // (Mirrored server-side in users.service._enforceSwipeLimits.)
      await _consumeSuperLikeCredit(currentUser.uid);

      SecureLogger.debug('Sending super like', data: {
        'swiper': currentUser.uid,
        'swipedId': swipedId,
      });

      try {
        await _firestore
            .collection('swipes')
            .doc('${currentUser.uid}_$swipedId')
            .set({
          'swiperId': currentUser.uid,
          'swipedId': swipedId,
          'isLike': true,
          'isSuperLike': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        return await _recordSwipeViaBackend(
          uid: currentUser.uid,
          swipedId: swipedId,
          isLike: true,
          isSuperLike: true,
        );
      }

      // Check if there's a mutual like; backend resolves it if the
      // client-side match creation is denied.
      try {
        return await _checkForMatch(
            swiperId: currentUser.uid, swipedId: swipedId);
      } catch (e) {
        debugPrint('Match check failed, resolving via backend: $e');
        return await _recordSwipeViaBackend(
          uid: currentUser.uid,
          swipedId: swipedId,
          isLike: true,
          isSuperLike: true,
        );
      }
    } catch (e) {
      SecureLogger.error('Failed to send super like', error: e);
      rethrow;
    }
  }

  /// Enforces the super-like quota. Premium users return immediately.
  /// Free users get 1 super like/day; past that, a purchased
  /// superLikesAvailable credit is consumed. Throws when no quota remains.
  Future<void> _consumeSuperLikeCredit(String uid) async {
    const freeDailySuperLikes = 1;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};

    final subscription = userData['subscription'] as Map<String, dynamic>?;
    final endDate = subscription?['endDate'];
    final endMs = endDate is Timestamp ? endDate.millisecondsSinceEpoch : 0;
    final isPremium = userData['isPremium'] == true &&
        endMs > DateTime.now().millisecondsSinceEpoch;
    if (isPremium) return;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final superLikesToday = await _firestore
        .collection('swipes')
        .where('swiperId', isEqualTo: uid)
        .where('isSuperLike', isEqualTo: true)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    if (superLikesToday.docs.length < freeDailySuperLikes) return;

    final available = (userData['superLikesAvailable'] as num?)?.toInt() ?? 0;
    if (available <= 0) {
      throw Exception('Has alcanzado el límite diario de super likes');
    }
    // Rules allow decrementing superLikesAvailable but never increasing it.
    await _firestore.collection('users').doc(uid).update({
      'superLikesAvailable': FieldValue.increment(-1),
    });
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
            if (minAge != null &&
                maxAge != null &&
                minAge >= 18 &&
                maxAge <= 100 &&
                minAge <= maxAge) {
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

      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();

      return userData?['preferences'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting preferences: $e');
      rethrow;
    }
  }

  /// Bump when the demo profile schema/photos change — older seeded
  /// profiles are purged and recreated on next seed.
  static const int demoSeedVersion = 3;

  /// True when the current user already has usable test interactions:
  /// at least one received like whose swiper profile still exists.
  /// Orphan likes pointing to purged profiles don't count.
  Future<bool> hasTestInteractions() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    try {
      final likes = await _firestore
          .collection('swipes')
          .where('swipedId', isEqualTo: uid)
          .where('isLike', isEqualTo: true)
          .limit(10)
          .get();
      for (final doc in likes.docs) {
        final swiperId = doc.data()['swiperId'] as String?;
        if (swiperId == null) continue;
        final profile =
            await _firestore.collection('profiles').doc(swiperId).get();
        if (profile.exists) return true;
      }
      return false;
    } catch (e) {
      debugPrint('hasTestInteractions error: $e');
      return false;
    }
  }

  /// Creates demo profiles in Firestore so the swipe deck can be tested.
  /// Intended for development only; documents are flagged with `isDemo: true`.
  /// A few of them also like the current user so matches can be tested, and
  /// the first [matchesWithChats] get a mutual match + chat with seeded
  /// messages (chat list and match overlay work out of the box).
  /// Returns the number of profiles created.
  Future<int> seedDemoProfiles(
      {int count = 12,
      int likesToCurrentUser = 4,
      int matchesWithChats = 2}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Debes iniciar sesión para crear perfiles de prueba');
    }

    // Prefer the backend seed: the Admin SDK bypasses Firestore rules,
    // so it can create incoming likes, matches and two-way messages the
    // client is not allowed to write. Falls back to local seeding.
    try {
      final token = await currentUser.getIdToken();
      if (token != null) {
        final api = ApiService();
        api.setAuthToken(token);
        try {
          final res = await api.post('/users/me/seed-demo');
          final created = (res.data?['profiles'] as num?)?.toInt();
          if (created != null && created > 0) {
            debugPrint('Demo seed via backend: ${res.data}');
            return created;
          }
        } finally {
          api.clearAuthToken();
        }
      }
    } catch (e) {
      debugPrint('Backend seed unavailable, using local seed: $e');
    }

    final meDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
    final me = meDoc.data() ?? <String, dynamic>{};

    // Purge stale demo data first: older seeds left profiles without
    // geohash/coherent photos plus orphan matches/chats. Deleting them
    // keeps the deck clean on every reseed.
    await _purgeMyDemoData(currentUser.uid);

    // getPotentialMatches() returns [] when preferences are missing —
    // patch them in so the deck works on half-migrated accounts.
    var me2 = me;
    if (me['preferences'] is! Map<String, dynamic>) {
      await _firestore.collection('users').doc(currentUser.uid).set({
        'preferences': {
          'ageRange': [18, 40],
          'gender': 'all',
          'budget': 650.0,
          'maxDistance': 50,
          'location': const GeoPoint(40.4168, -3.7038), // Madrid
        },
      }, SetOptions(merge: true));
      me2 = (await _firestore.collection('users').doc(currentUser.uid).get())
              .data() ??
          me;
    }

    final myPrefs = me2['preferences'] as Map<String, dynamic>? ?? {};
    final myProfile = me['profile'] as Map<String, dynamic>? ?? {};
    final myType = me['userType'] as String? ?? 'tenant';
    final myInterests =
        (myProfile['interests'] as List?)?.whereType<String>().toList() ?? [];
    final myAgeRange =
        (myPrefs['ageRange'] as List?)?.whereType<num>().toList() ?? [18, 40];
    final myLocation = myPrefs['location'] as GeoPoint?;
    final myBudget = (myPrefs['budget'] as num?)?.toDouble() ?? 650.0;

    // Candidates must have a different userType, otherwise they are filtered out
    final candidateType = myType == 'landlord' ? 'tenant' : 'landlord';

    const names = [
      'Lucía',
      'Marcos',
      'Sofía',
      'Daniel',
      'Valeria',
      'Pablo',
      'Carmen',
      'Alejandro',
      'Elena',
      'Hugo',
      'Marta',
      'Adrián',
    ];
    const bios = [
      'Estudiante de arquitectura, tranquila y ordenada. Busco un ambiente respetuoso en casa.',
      'Trabajo en tecnología, teletrabajo la mayoría de días. Me gusta cocinar y el cine.',
      'Deportista, madrugadora y muy limpia. Busco compañeros con buen rollo.',
      'Recién llegado a la ciudad por trabajo. Sociable pero respeto los espacios comunes.',
      'Me encanta el yoga, las plantas y los planes de domingo. Casa tranquila.',
      'Fotógrafo freelance. Paso mucho tiempo fuera, busco un piso céntrico.',
      'Doctoranda en biología. Busco convivencia tranquila y compañeros responsables.',
      'Amante de los animales y la música. Busco piso con buen ambiente.',
      'Cocinero de profesión, la cocina siempre huele bien. Busco compañeros abiertos.',
      'Estudio diseño, me gusta el arte y salir a exposiciones. Ordenada y puntual.',
      'Teletrabajo en marketing. Busco piso luminoso y compañeros comunicativos.',
      'Ciclista y senderista los fines de semana. Casa organizada y sin dramas.',
    ];
    const interestPool = [
      'Música',
      'Cine',
      'Deporte',
      'Viajes',
      'Cocinar',
      'Lectura',
      'Senderismo',
      'Fotografía',
      'Videojuegos',
      'Yoga',
      'Mascotas',
      'Arte',
    ];

    // Gender-matched portraits (names alternate female/male by index) and
    // real apartment interiors — pravatar/picsum returned random subjects.
    const femalePortraits = [
      'photo-1494790108377-be9c29b29330',
      'photo-1438761681033-6461ffad8d80',
      'photo-1544005313-94ddf0286df2',
      'photo-1517841905240-472988babdf9',
      'photo-1531123897727-8f129e1688ce',
      'photo-1489424731084-a5d8b219a5bb',
    ];
    const malePortraits = [
      'photo-1507003211169-0a1dd7228f2d',
      'photo-1500648767791-00dcc994a43e',
      'photo-1472099645785-5658abf4ff4e',
      'photo-1506794778202-cad84cf45f1d',
      'photo-1560250097-0b93528c311a',
      'photo-1519085360753-af0119f7cbe7',
    ];
    const apartmentInteriors = [
      'photo-1522708323590-d24dbb6b0267',
      'photo-1502672260266-1c1ef2d93688',
      'photo-1560448204-e02f11c3d0e2',
      'photo-1493809842364-78817add7ffb',
      'photo-1554995207-c18c203602cb',
      'photo-1484154218962-a197022b5858',
    ];
    String img(String id) =>
        'https://images.unsplash.com/$id?auto=format&fit=crop&w=800&q=80';

    final random = Random();
    final now = DateTime.now();
    final batch = _firestore.batch();
    final createdIds = <String>[];

    final ageMin = myAgeRange.isNotEmpty ? myAgeRange[0].toInt() : 18;
    final ageMax = myAgeRange.length > 1 ? myAgeRange[1].toInt() : 40;
    final ageSpan = (ageMax - ageMin).clamp(1, 40);

    for (var i = 0; i < count; i++) {
      final docRef = _firestore.collection('profiles').doc();
      createdIds.add(docRef.id);

      final name = names[i % names.length];
      final gender = i.isEven ? 'female' : 'male';
      final age = ageMin + random.nextInt(ageSpan);

      // Shared interests with the current user to raise compatibility
      final interests = <String>{
        ...myInterests.take(2),
        interestPool[random.nextInt(interestPool.length)],
        interestPool[random.nextInt(interestPool.length)],
      }.toList();

      // Location near the current user (or Madrid center as fallback)
      final baseLat = myLocation?.latitude ?? 40.4168;
      final baseLon = myLocation?.longitude ?? -3.7038;
      final location = GeoPoint(
        baseLat + (random.nextDouble() - 0.5) * 0.04,
        baseLon + (random.nextDouble() - 0.5) * 0.04,
      );

      // Budget within the tolerance band of the current user
      final budget = myBudget * (0.95 + random.nextDouble() * 0.1);

      final portraits = gender == 'female' ? femalePortraits : malePortraits;
      // i~/2 gives a unique index per gender so no two seeded names
      // share the same face.
      final portraitIdx = i ~/ 2;
      final personalPhotos = <String>[
        img(portraits[portraitIdx % portraits.length]),
        img(portraits[(portraitIdx + 3) % portraits.length]),
      ];

      final data = <String, dynamic>{
        'uid': docRef.id,
        'name': name,
        'userType': candidateType,
        'photoURL': personalPhotos.first,
        'birthDate':
            Timestamp.fromDate(DateTime(now.year - age, 1 + (i % 12), 15)),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isPremium': false,
        'isVerified': false,
        'isDemo': true,
        'banned': false,
        // Seed format version — the deck reseeds automatically when it
        // finds demo profiles from older schema/photo formats.
        'seedVersion': demoSeedVersion,
        // Coarse geohash so the bounded geoquery finds demo profiles
        'geohash': GeoHash.encode(
          (location.latitude * 100).round() / 100,
          (location.longitude * 100).round() / 100,
        ),
        'profile': {
          'age': age,
          'bio': bios[i % bios.length],
          'gender': gender,
          'interests': interests,
          'photos': personalPhotos,
        },
        'preferences': {
          'ageRange': [18, 99],
          'gender': 'all',
          'budget': budget,
          'maxDistance': 100,
          'location': location,
        },
      };

      if (candidateType == 'landlord') {
        data['apartment'] = {
          'title': 'Habitación luminosa en piso compartido',
          'location': 'Zona centro',
          'price': budget,
          'description':
              'Habitación exterior con escritorio, gastos incluidos.',
          'photos': <String>[
            img(apartmentInteriors[i % apartmentInteriors.length]),
            img(apartmentInteriors[(i + 2) % apartmentInteriors.length]),
          ],
        };
      }

      batch.set(docRef, data);
    }

    await batch.commit();

    // Some demo users already like the current user so a match can be tested.
    // Done in a separate commit so profile creation still succeeds if this fails.
    try {
      final likesBatch = _firestore.batch();
      for (var i = 0; i < likesToCurrentUser && i < createdIds.length; i++) {
        likesBatch.set(
            _firestore
                .collection('swipes')
                .doc('${createdIds[i]}_${currentUser.uid}'),
            {
              'swiperId': createdIds[i],
              'swipedId': currentUser.uid,
              'isLike': true,
              'isDemo': true,
              'timestamp': FieldValue.serverTimestamp(),
            });
      }
      await likesBatch.commit();

      // Surface a clear error when the deployed rules still reject
      // demo->user likes (old rules weren't published). Without this
      // check failures were silent and testing looked broken.
      final probe = await _firestore
          .collection('swipes')
          .doc('${createdIds[0]}_${currentUser.uid}')
          .get();
      if (!probe.exists) {
        throw Exception(
            'Las reglas de Firestore desplegadas no permiten likes demo. Publica database/firestore.rules en Firebase Console → Firestore → Reglas.');
      }
    } catch (e) {
      debugPrint('No se pudieron crear los likes demo: $e');
      rethrow;
    }

    // Mutual matches + chats with seeded messages so every feature
    // (match overlay, chat list, conversation) can be tested on a fresh
    // launch without manual swiping.
    try {
      final meUid = currentUser.uid;
      final matchCount = matchesWithChats
          .clamp(0, likesToCurrentUser)
          .clamp(0, createdIds.length);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      for (var i = 0; i < matchCount; i++) {
        final demoId = createdIds[i];
        final name = names[i % names.length];
        final id = meUid.compareTo(demoId) < 0
            ? '${meUid}_$demoId'
            : '${demoId}_$meUid';

        // Mutual like: rules require the demo->me swipe to exist already.
        await _firestore.collection('swipes').doc('${meUid}_$demoId').set({
          'swiperId': meUid,
          'swipedId': demoId,
          'isLike': true,
          'isDemo': true,
          'timestamp': FieldValue.serverTimestamp(),
        });

        final lastMsg =
            '¡Hola! Soy $name, me alegra que hayamos hecho match 😊';
        final lastTs =
            Timestamp.fromMillisecondsSinceEpoch(nowMs - i * 3600000);

        final pairBatch = _firestore.batch();
        pairBatch.set(_firestore.collection('matches').doc(id), {
          'users': [meUid, demoId],
          'timestamp': FieldValue.serverTimestamp(),
          'lastMessage': lastMsg,
          'lastMessageTimestamp': lastTs,
          'unreadCount': {meUid: 1, demoId: 0},
        });
        pairBatch.set(_firestore.collection('chats').doc(id), {
          'participants': [meUid, demoId],
          'lastMessage': lastMsg,
          'lastMessageTimestamp': lastTs,
          'lastMessageSender': demoId,
          'createdAt': FieldValue.serverTimestamp(),
          'unreadCounts': {meUid: 1, demoId: 0},
        });
        await pairBatch.commit();

        // Rules only allow senderId == current user, so the seeded
        // conversation shows my side; the chat doc still renders an
        // incoming lastMessage preview + unread badge in the list.
        final messages = [
          '¡Hola $name! Encantado de hacer match',
          'Tu perfil me llamó mucho la atención',
          '¿Qué zona te interesa para vivir?',
        ];
        final msgBatch = _firestore.batch();
        for (var j = 0; j < messages.length; j++) {
          msgBatch.set(
            _firestore.collection('chats').doc(id).collection('messages').doc(),
            {
              'senderId': meUid,
              'receiverId': demoId,
              'message': messages[j],
              'imageUrl': null,
              'timestamp': Timestamp.fromMillisecondsSinceEpoch(
                  nowMs - i * 3600000 - (messages.length - j) * 60000),
              'read': true,
            },
          );
        }
        await msgBatch.commit();
      }
    } catch (e) {
      debugPrint('No se pudieron crear matches/chats demo: $e');
    }

    return createdIds.length;
  }

  /// Deletes demo profiles and this user's swipes/matches/chats involving
  /// them. Rules allow deleting isDemo profiles and own matches/chats;
  /// demo->me swipe docs can't be deleted client-side (harmless orphans).
  Future<void> _purgeMyDemoData(String uid) async {
    try {
      final demoSnapshot = await _firestore
          .collection('profiles')
          .where('isDemo', isEqualTo: true)
          .get();
      if (demoSnapshot.docs.isEmpty) return;
      final demoIds = demoSnapshot.docs.map((d) => d.id).toSet();

      final deleteBatch = _firestore.batch();
      for (final doc in demoSnapshot.docs) {
        deleteBatch.delete(doc.reference);
      }

      final mySwipes = await _firestore
          .collection('swipes')
          .where('swiperId', isEqualTo: uid)
          .get();
      for (final doc in mySwipes.docs) {
        if (demoIds.contains(doc.data()['swipedId'])) {
          deleteBatch.delete(doc.reference);
        }
      }

      final myMatches = await _firestore
          .collection('matches')
          .where('users', arrayContains: uid)
          .get();
      for (final doc in myMatches.docs) {
        final users = (doc.data()['users'] as List?) ?? [];
        if (users.any((u) => demoIds.contains(u))) {
          deleteBatch.delete(doc.reference);
          deleteBatch.delete(_firestore.collection('chats').doc(doc.id));
        }
      }

      await deleteBatch.commit();
      debugPrint('Demo data purged: ${demoIds.length} profiles');
    } catch (e) {
      debugPrint('Demo purge failed (non-fatal): $e');
    }
  }

  /// Removes all demo profiles previously created with [seedDemoProfiles].
  Future<int> removeDemoProfiles() async {
    final snapshot = await _firestore
        .collection('profiles')
        .where('isDemo', isEqualTo: true)
        .get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    return snapshot.docs.length;
  }
}
