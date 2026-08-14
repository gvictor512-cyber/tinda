import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize analytics
  Future<void> initialize() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  // Log app open
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  // Log login
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
    await _logEvent('login', {'method': method});
  }

  // Log sign up
  Future<void> logSignUp({
    required String method,
    String? userType,
  }) async {
    await _analytics.logSignUp(signUpMethod: method);
    await _logEvent('sign_up', {
      'method': method,
      'user_type': userType,
    });
    
    // Store registration event
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('user_registrations').add({
          'userId': currentUser.uid,
          'method': method,
          'userType': userType,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Failed to store registration: $e');
      }
    }
  }

  // Log screen view
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
    await _logEvent('screen_view', {'screen_name': screenName});
  }

  // Log search
  Future<void> logSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
    await _logEvent('search', {'search_term': searchTerm});
  }

  // Log share
  Future<void> logShare(String contentType, String itemId) async {
    await _analytics.logShare(contentType: contentType, itemId: itemId, method: 'app');
    await _logEvent('share', {'content_type': contentType, 'item_id': itemId});
  }

  // Log tutorial begin
  Future<void> logTutorialBegin() async {
    await _analytics.logTutorialBegin();
    await _logEvent('tutorial_begin', {});
  }

  // Log tutorial complete
  Future<void> logTutorialComplete() async {
    await _analytics.logTutorialComplete();
    await _logEvent('tutorial_complete', {});
  }

  // Custom event logging
  Future<void> _logEvent(String name, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters.cast<String, Object>(),
    );

    // Also log to Firestore for custom analytics
    await _logToFirestore(name, parameters);
  }

  // Log to Firestore for custom analytics
  Future<void> _logToFirestore(String eventName, Map<String, dynamic> parameters) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('analytics_events').add({
        'userId': currentUser.uid,
        'eventName': eventName,
        'parameters': parameters,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'mobile',
      });
    } catch (e) {
      // Silently fail to avoid disrupting user experience
      debugPrint('Failed to log to Firestore: $e');
    }
  }

  // Log swipe action
  Future<void> logSwipe({required bool isLike, required String profileId}) async {
    await _logEvent('swipe', {
      'is_like': isLike,
      'profile_id': profileId,
    });
  }

  // Log match
  Future<void> logMatch(String matchedUserId) async {
    await _logEvent('match', {
      'matched_user_id': matchedUserId,
    });
  }

  // Log message sent
  Future<void> logMessageSent(String chatId) async {
    await _logEvent('message_sent', {
      'chat_id': chatId,
    });
  }

  // Log message received
  Future<void> logMessageReceived(String chatId) async {
    await _logEvent('message_received', {
      'chat_id': chatId,
    });
  }

  // Log profile view
  Future<void> logProfileView(String profileId) async {
    await _logEvent('profile_view', {
      'profile_id': profileId,
    });
  }

  // Log filter applied
  Future<void> logFilterApplied(Map<String, dynamic> filters) async {
    await _logEvent('filter_applied', filters);
  }

  // Log location update
  Future<void> logLocationUpdate(double latitude, double longitude) async {
    await _logEvent('location_update', {
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  // Log subscription purchase
  Future<void> logSubscriptionPurchase({
    required String planId,
    required double price,
    required String currency,
    String? transactionId,
    bool isRenewal = false,
  }) async {
    final txId = transactionId ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    await _analytics.logPurchase(
      transactionId: txId,
      value: price,
      currency: currency,
      items: [
        AnalyticsEventItem(
          itemId: planId,
          itemName: planId,
          price: price,
        ),
      ],
    );
    
    await _logEvent('subscription_purchase', {
      'plan_id': planId,
      'price': price,
      'currency': currency,
      'transaction_id': txId,
      'is_renewal': isRenewal,
      'purchase_type': isRenewal ? 'renewal' : 'new',
    });
    
    // Also store in purchases collection for detailed tracking
    await _storePurchase({
      'planId': planId,
      'price': price,
      'currency': currency,
      'transactionId': txId,
      'isRenewal': isRenewal,
    });
  }

  // Store purchase in dedicated collection
  Future<void> _storePurchase(Map<String, dynamic> purchaseData) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('purchases').add({
        'userId': currentUser.uid,
        ...purchaseData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to store purchase: $e');
    }
  }

  // Log subscription cancel
  Future<void> logSubscriptionCancel({
    required String planId,
    String? reason,
  }) async {
    await _logEvent('subscription_cancel', {
      'plan_id': planId,
      'cancellation_reason': reason,
    });
    
    // Store cancellation event
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await _firestore.collection('subscription_events').add({
          'userId': currentUser.uid,
          'eventType': 'cancellation',
          'planId': planId,
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Failed to store cancellation: $e');
      }
    }
  }

  // Log verification started
  Future<void> logVerificationStarted(String verificationType) async {
    await _logEvent('verification_started', {
      'verification_type': verificationType,
    });
  }

  // Log verification completed
  Future<void> logVerificationCompleted(String verificationType, bool success) async {
    await _logEvent('verification_completed', {
      'verification_type': verificationType,
      'success': success,
    });
  }

  // Log error
  Future<void> logError(String error, String? context) async {
    await _logEvent('error', {
      'error_message': error,
      'context': context,
    });
  }

  // Set user property
  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Set user ID
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  // Reset analytics data
  Future<void> resetAnalyticsData() async {
    await _analytics.resetAnalyticsData();
  }

  // Get analytics data
  Future<Map<String, dynamic>> getUserAnalytics() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Get user's analytics data from Firestore
      final userEventsSnapshot = await _firestore
          .collection('analytics_events')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      // Calculate basic metrics
      int totalEvents = userEventsSnapshot.docs.length;
      Map<String, int> eventCounts = {};

      for (var doc in userEventsSnapshot.docs) {
        final eventName = doc.data()['eventName'] as String?;
        if (eventName != null) {
          eventCounts[eventName] = (eventCounts[eventName] ?? 0) + 1;
        }
      }

      return {
        'total_events': totalEvents,
        'event_counts': eventCounts,
        'most_common_event': eventCounts.isNotEmpty
            ? eventCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null,
      };
    } catch (e) {
      debugPrint('Error getting user analytics: $e');
      rethrow;
    }
  }

  // Track funnel conversion
  Future<void> trackFunnelStep(String funnelName, String stepName) async {
    await _logEvent('funnel_step', {
      'funnel_name': funnelName,
      'step_name': stepName,
    });
  }

  // Common funnels
  static const String FUNNEL_ONBOARDING = 'onboarding';
  static const String FUNNEL_MATCHING = 'matching';
  static const String FUNNEL_SUBSCRIPTION = 'subscription';

  // Funnel steps
  static const String STEP_APP_OPEN = 'app_open';
  static const String STEP_SIGN_UP = 'sign_up';
  static const String STEP_PROFILE_COMPLETE = 'profile_complete';
  static const String STEP_FIRST_SWIPE = 'first_swipe';
  static const String STEP_FIRST_MATCH = 'first_match';
  static const String STEP_FIRST_MESSAGE = 'first_message';
  static const String STEP_SUBSCRIPTION_VIEW = 'subscription_view';
  static const String STEP_SUBSCRIPTION_PURCHASE = 'subscription_purchase';

  // Track retention
  Future<void> trackRetention(int daysSinceInstall) async {
    await _logEvent('retention', {
      'days_since_install': daysSinceInstall,
    });
  }

  // Track session duration
  Future<void> trackSessionDuration(Duration duration) async {
    await _logEvent('session_duration', {
      'duration_seconds': duration.inSeconds,
    });
  }

  // Track feature usage
  Future<void> trackFeatureUsage(String featureName) async {
    await _logEvent('feature_usage', {
      'feature_name': featureName,
    });
  }

  // Track crash
  Future<void> trackCrash(String error, String stackTrace) async {
    await _logEvent('crash', {
      'error': error,
      'stack_trace': stackTrace,
    });
  }

  // Track performance
  Future<void> trackPerformance(String metricName, double value) async {
    await _logEvent('performance', {
      'metric_name': metricName,
      'value': value,
    });
  }

  // Get daily active users (admin function)
  Future<int> getDailyActiveUsers() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final eventsSnapshot = await _firestore
          .collection('analytics_events')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      // Count unique users
      final uniqueUsers = eventsSnapshot.docs
          .map((doc) => doc.data()['userId'] as String?)
          .where((userId) => userId != null)
          .toSet();

      return uniqueUsers.length;
    } catch (e) {
      debugPrint('Error getting daily active users: $e');
      rethrow;
    }
  }

  // Get weekly active users (admin function)
  Future<int> getWeeklyActiveUsers() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      final eventsSnapshot = await _firestore
          .collection('analytics_events')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      final uniqueUsers = eventsSnapshot.docs
          .map((doc) => doc.data()['userId'] as String?)
          .where((userId) => userId != null)
          .toSet();

      return uniqueUsers.length;
    } catch (e) {
      debugPrint('Error getting weekly active users: $e');
      rethrow;
    }
  }

  // Get monthly active users (admin function)
  Future<int> getMonthlyActiveUsers() async {
    try {
      final now = DateTime.now();
      final monthAgo = now.subtract(const Duration(days: 30));
      
      final eventsSnapshot = await _firestore
          .collection('analytics_events')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo))
          .get();

      final uniqueUsers = eventsSnapshot.docs
          .map((doc) => doc.data()['userId'] as String?)
          .where((userId) => userId != null)
          .toSet();

      return uniqueUsers.length;
    } catch (e) {
      debugPrint('Error getting monthly active users: $e');
      rethrow;
    }
  }

  // Get event counts by type (admin function)
  Future<Map<String, int>> getEventCountsByType(DateTime startDate, DateTime endDate) async {
    try {
      final eventsSnapshot = await _firestore
          .collection('analytics_events')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      Map<String, int> eventCounts = {};

      for (var doc in eventsSnapshot.docs) {
        final eventName = doc.data()['eventName'] as String?;
        if (eventName != null) {
          eventCounts[eventName] = (eventCounts[eventName] ?? 0) + 1;
        }
      }

      return eventCounts;
    } catch (e) {
      debugPrint('Error getting event counts by type: $e');
      rethrow;
    }
  }

  // Get user retention data (admin function)
  Future<Map<String, int>> getUserRetention() async {
    // This would require more complex analysis
    // For now, return basic retention metrics
    final dailyUsers = await getDailyActiveUsers();
    final weeklyUsers = await getWeeklyActiveUsers();
    final monthlyUsers = await getMonthlyActiveUsers();

    return {
      'dau': dailyUsers,
      'wau': weeklyUsers,
      'mau': monthlyUsers,
    };
  }

  // Get registrations by date range (admin function)
  Future<List<Map<String, dynamic>>> getRegistrationsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('user_registrations')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting registrations: $e');
      rethrow;
    }
  }

  // Get purchases by date range (admin function)
  Future<List<Map<String, dynamic>>> getPurchasesByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? planId,
    bool? renewalsOnly,
  }) async {
    try {
      Query query = _firestore
          .collection('purchases')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      if (planId != null) {
        query = query.where('planId', isEqualTo: planId);
      }

      if (renewalsOnly == true) {
        query = query.where('isRenewal', isEqualTo: true);
      }

      final snapshot = await query.orderBy('timestamp', descending: true).get();

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error getting purchases: $e');
      rethrow;
    }
  }

  // Get subscription events by date range (admin function)
  Future<List<Map<String, dynamic>>> getSubscriptionEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('subscription_events')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting subscription events: $e');
      rethrow;
    }
  }

  // Get revenue by date range (admin function)
  Future<Map<String, dynamic>> getRevenueByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final purchases = await getPurchasesByDateRange(startDate, endDate);

      double totalRevenue = 0;
      int totalPurchases = 0;
      int renewals = 0;
      int newSubscriptions = 0;
      Map<String, double> revenueByPlan = {};
      Map<String, int> purchasesByPlan = {};

      for (var purchase in purchases) {
        final price = (purchase['price'] as num?)?.toDouble() ?? 0.0;
        final planId = purchase['planId'] as String? ?? 'unknown';
        final isRenewal = purchase['isRenewal'] as bool? ?? false;

        totalRevenue += price;
        totalPurchases++;

        if (isRenewal) {
          renewals++;
        } else {
          newSubscriptions++;
        }

        revenueByPlan[planId] = (revenueByPlan[planId] ?? 0) + price;
        purchasesByPlan[planId] = (purchasesByPlan[planId] ?? 0) + 1;
      }

      return {
        'total_revenue': totalRevenue,
        'total_purchases': totalPurchases,
        'renewals': renewals,
        'new_subscriptions': newSubscriptions,
        'revenue_by_plan': revenueByPlan,
        'purchases_by_plan': purchasesByPlan,
        'average_revenue_per_purchase': totalPurchases > 0 ? totalRevenue / totalPurchases : 0,
      };
    } catch (e) {
      debugPrint('Error getting revenue: $e');
      rethrow;
    }
  }

  // Get user metrics summary (admin function)
  Future<Map<String, dynamic>> getUserMetricsSummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final registrations = await getRegistrationsByDateRange(startDate, endDate);
      final revenueData = await getRevenueByDateRange(startDate, endDate);
      final retentionData = await getUserRetention();

      // Count registrations by user type
      Map<String, int> registrationsByType = {};
      for (var reg in registrations) {
        final userType = reg['userType'] as String? ?? 'unknown';
        registrationsByType[userType] = (registrationsByType[userType] ?? 0) + 1;
      }

      return {
        'period': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
        'registrations': {
          'total': registrations.length,
          'by_type': registrationsByType,
        },
        'revenue': revenueData,
        'retention': retentionData,
      };
    } catch (e) {
      debugPrint('Error getting user metrics summary: $e');
      rethrow;
    }
  }

  // Get daily metrics for charts (admin function)
  Future<List<Map<String, dynamic>>> getDailyMetrics(int days) async {
    try {
      final now = DateTime.now();
      final metrics = <Map<String, dynamic>>[];

      for (int i = days - 1; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        final registrations = await getRegistrationsByDateRange(startOfDay, endOfDay);
        final revenueData = await getRevenueByDateRange(startOfDay, endOfDay);

        metrics.add({
          'date': startOfDay.toIso8601String(),
          'registrations': registrations.length,
          'purchases': revenueData['total_purchases'],
          'revenue': revenueData['total_revenue'],
          'renewals': revenueData['renewals'],
          'new_subscriptions': revenueData['new_subscriptions'],
        });
      }

      return metrics;
    } catch (e) {
      debugPrint('Error getting daily metrics: $e');
      rethrow;
    }
  }
}
