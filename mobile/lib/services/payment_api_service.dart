import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class PaymentApiService {
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

  /// Solicita al backend que registre la compra y envie la factura por email.
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
