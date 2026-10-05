import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  /// Permanently delete the user record on the backend. Performs the full
  /// cascade server-side: Postgres anonymization, Firestore documents,
  /// Storage files and the Firebase Auth user (Admin SDK).
  /// Throws if there is no signed-in user or the request fails.
  Future<void> deleteMe() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw Exception('Usuario no autenticado');
    _api.setAuthToken(token);
    try {
      await _api.delete('/users/me');
    } on DioException catch (_) {
      rethrow;
    } finally {
      _api.clearAuthToken();
    }
  }
}
