import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/premium_plan.dart';
import 'auth_service.dart';

/// Service to manage user limits and track daily usage
class LimitsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Get current user's subscription
  Future<UserSubscription?> getUserSubscription() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        // Create basic subscription if not exists
        final basicSub = UserSubscription(
          userId: user.uid,
          planId: 'basic',
          isActive: true,
        );
        await _firestore
            .collection('subscriptions')
            .doc(user.uid)
            .set(basicSub.toMap());
        return basicSub;
      }

      return UserSubscription.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting user subscription: $e');
      return null;
    }
  }

  /// Get user limits based on subscription
  Future<UserLimits> getUserLimits() async {
    final subscription = await getUserSubscription();
    return subscription?.limits ?? UserLimits.basic;
  }

  /// Check if user can swipe today
  Future<bool> canSwipe() async {
    final limits = await getUserLimits();
    if (limits.dailySwipes == -1) return true; // Unlimited

    final todaySwipes = await getTodaySwipes();
    return todaySwipes < limits.dailySwipes;
  }

  /// Get number of swipes done today
  Future<int> getTodaySwipes() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return 0;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('swipes')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting today swipes: $e');
      return 0;
    }
  }

  /// Record a swipe
  Future<void> recordSwipe({required bool isLike}) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('swipes')
          .add({
        'isLike': isLike,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error recording swipe: $e');
    }
  }

  /// Check if user can create more listings
  Future<bool> canCreateListing() async {
    final limits = await getUserLimits();
    if (limits.activeListings == -1) return true; // Unlimited

    final activeListings = await getActiveListingsCount();
    return activeListings < limits.activeListings;
  }

  /// Get number of active listings
  Future<int> getActiveListingsCount() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('listings')
          .where('userId', isEqualTo: user.uid)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting active listings: $e');
      return 0;
    }
  }

  /// Check if user can use boost
  Future<bool> canUseBoost() async {
    final limits = await getUserLimits();
    if (limits.weeklyBoosts == 0) return false;

    final usedBoosts = await getWeeklyBoosts();
    return usedBoosts < limits.weeklyBoosts;
  }

  /// Get number of boosts used this week
  Future<int> getWeeklyBoosts() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return 0;

      final now = DateTime.now();
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day - (now.weekday - 1),
      );

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('boosts')
          .where('timestamp', isGreaterThanOrEqualTo: startOfWeek)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting weekly boosts: $e');
      return 0;
    }
  }

  /// Record a boost usage
  Future<void> recordBoost({required int durationMinutes}) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('boosts')
          .add({
        'durationMinutes': durationMinutes,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update user document to set boost end time
      final boostEndTime = DateTime.now().add(Duration(minutes: durationMinutes));
      await _firestore.collection('users').doc(user.uid).update({
        'boostEndTime': Timestamp.fromDate(boostEndTime),
        'isBoosted': true,
      });
    } catch (e) {
      debugPrint('Error recording boost: $e');
    }
  }

  /// Check if user is currently boosted
  Future<bool> isUserBoosted() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final isBoosted = data['isBoosted'] as bool? ?? false;
      final boostEndTime = data['boostEndTime'] as Timestamp?;

      if (!isBoosted || boostEndTime == null) return false;

      return boostEndTime.toDate().isAfter(DateTime.now());
    } catch (e) {
      debugPrint('Error checking if user is boosted: $e');
      return false;
    }
  }

  /// Check if user has access to advanced filters
  Future<bool> hasAdvancedFilters() async {
    final limits = await getUserLimits();
    return limits.advancedFilters;
  }

  /// Check if user can see who liked them
  Future<bool> canSeeWhoLikedYou() async {
    final limits = await getUserLimits();
    return limits.seeWhoLikedYou;
  }

  /// Check if user can undo swipe
  Future<bool> canUndoSwipe() async {
    final limits = await getUserLimits();
    return limits.undoSwipe;
  }

  /// Check if user has priority recommendations
  Future<bool> hasPriorityRecommendations() async {
    final limits = await getUserLimits();
    return limits.priorityRecommendations;
  }

  /// Check if user has premium badge
  Future<bool> hasPremiumBadge() async {
    final limits = await getUserLimits();
    return limits.premiumBadge;
  }

  /// Check if user has no ads
  Future<bool> hasNoAds() async {
    final limits = await getUserLimits();
    return limits.noAds;
  }

  /// Check if user has full statistics
  Future<bool> hasFullStatistics() async {
    final limits = await getUserLimits();
    return limits.fullStatistics;
  }

  /// Check if user has priority support
  Future<bool> hasPrioritySupport() async {
    final limits = await getUserLimits();
    return limits.prioritySupport;
  }

  /// Upgrade user to premium
  Future<void> upgradeToPremium({
    required String stripeSubscriptionId,
    required String stripeCustomerId,
    required DateTime endDate,
  }) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final subscription = UserSubscription(
        userId: user.uid,
        planId: 'premium',
        startDate: DateTime.now(),
        endDate: endDate,
        isActive: true,
        stripeSubscriptionId: stripeSubscriptionId,
        stripeCustomerId: stripeCustomerId,
      );

      await _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .set(subscription.toMap());

      // Update user document
      await _firestore.collection('users').doc(user.uid).update({
        'planId': 'premium',
        'isPremium': true,
      });
    } catch (e) {
      debugPrint('Error upgrading to premium: $e');
      rethrow;
    }
  }

  /// Downgrade user to basic
  Future<void> downgradeToBasic() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final subscription = UserSubscription(
        userId: user.uid,
        planId: 'basic',
        isActive: true,
      );

      await _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .set(subscription.toMap());

      // Update user document
      await _firestore.collection('users').doc(user.uid).update({
        'planId': 'basic',
        'isPremium': false,
      });
    } catch (e) {
      debugPrint('Error downgrading to basic: $e');
      rethrow;
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final subscription = await getUserSubscription();
      if (subscription == null) return;

      // Keep subscription active until end date
      await _firestore
          .collection('subscriptions')
          .doc(user.uid)
          .update({
        'isActive': false,
        'cancelAtPeriodEnd': true,
      });
    } catch (e) {
      debugPrint('Error canceling subscription: $e');
      rethrow;
    }
  }
}
