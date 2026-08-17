import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'analytics_service.dart';

/// Stripe payments orchestrated by the backend.
/// All secret operations (customer creation, PaymentIntent, subscriptions)
/// live in `backend/src/modules/payments`. This file never stores `sk_`.
class StripePaymentService {
  // Stripe publishable key: se inyecta en build con --dart-define o .env
  // nunca se sube al repositorio
  static const String _publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  // Backend API URL. Cambia según entorno:
  // Android emulator: 10.0.2.2:3000
  // iOS simulator / web: localhost:3000
  // Producción: https://api.roommatematch.com
  static const String _backendBaseUrl = 'http://10.0.2.2:3000';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AnalyticsService _analytics = AnalyticsService();

  /// Inicializar Stripe
  /// Debe llamarse al inicio de la app
  static Future<void> initialize() async {
    if (_publishableKey.isEmpty) {
      throw Exception('STRIPE_PUBLISHABLE_KEY no está definida. Usa --dart-define en build.');
    }
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
  }

  // Helpers para comunicación con el backend
  Future<String?> _getAuthToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('Usuario no autenticado');
    return http.post(
      Uri.parse('$_backendBaseUrl$path'),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
  }

  /// Crear un Payment Intent en el servidor
  /// El backend utiliza la clave secreta y devuelve client_secret e id
  Future<Map<String, dynamic>> _createPaymentIntent({
    required double amount,
    required String currency,
    required String planId,
    String? customerId,
  }) async {
    try {
      final response = await _post('/payments/payment-intent', {
        'amount': (amount * 100).toInt(),
        'currency': currency.toLowerCase(),
        'planId': planId,
        if (customerId != null) 'customerId': customerId,
      });

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error creating payment intent: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      rethrow;
    }
  }

  /// Crear un Customer en Stripe a través del backend
  Future<String> _createCustomer({
    required String email,
    required String name,
  }) async {
    try {
      final response = await _post('/payments/customer', {
        'email': email,
        'name': name,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'] as String;
      } else {
        throw Exception('Error creating customer: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating customer: $e');
      rethrow;
    }
  }

  /// Obtener o crear el Customer ID del usuario desde Firestore
  Future<String> _getOrCreateCustomerId() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Buscar customer ID en Firestore
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      String? customerId = userData?['stripeCustomerId'] as String?;

      if (customerId == null) {
        // Crear nuevo customer en Stripe a través del backend
        customerId = await _createCustomer(
          email: currentUser.email ?? '',
          name: currentUser.displayName ?? 'User',
        );

        // Guardar customer ID en Firestore
        await _firestore.collection('users').doc(currentUser.uid).update({
          'stripeCustomerId': customerId,
        });
      }

      return customerId;
    } catch (e) {
      debugPrint('Error getting/creating customer ID: $e');
      rethrow;
    }
  }

