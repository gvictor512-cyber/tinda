import 'package:flutter/material.dart';
import 'auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isLoading => _authService.isLoading;
  String? get errorMessage => _authService.errorMessage;

  AuthProvider() {
    _authService.addListener(() {
      notifyListeners();
    });
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    final result = await _authService.signInWithEmailAndPassword(email, password);
    notifyListeners();
    return result;
  }

  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    final result = await _authService.signUpWithEmailAndPassword(email, password);
    notifyListeners();
    return result;
  }

  Future<bool> signInWithGoogle() async {
    final result = await _authService.signInWithGoogle();
    notifyListeners();
    return result;
  }

  Future<bool> signInWithApple() async {
    final result = await _authService.signInWithApple();
    notifyListeners();
    return result;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    final result = await _authService.resetPassword(email);
    notifyListeners();
    return result;
  }

  Future<String?> getIdToken() async {
    return await _authService.getIdToken();
  }
}
