import 'package:dio/dio.dart';
import 'api_service.dart';

class VerificationApiService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _api.get('/verification/status');
      return response.data as Map<String, dynamic>;
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<void> verifyPhone({
    required String phone,
    required String code,
  }) async {
    try {
      await _api.post('/verification/phone', data: {
        'phone': phone,
        'code': code,
      });
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<void> verifySelfie({
    required String selfieUrl,
    required String documentUrl,
  }) async {
    try {
      await _api.post('/verification/selfie', data: {
        'selfieUrl': selfieUrl,
        'documentUrl': documentUrl,
      });
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<void> verifyDocument({
    required String documentUrl,
  }) async {
    try {
      await _api.post('/verification/document', data: {
        'documentUrl': documentUrl,
      });
    } on DioException catch (_) {
      rethrow;
    }
  }
}