  /// Procesar pago con tarjeta
  /// Retorna el paymentIntentId si el pago es exitoso, o null si falla
  Future<String?> processCardPayment({
    required double amount,
    required String currency,
    required String planId,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Crear o obtener customer ID
      final customerId = await _getOrCreateCustomerId();

      // Crear el Payment Intent
      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        planId: planId,
        customerId: customerId,
      );

      // Confirmar el pago
      final paymentIntentResult = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntent['client_secret'],
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              name: currentUser.displayName,
              email: currentUser.email,
            ),
          ),
        ),
      );

      if (paymentIntentResult.status == PaymentIntentsStatus.Succeeded) {
        // Guardar transacción en Firestore
        await _saveTransaction(
          paymentIntentId: paymentIntent['id'],
          amount: amount,
          currency: currency,
          planId: planId,
          status: 'succeeded',
          customerId: customerId,
        );

        // Track en analytics
        await _analytics.logSubscriptionPurchase(
          planId: planId,
          price: amount,
          currency: currency,
          transactionId: paymentIntent['id'],
          isRenewal: false,
        );

        return paymentIntent['id'] as String?;
      } else {
        throw Exception('Payment failed: ${paymentIntentResult.status}');
      }
    } catch (e) {
      debugPrint('Error processing card payment: $e');
      rethrow;
    }
  }

  /// Procesar pago con Apple Pay a través del PaymentSheet de Stripe
  Future<String?> processApplePay({
    required double amount,
    required String currency,
    required String planId,
  }) async {
    return presentPaymentSheet(
      amount: amount,
      currency: currency,
      planId: planId,
      paymentMethod: 'applePay',
      applePay: true,
    );
  }

  /// Procesar pago con Google Pay a través del PaymentSheet de Stripe
  Future<String?> processGooglePay({
    required double amount,
    required String currency,
    required String planId,
  }) async {
    return presentPaymentSheet(
      amount: amount,
      currency: currency,
      planId: planId,
      paymentMethod: 'googlePay',
      googlePay: true,
    );
  }

  /// Guardar transacción en Firestore
  Future<void> _saveTransaction({
    required String paymentIntentId,
    required double amount,
    required String currency,
    required String planId,
    required String status,
    required String customerId,
    String? paymentMethod,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('transactions').add({
        'userId': currentUser.uid,
        'paymentIntentId': paymentIntentId,
        'amount': amount,
        'currency': currency,
        'planId': planId,
        'status': status,
        'customerId': customerId,
        'paymentMethod': paymentMethod ?? 'card',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // También guardar en la subcolección del usuario
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('transactions')
          .add({
        'paymentIntentId': paymentIntentId,
        'amount': amount,
        'currency': currency,
        'planId': planId,
        'status': status,
        'paymentMethod': paymentMethod ?? 'card',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving transaction: $e');
    }
  }

  /// Obtener historial de transacciones del usuario
  Future<List<Map<String, dynamic>>> getUserTransactions() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting user transactions: $e');
      rethrow;
    }
  }

  /// Configurar suscripción recurrente a través del backend
  Future<String> setupSubscription({
    required String priceId,
    required String paymentMethodId,
  }) async {
    try {
      final customerId = await _getOrCreateCustomerId();

      final response = await _post('/payments/subscription', {
        'customerId': customerId,
        'priceId': priceId,
        'paymentMethodId': paymentMethodId,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'] as String;
      } else {
        throw Exception('Error creating subscription: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error setting up subscription: $e');
      rethrow;
    }
  }

  /// Cancelar suscripción a través del backend
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      final response = await _post('/payments/subscription/cancel', {
        'subscriptionId': subscriptionId,
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error cancelling subscription: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      rethrow;
    }
  }

  /// Muestra el Payment Sheet de Stripe y confirma el pago.
  /// Devuelve el paymentIntentId si se completó, `null` si el usuario canceló.
  Future<String?> presentPaymentSheet({
    required double amount,
    required String currency,
    required String planId,
    String paymentMethod = 'card',
    bool applePay = false,
    bool googlePay = false,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Crear/obtener customer a través del backend
      final customerId = await _getOrCreateCustomerId();

      // Crear PaymentIntent en el backend
      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        planId: planId,
        customerId: customerId,
      );

      final clientSecret = paymentIntent['client_secret'] as String?;
      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Backend did not return a client_secret');
      }

      // Inicializar y presentar el PaymentSheet de Stripe
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'RoomMate Match',
          customerId: customerId,
          style: ThemeMode.system,
          applePay: applePay
              ? const PaymentSheetApplePay(
                  merchantCountryCode: 'ES',
                )
              : null,
          googlePay: googlePay
              ? PaymentSheetGooglePay(
                  merchantCountryCode: 'ES',
                  currencyCode: currency.toUpperCase(),
                  testEnv: true,
                )
              : null,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Guardar transacción en Firestore
      await _saveTransaction(
        paymentIntentId: paymentIntent['id'] as String,
        amount: amount,
        currency: currency,
        planId: planId,
        status: 'succeeded',
        customerId: customerId,
        paymentMethod: paymentMethod,
      );

      return paymentIntent['id'] as String;
    } on StripeException catch (e) {
      if (e.error.code == 'Canceled') {
        debugPrint('Payment sheet cancelled by user');
        return null;
      }
      debugPrint('Stripe error: $e');
      rethrow;
    } catch (e) {
      debugPrint('Error presenting payment sheet: $e');
      rethrow;
    }
  }
}
