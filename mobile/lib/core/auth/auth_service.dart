import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  String? _userId;
  bool _isLoading = false;
  String? _errorMessage;
  bool _useMockAuth = false; // Firebase configured via google-services.json / GoogleService-Info.plist

  String? get user => _userId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _userId != null;
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  AuthService() {
    _initAuth();
  }

  void _initAuth() {
    if (!_useMockAuth) {
      try {
        _firebaseAuth.authStateChanges().listen((user) {
          _userId = user?.uid;
          notifyListeners();
        });
      } catch (e) {
        debugPrint('AuthService: error al escuchar authStateChanges - $e');
      }
    }
  }

  // Sign in with Email and Password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockAuth) {
        // Mock sign in for development
        await Future.delayed(const Duration(milliseconds: 300));
        _userId = 'mock_user_id';
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Real Firebase authentication
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _userId = userCredential.user?.uid;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign up with Email and Password
  Future<bool> signUpWithEmailAndPassword(String email, String password, {Map<String, dynamic>? userData}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockAuth) {
        // Mock sign up for development
        await Future.delayed(const Duration(milliseconds: 300));
        _userId = 'mock_user_id';
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Real Firebase authentication
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _userId = userCredential.user?.uid;
      
      // Create user document in Firestore
      if (userData != null && userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'isPremium': false,
          ...userData,
        });
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockAuth) {
        // Mock sign in for development
        await Future.delayed(const Duration(milliseconds: 300));
        _userId = 'mock_user_id';
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Real Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      _userId = userCredential.user?.uid;
      
      // Create or update user document
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'displayName': userCredential.user!.displayName,
          'photoURL': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'isPremium': false,
        }, SetOptions(merge: true));
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in with Apple (iOS only)
  Future<bool> signInWithApple() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockAuth) {
        // Mock sign in for development
        await Future.delayed(const Duration(milliseconds: 300));
        _userId = 'mock_user_id';
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Real Apple Sign In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = firebase_auth.OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(oauthCredential);
      _userId = userCredential.user?.uid;
      
      // Create or update user document
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'displayName': credential.givenName ?? credential.familyName,
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'isPremium': false,
        }, SetOptions(merge: true));
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_useMockAuth) {
        await Future.delayed(const Duration(milliseconds: 200));
        _userId = null;
      } else {
        await _firebaseAuth.signOut();
        await _googleSignIn.signOut();
        _userId = null;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockAuth) {
        // Mock reset for development
        await Future.delayed(const Duration(milliseconds: 300));
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Real Firebase password reset
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    if (_userId == null) return null;

    try {
      if (_useMockAuth) {
        // Mock user data
        await Future.delayed(const Duration(milliseconds: 200));
        return {
          'email': 'mock@example.com',
          'displayName': 'Mock User',
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
          'isPremium': false,
        };
      }

      // Real Firestore data
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return null;
    }
  }

  // Get current ID token
  Future<String?> getIdToken() async {
    if (_userId == null) return null;

    try {
      if (_useMockAuth) {
        return 'mock_token_$_userId';
      }

      final user = _firebaseAuth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      return null;
    }
  }

  // Update user data
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    if (_userId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockAuth) {
        await Future.delayed(const Duration(milliseconds: 200));
        _isLoading = false;
        notifyListeners();
        return true;
      }

      await _firestore.collection('users').doc(_userId).update(data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    if (_userId == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockAuth) {
        await Future.delayed(const Duration(milliseconds: 200));
        _userId = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Delete user document
      await _firestore.collection('users').doc(_userId).delete();
      // Delete auth account
      await _firebaseAuth.currentUser?.delete();
      _userId = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Helper method to get user-friendly error messages
  String _getErrorMessage(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No se encontró ningún usuario con este correo electrónico';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con este correo electrónico';
        case 'weak-password':
          return 'La contraseña es demasiado débil';
        case 'invalid-email':
          return 'Correo electrónico inválido';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada';
        case 'too-many-requests':
          return 'Demasiados intentos. Inténtalo más tarde';
        case 'operation-not-allowed':
          return 'Operación no permitida';
        default:
          return 'Error de autenticación: ${error.message}';
      }
    }
    return error.toString();
  }

  // Method to enable/disable mock auth (for testing)
  void setUseMockAuth(bool useMock) {
    _useMockAuth = useMock;
    if (!useMock) {
      _initAuth();
    }
  }
}
