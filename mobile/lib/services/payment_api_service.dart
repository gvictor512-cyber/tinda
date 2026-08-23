import 'package:dio/dio.dart';
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
}
