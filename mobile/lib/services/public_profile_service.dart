import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/geohash.dart';

/// Keeps the public `profiles/{uid}` document in sync with the private
/// `users/{uid}` document.
///
/// The `users` collection is owner-only (it contains email, birthDate, exact
/// location, verification data…). Everything other users may see is published
/// here — only non-sensitive display fields — and the location is rounded to
/// ~1 km so exact coordinates are never exposed.
class PublicProfileService {
  PublicProfileService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fields from the user doc that are safe to show to other users.
  static const _topLevelPublicKeys = [
    'name',
    'userType',
    'photoURL',
    'photos',
    'age',
    'bio',
    'profession',
    'gender',
    'interests',
    'badges',
    'isVerified',
    'isDemo',
    'banned',
    'isBoosted',
    'boostEndTime',
    'isOnline',
    'lastActive',
    'isListingHighlighted',
    'profile',
    'apartment',
    'createdAt',
  ];

  /// Preference keys used by matching/display that are not sensitive.
  static const _publicPreferenceKeys = [
    'ageRange',
    'gender',
    'maxDistance',
    'budget',
    'budgetMin',
    'budgetMax',
    'moveInDate',
    'locationEnabled',
  ];

  /// Rounds a GeoPoint to 2 decimals (~1.1 km) for privacy.
  static GeoPoint _coarse(GeoPoint p) => GeoPoint(
        (p.latitude * 100).round() / 100,
        (p.longitude * 100).round() / 100,
      );

  /// Reads `users/{uid}` and writes the public subset to `profiles/{uid}`.
  /// Best-effort: never throws so callers can fire-and-forget.
  static Future<void> sync([String? uid]) async {
    final target = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (target == null) return;

    try {
      final doc = await _firestore.collection('users').doc(target).get();
      if (!doc.exists) return;
      final data = doc.data()!;

      final public = <String, dynamic>{'uid': target};
      for (final key in _topLevelPublicKeys) {
        if (data.containsKey(key)) public[key] = data[key];
      }

      // Sanitise preferences: whitelist keys + coarse location only.
      final rawPrefs = data['preferences'];
      if (rawPrefs is Map) {
        final prefs = <String, dynamic>{};
        for (final key in _publicPreferenceKeys) {
          if (rawPrefs.containsKey(key)) prefs[key] = rawPrefs[key];
        }
        final loc = rawPrefs['location'];
        if (loc is GeoPoint) {
          prefs['location'] = _coarse(loc);
          // Coarse geohash for bounded geoqueries (~1km precision)
          public['geohash'] = GeoHash.encode(
            (loc.latitude * 100).round() / 100,
            (loc.longitude * 100).round() / 100,
          );
        }
        public['preferences'] = prefs;
      }

      public['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('profiles')
          .doc(target)
          .set(public, SetOptions(merge: true));
    } catch (e) {
      debugPrint('PublicProfileService.sync error: $e');
    }
  }

  /// Removes the public profile (account deletion).
  static Future<void> remove(String uid) async {
    try {
      await _firestore.collection('profiles').doc(uid).delete();
    } catch (e) {
      debugPrint('PublicProfileService.remove error: $e');
    }
  }
}
