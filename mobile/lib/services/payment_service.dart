import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/premium_plan.dart';
import 'analytics_service.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnalyticsService _analytics = AnalyticsService();

  // Subscription plans (using PremiumPlan model)
  static final Map<String, PremiumPlan> subscriptionPlans = {
    'premium_monthly': PremiumPlan(
      id: 'premium_monthly',
      name: 'Premium Mensual',
      monthlyPrice: 9.99,
      yearlyPrice: 9.99,
      features: [
        'Matches ilimitados',
        'Filtros avanzados',
        'Ver quién te dio like',
        'Boost de perfil',
        'Undo swipe ilimitado',
        'Soporte prioritario',
      ],
      description: 'Acceso premium por 30 días',
    ),
    'premium_annual': PremiumPlan(
      id: 'premium_annual',
      name: 'Premium Anual',
      monthlyPrice: 79.99,
      yearlyPrice: 79.99,
      features: [
        'Matches ilimitados',
        'Filtros avanzados',
        'Ver quién te dio like',
        'Boost de perfil',
        'Undo swipe ilimitado',
        'Soporte prioritario',
        'Ahorra 33% vs mensual',
      ],
      description: 'Acceso premium por 365 días',
    ),
  };

  // Individual purchases (extras)
  static const Map<String, Map<String, dynamic>> individualPurchases = {
    'boost': {
      'id': 'boost',
      'name': 'Boost',
      'description': 'Aparece primero durante 30 minutos',
      'price': 1.99,
      'currency': 'EUR',
    },
    'super_like': {
      'id': 'super_like',
      'name': 'Super Like',
      'description': 'Notificación especial al otro usuario',
      'price': 0.99,
      'currency': 'EUR',
    },
    'premium_verification': {
      'id': 'premium_verification',
      'name': 'Verificación Premium',
      'description': 'Revisión manual y sello de confianza',
      'price': 2.99,
      'currency': 'EUR',
    },
    'highlight_listing': {
      'id': 'highlight_listing',
      'name': 'Destacar anuncio',
      'description': 'Tu anuncio destacado 24 horas',
      'price': 3.99,
      'currency': 'EUR',
    },
  };

  // Free trial duration
  static const int FREE_TRIAL_DAYS = 7;

  // Default currency
  static const String DEFAULT_CURRENCY = 'EUR';

  /// Check if the current user has an active subscription
  /// Returns true if subscription exists and hasn't expired
  /// Returns false if no subscription or expired
  Future<bool> hasActiveSubscription() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();

      if (userData == null) return false;

      final subscription = userData['subscription'] as Map<String, dynamic>?;
      if (subscription == null) return false;

      final endDate = (subscription['endDate'] as Timestamp?)?.toDate();
      if (endDate == null) return false;

      return DateTime.now().isBefore(endDate);
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      return false;
    }
  }

  /// Get the current user's subscription details
  /// Returns null if no subscription exists
  /// Returns subscription data including plan, dates, and status
  Future<Map<String, dynamic>?> getSubscriptionDetails() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();

      return userData?['subscription'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting subscription details: $e');
      return null;
    }
  }

  // Get subscription plan
  PremiumPlan? getSubscriptionPlan(String planId) {
    return subscriptionPlans[planId];
  }

  // Get all subscription plans
  Map<String, PremiumPlan> getAllSubscriptionPlans() {
    return subscriptionPlans;
  }

  /// Purchase a subscription plan
  /// In production, this would integrate with in-app purchase (Stripe/Apple/Google)
  /// Currently simulates a successful purchase
  /// Returns true if purchase succeeds
  /// Throws Exception if purchase fails
  Future<bool> purchaseSubscription(String planId, {String? transactionId}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final plan = subscriptionPlans[planId];
    if (plan == null) throw Exception('Invalid plan ID');

    try {
      // In production, this would integrate with actual in-app purchase
      // For now, we'll simulate a successful purchase
      
      final startDate = DateTime.now();
      final duration = planId == 'premium_annual' ? 365 : 30;
      final endDate = startDate.add(Duration(days: duration));

      // Create subscription record
      final subscription = UserSubscription(
        userId: currentUser.uid,
        planId: 'premium',
        startDate: startDate,
        endDate: endDate,
        isActive: true,
      );

      await _firestore
          .collection('subscriptions')
          .doc(currentUser.uid)
          .set(subscription.toMap());

      // Update user document
      await _firestore.collection('users').doc(currentUser.uid).update({
        'planId': 'premium',
        'isPremium': true,
        'subscription': {
          'planId': planId,
          'planName': plan.name,
          'startDate': Timestamp.fromDate(startDate),
          'endDate': Timestamp.fromDate(endDate),
          'price': plan.monthlyPrice,
          'currency': 'EUR',
          'autoRenew': true,
          'status': 'active',
        },
      });

      // Save subscription status locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', true);
      await prefs.setString('subscription_plan', planId);
      await prefs.setString('subscription_end_date', endDate.toIso8601String());

      final txId = transactionId ?? 'simulated_${DateTime.now().millisecondsSinceEpoch}';

      // Record purchase
      await recordPurchase(
        planId: planId,
        amount: plan.monthlyPrice,
        currency: 'EUR',
        transactionId: txId,
      );

      // Track subscription purchase in analytics
      await _analytics.logSubscriptionPurchase(
        planId: planId,
        price: plan.monthlyPrice,
        currency: 'EUR',
        transactionId: txId,
        isRenewal: false,
      );

      return true;
    } catch (e) {
      debugPrint('Failed to purchase subscription: $e');
      rethrow;
    }
  }

  /// Cancel the current subscription
  /// Sets auto-renew to false and updates status to cancelled
  /// In production, this would cancel with the app store
  /// Returns true if cancellation succeeds
  /// Throws Exception if cancellation fails
  Future<bool> cancelSubscription() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final subscription = await getSubscriptionDetails();
      if (subscription == null) throw Exception('No active subscription');

      // In production, this would cancel the subscription in the app store
      // For now, we'll just set autoRenew to false
      
      await _firestore.collection('users').doc(currentUser.uid).update({
        'subscription.autoRenew': false,
        'subscription.status': 'cancelled',
      });

      // Update local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_renew', false);

      // Track subscription cancellation in analytics
      final subDetails = await getSubscriptionDetails();
      if (subDetails != null) {
        await _analytics.logSubscriptionCancel(
          planId: subDetails['planId'] as String? ?? 'unknown',
        );
      }

      return true;
    } catch (e) {
      debugPrint('Failed to cancel subscription: $e');
      rethrow;
    }
  }

  /// Restore a subscription from app store purchase
  /// Verifies subscription status with Firestore
  /// Returns true if active subscription found
  /// Throws Exception if restoration fails
  Future<bool> restoreSubscription() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // In production, this would verify subscription with app store
      // For now, we'll check Firestore
      
      final subscription = await getSubscriptionDetails();
      if (subscription == null) return false;

      final endDate = (subscription['endDate'] as Timestamp?)?.toDate();
      if (endDate == null) return false;

      final isActive = DateTime.now().isBefore(endDate);
      
      if (isActive) {
        // Update local preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_premium', true);
        await prefs.setString('subscription_plan', subscription['planId'] as String);
        await prefs.setString('subscription_end_date', endDate.toIso8601String());
        
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Failed to restore subscription: $e');
      rethrow;
    }
  }

  // Check if user can use premium feature
  Future<bool> canUsePremiumFeature(String feature) async {
    final hasSubscription = await hasActiveSubscription();
    if (!hasSubscription) return false;

    // Check specific feature availability
    final subscription = await getSubscriptionDetails();
    if (subscription == null) return false;

    final planId = subscription['planId'] as String;
    final plan = subscriptionPlans[planId];
    
    if (plan == null) return false;

    return plan.features.contains(feature);
  }

  // Get subscription status text
  Future<String> getSubscriptionStatusText() async {
    final hasSubscription = await hasActiveSubscription();
    
    if (!hasSubscription) {
      return 'Gratis';
    }

    final subscription = await getSubscriptionDetails();
    if (subscription == null) return 'Gratis';

    final endDate = (subscription['endDate'] as Timestamp?)?.toDate();
    if (endDate == null) return 'Gratis';

    final daysRemaining = endDate.difference(DateTime.now()).inDays;
    
    if (daysRemaining <= 0) {
      return 'Expirado';
    } else if (daysRemaining == 1) {
      return '1 día restante';
    } else {
      return '$daysRemaining días restantes';
    }
  }

  // Get days remaining in subscription
  Future<int> getDaysRemaining() async {
    final subscription = await getSubscriptionDetails();
    if (subscription == null) return 0;

    final endDate = (subscription['endDate'] as Timestamp?)?.toDate();
    if (endDate == null) return 0;

    final daysRemaining = endDate.difference(DateTime.now()).inDays;
    return daysRemaining > 0 ? daysRemaining : 0;
  }

  /// Start a free trial for new users
  /// Checks if user has already used free trial
  /// Creates 7-day trial subscription
  /// Returns true if trial starts successfully
  /// Throws Exception if trial cannot be started
  Future<bool> startFreeTrial() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Check if user already used free trial
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      
      if (userData?['hasUsedFreeTrial'] == true) {
        throw Exception('Free trial already used');
      }

      // Start free trial
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: FREE_TRIAL_DAYS));

      await _firestore.collection('users').doc(currentUser.uid).update({
        'subscription': {
          'planId': 'free_trial',
          'planName': 'Prueba Gratis',
          'startDate': Timestamp.fromDate(startDate),
          'endDate': Timestamp.fromDate(endDate),
          'price': 0,
          'currency': DEFAULT_CURRENCY,
          'autoRenew': false,
          'status': 'trial',
        },
        'isPremium': true,
        'hasUsedFreeTrial': true,
      });

      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', true);
      await prefs.setBool('has_used_free_trial', true);
      await prefs.setString('subscription_end_date', endDate.toIso8601String());

      return true;
    } catch (e) {
      debugPrint('Failed to start free trial: $e');
      rethrow;
    }
  }

  /// Check if the user is eligible for a free trial
  /// Returns true if user hasn't used trial and has no active subscription
  /// Returns false otherwise
  Future<bool> canStartFreeTrial() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();

      final hasUsedFreeTrial = userData?['hasUsedFreeTrial'] ?? false;
      final hasActiveSubscription = await this.hasActiveSubscription();

      return !hasUsedFreeTrial && !hasActiveSubscription;
    } catch (e) {
      debugPrint('Error checking free trial eligibility: $e');
      return false;
    }
  }

  /// Get the user's purchase history
  /// Returns list of all purchases ordered by timestamp (descending)
  /// Throws Exception if fetch fails
  Future<List<Map<String, dynamic>>> getPurchaseHistory() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final purchasesSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('purchases')
          .orderBy('timestamp', descending: true)
          .get();

      return purchasesSnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting purchase history: $e');
      rethrow;
    }
  }

  /// Record a purchase in Firestore
  /// Stores purchase details for history and analytics
  /// Throws Exception if recording fails
  Future<void> recordPurchase({
    required String planId,
    required double amount,
    required String currency,
    required String transactionId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('purchases')
          .add({
        'planId': planId,
        'amount': amount,
        'currency': currency,
        'transactionId': transactionId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error recording purchase: $e');
      rethrow;
    }
  }

  // Get pricing for display
  String formatPrice(double price, String currency) {
    return '$price $currency';
  }

  /// Purchase an individual item (Boost, Super Like, etc.)
  /// In production, this would integrate with in-app purchase
  /// Currently simulates a successful purchase
  /// Returns true if purchase succeeds
  /// Throws Exception if purchase fails
  Future<bool> purchaseIndividualItem(String itemId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final item = individualPurchases[itemId];
    if (item == null) throw Exception('Invalid item ID');

    try {
      // In production, this would integrate with actual in-app purchase
      // For now, we'll simulate a successful purchase
      
      // Record purchase
      await recordPurchase(
        planId: itemId,
        amount: item['price'] as double,
        currency: item['currency'] as String,
        transactionId: 'simulated_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Track individual purchase in analytics
      await _analytics.logSubscriptionPurchase(
        planId: itemId,
        price: item['price'] as double,
        currency: item['currency'] as String,
        transactionId: 'simulated_${DateTime.now().millisecondsSinceEpoch}',
        isRenewal: false,
      );

      // Grant the item based on type
      switch (itemId) {
        case 'boost':
          // Boost is handled by LimitsService.recordBoost
          break;
        case 'super_like':
          // Super Like is handled by MatchingService.sendSuperLike
          break;
        case 'premium_verification':
          // Premium verification is handled by VerificationService.requestPremiumVerification
          break;
        case 'highlight_listing':
          // Highlight listing is handled by ListingService.boostListing
          break;
      }

      return true;
    } catch (e) {
      debugPrint('Failed to purchase individual item: $e');
      rethrow;
    }
  }

  /// Get individual purchase item
  Map<String, dynamic>? getIndividualPurchaseItem(String itemId) {
    return individualPurchases[itemId];
  }

  /// Get all individual purchases
  Map<String, Map<String, dynamic>> getAllIndividualPurchases() {
    return individualPurchases;
  }

  // Calculate savings for annual plan
  double calculateAnnualSavings() {
    final monthlyPrice = subscriptionPlans['premium_monthly']!.monthlyPrice;
    final annualPrice = subscriptionPlans['premium_annual']!.monthlyPrice;
    final monthlyAnnualEquivalent = monthlyPrice * 12;
    
    return monthlyAnnualEquivalent - annualPrice;
  }

  // Get savings percentage
  double getSavingsPercentage() {
    final monthlyPrice = subscriptionPlans['premium_monthly']!.monthlyPrice;
    final annualPrice = subscriptionPlans['premium_annual']!.monthlyPrice;
    final monthlyAnnualEquivalent = monthlyPrice * 12;
    
    return ((monthlyAnnualEquivalent - annualPrice) / monthlyAnnualEquivalent) * 100;
  }
}
