import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthApiService {
  final ApiService _api = ApiService();

  Future<void> register({
    required String email,
    required String firebaseToken,
    String? phone,
  }) async {
    try {
      await _api.post('/auth/register', data: {
        'email': email,
        'firebaseToken': firebaseToken,
        if (phone != null) 'phone': phone,
      });
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String firebaseToken,
  }) async {
    try {
      await _api.post('/auth/login', data: {
        'email': email,
        'firebaseToken': firebaseToken,
      });
    } on DioException catch (_) {
      rethrow;
    }
  }
}
