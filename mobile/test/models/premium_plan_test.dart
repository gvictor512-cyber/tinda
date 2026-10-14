import 'package:flutter_test/flutter_test.dart';
import 'package:roommatematch/models/premium_plan.dart';

void main() {
  group('UserLimits', () {
    test('basic plan has restrictive limits', () {
      final limits = UserLimits.fromPlan('basic');
      expect(limits.dailySwipes, 15);
      expect(limits.activeListings, 1);
      expect(limits.seeWhoLikedYou, false);
      expect(limits.undoSwipe, false);
    });

    test('premium plan unlocks all features', () {
      final limits = UserLimits.fromPlan('premium');
      expect(limits.dailySwipes, -1);
      expect(limits.activeListings, 10);
      expect(limits.seeWhoLikedYou, true);
      expect(limits.undoSwipe, true);
      expect(limits.noAds, true);
    });

    test('unknown plans fall back to basic limits', () {
      final limits = UserLimits.fromPlan('gold');
      expect(limits.dailySwipes, 15);
      expect(limits.seeWhoLikedYou, false);
    });
  });

  group('UserSubscription', () {
    test('round-trips through toMap/fromMap', () {
      final sub = UserSubscription(
        userId: 'u1',
        planId: 'premium',
        startDate: DateTime.fromMillisecondsSinceEpoch(1000),
        endDate: DateTime.fromMillisecondsSinceEpoch(2000),
        isActive: true,
        stripeSubscriptionId: 'sub_123',
        stripeCustomerId: 'cus_123',
      );

      final restored = UserSubscription.fromMap(sub.toMap());

      expect(restored.userId, 'u1');
      expect(restored.planId, 'premium');
      expect(restored.isActive, true);
      expect(restored.stripeSubscriptionId, 'sub_123');
      expect(restored.endDate!.millisecondsSinceEpoch, 2000);
    });

    test('isPremium is false for expired subscriptions', () {
      final sub = UserSubscription(
        userId: 'u1',
        planId: 'premium',
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        isActive: true,
      );

      expect(sub.isExpired, true);
      expect(sub.isPremium, false);
      expect(sub.isBasic, true);
    });

    test('isPremium is true for active non-expired premium subs', () {
      final sub = UserSubscription(
        userId: 'u1',
        planId: 'premium',
        endDate: DateTime.now().add(const Duration(days: 10)),
        isActive: true,
      );

      expect(sub.isPremium, true);
    });

    test('isPremium is false when flagged inactive even without expiry', () {
      final sub = UserSubscription(
        userId: 'u1',
        planId: 'premium',
        isActive: false,
      );

      expect(sub.isPremium, false);
    });
  });
}
