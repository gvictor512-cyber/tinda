import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class PaymentApiService {
  /// Sends the store receipt/purchase token to the backend so the purchase is
  /// verified server-side and the entitlement is granted via the Admin SDK.
  /// Returns the verification result. Throws on failure.
  Future<Map<String, dynamic>> verifyIapPurchase({
    required String productId,
    required String transactionId,
    required String platform,
    String? verificationData,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('Usuario no autenticado');
    _api.setAuthToken(token);
    try {
      final res = await _api.post('/payments/iap/verify',
          data: {
            'productId': productId,
            'transactionId': transactionId,
            'platform': platform,
            if (verificationData != null) 'verificationData': verificationData,
          },
          // Un cold start del backend (Render free) puede tardar ~50s; con
          // el timeout por defecto (15s) la verificación abortaba y la
          // compra quedaba cobrada pero sin entregar.
          options: Options(
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 30),
          ));
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      // Surface the server's real message (NestJS error body) instead of the
      // raw DioException dump in the UI.
      final data = e.response?.data;
      String? serverMsg;
      if (data is Map) {
        final m = data['message'];
        serverMsg = m is List ? m.join(', ') : m?.toString();
      }
      throw Exception(
        serverMsg?.isNotEmpty == true
            ? serverMsg!
            : 'Error del servidor (${e.response?.statusCode ?? 'sin conexión'})',
      );
    } finally {
      _api.clearAuthToken();
    }
  }

  final ApiService _api = ApiService();

  Future<void> purchaseSubscription({
    required String planId,
    required String transactionId,
  }) async {
    try {
      await _api.post('/payments/subscription', data: {
        'planId': planId,
        'transactionId': transactionId,
      });
    } on DioException catch (_) {
      rethrow;
    }
  }

  /// Solicita al backend que registre la compra y envie el resumen por email.
  /// Best-effort: nunca lanza excepciones para no interferir con la entrega
  /// del producto al usuario.
  Future<bool> sendPurchaseReceipt({
    required String productId,
    required String transactionId,
    String? productName,
    int? amountCents,
    String? currency,
    String? platform,
  }) async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return false;
      _api.setAuthToken(token);
      await _api.post('/payments/receipt', data: {
        'productId': productId,
        'transactionId': transactionId,
        if (productName != null) 'productName': productName,
        if (amountCents != null) 'amountCents': amountCents,
        if (currency != null) 'currency': currency,
        if (platform != null) 'platform': platform,
      });
      return true;
    } catch (e) {
      debugPrint('No se pudo solicitar la factura por email: $e');
      return false;
    } finally {
      _api.clearAuthToken();
    }
  }
}
