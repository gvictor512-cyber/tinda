import 'dart:async';
import 'dart:io';

import 'presence_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/secure_storage_service.dart';
import 'package:flutter/foundation.dart';
import '../utils/password_validator.dart';
import '../utils/email_validator.dart';
import '../utils/input_sanitizer.dart';
import '../utils/rate_limiter.dart';
import '../utils/secure_logger.dart';
import 'analytics_service.dart';
import 'auth_api_service.dart';
import 'location_service.dart';
import 'public_profile_service.dart';

class AuthService {
  /// Devuelve los bytes de la imagen lista para subir.
  /// (flutter_image_compress desactivado temporalmente mientras se
  /// diagnostica el arranque en iOS; luego se reimplementa en Dart puro)
  static Future<Uint8List> compressImage(String path) async {
    return File(path).readAsBytes();
  }


  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AnalyticsService _analytics = AnalyticsService();
  final AuthApiService _authApi = AuthApiService();
  final LocationService _locationService = LocationService();

  // Default age range for new users
  static const List<int> DEFAULT_AGE_RANGE = [18, 35];

  // Default max distance in km
  static const int DEFAULT_MAX_DISTANCE = 50;

  // Default gender preference
  static const String DEFAULT_GENDER = 'all';

  /// Get the currently authenticated user
  /// Returns null if no user is signed in
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  /// Emits the current user whenever the authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up a new user with email and password
  /// Creates a user document in Firestore with default preferences
  /// Returns UserCredential containing the user information
  /// Throws Exception if sign up fails
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String userType,
    required DateTime birthDate,
    List<XFile> profilePhotos = const [],
    List<XFile> propertyPhotos = const [],
    Map<String, dynamic>? apartment,
  }) async {
    try {
      // Validate email
      final emailValidation = EmailValidator.validateEmail(email);
      if (!emailValidation.isValid) {
        throw Exception(emailValidation.errors.join(', '));
      }

      // Validate password
      final passwordValidation = PasswordValidator.validatePassword(
        password,
        userEmail: email,
        userName: name,
      );
      if (!passwordValidation.isValid) {
        throw Exception(passwordValidation.errors.join(', '));
      }

      // Sanitize inputs
      final sanitizedEmail = InputSanitizer.sanitizeEmail(email);
      final sanitizedName = InputSanitizer.sanitizeUsername(name);
      final sanitizedUserType = InputSanitizer.sanitizeString(userType);

      // Verify age (18+)
      final now = DateTime.now();
      var age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      if (age < 18) {
        throw Exception('Debes ser mayor de 18 años para registrarte');
      }

      final cookiesAccepted =
          await SecureStorageService.read('cookies_accepted') == 'true';

      SecureLogger.logAuth('Sign up attempt', method: 'email', userId: sanitizedEmail);

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: sanitizedEmail,
        password: password,
      );

      // Upload photos
      final uid = userCredential.user!.uid;
      final profilePhotoUrls = <String>[];
      for (var i = 0; i < profilePhotos.length; i++) {
        final ref = _storage.ref().child('users/$uid/profile/$i.jpg');
        await ref.putData(
          await compressImage(profilePhotos[i].path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
        profilePhotoUrls.add(await ref.getDownloadURL());
      }

      final propertyPhotoUrls = <String>[];
      for (var i = 0; i < propertyPhotos.length; i++) {
        final ref = _storage.ref().child('users/$uid/apartment/$i.jpg');
        await ref.putData(
          await compressImage(propertyPhotos[i].path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
        propertyPhotoUrls.add(await ref.getDownloadURL());
      }

      final apartmentData = apartment != null ? Map<String, dynamic>.from(apartment) : null;
      if (apartmentData != null && propertyPhotoUrls.isNotEmpty) {
        apartmentData['photos'] = propertyPhotoUrls;
      }

      // Create user document in Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': sanitizedEmail,
        'name': sanitizedName,
        'userType': sanitizedUserType,
        'birthDate': birthDate,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
        'consent': {
          'acceptedTermsAt': FieldValue.serverTimestamp(),
          'acceptedPrivacyAt': FieldValue.serverTimestamp(),
          'acceptedCookiesAt':
              cookiesAccepted ? FieldValue.serverTimestamp() : null,
        },
        'preferences': {
          'ageRange': DEFAULT_AGE_RANGE,
          'gender': DEFAULT_GENDER,
          'location': null,
          'maxDistance': DEFAULT_MAX_DISTANCE,
        },
        'profile': {
          'bio': '',
          'photos': profilePhotoUrls,
          'interests': [],
        },
        if (apartmentData != null) 'apartment': apartmentData,
      });

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Save user type locally
      await SecureStorageService.setString('user_type', sanitizedUserType);

      // Publish the public profile doc (visible to other users)
      await PublicProfileService.sync(uid);

      // Update current location
      await _locationService.updateAndSaveCurrentLocation();

      // Sync user with backend
      try {
        final firebaseToken = await userCredential.user?.getIdToken() ?? '';
        await _authApi.register(
          email: sanitizedEmail,
          firebaseToken: firebaseToken,
        );
      } catch (apiError) {
        SecureLogger.warning('Backend sync failed on sign up', data: {'error': apiError.toString()});
      }

      SecureLogger.logAuth('Sign up successful', method: 'email', userId: userCredential.user!.uid);

      // Track sign up event
      await _analytics.logSignUp(
        method: 'email',
        userType: userType,
      );

      return userCredential;
    } catch (e) {
      SecureLogger.error('Sign up failed', error: e);
      throw _handleAuthError(e);
    }
  }

  /// Sign in an existing user with email and password
  /// Loads user type from Firestore and saves it locally
  /// Returns UserCredential containing the user information
  /// Throws Exception if sign in fails
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Check rate limiting
      final rateLimitResult = await RateLimiter.canAttemptLogin(email);
      if (!rateLimitResult.allowed) {
        throw Exception(rateLimitResult.message);
      }

      // Validate email format
      final emailValidation = EmailValidator.validateEmail(email);
      if (!emailValidation.isValid) {
        await RateLimiter.recordLoginAttempt(email, false);
        throw Exception(emailValidation.errors.join(', '));
      }

      // Sanitize email
      final sanitizedEmail = InputSanitizer.sanitizeEmail(email);

      SecureLogger.logAuth('Sign in attempt', method: 'email', userId: sanitizedEmail);

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: sanitizedEmail,
        password: password,
      );

      // Load user type from Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (userDoc.exists) {
        final userType = userDoc.data()?['userType'];
        if (userType != null) {
          await SecureStorageService.setString('user_type', userType);
        }
      } else {
        SecureLogger.warning('User document not found', userId: userCredential.user!.uid);
      }

      await RateLimiter.recordLoginAttempt(sanitizedEmail, true);
      SecureLogger.logAuth('Sign in successful', method: 'email', userId: userCredential.user!.uid);

      // Update current location
      await _locationService.updateAndSaveCurrentLocation();

      // Track login event
      await _analytics.logLogin('email');

      // Sync login with backend
      try {
        final firebaseToken = await userCredential.user?.getIdToken() ?? '';
        await _authApi.login(
          email: sanitizedEmail,
          firebaseToken: firebaseToken,
        );
      } catch (apiError) {
        SecureLogger.warning('Backend sync failed on login', data: {'error': apiError.toString()});
      }

      return userCredential;
    } catch (e) {
      await RateLimiter.recordLoginAttempt(email, false);
      SecureLogger.error('Sign in failed', error: e);
      throw _handleAuthError(e);
    }
  }

  /// Sign in with Google OAuth
  /// Creates a new user document if this is the first time signing in
  /// Returns UserCredential containing the user information
  /// Throws Exception if sign in fails or is cancelled
  Future<UserCredential> signInWithGoogle({required String userType}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      
      if (!userDoc.exists) {
        // Create new user document
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': userCredential.user!.displayName ?? 'User',
          'userType': userType,
          'photoURL': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': true,
          'preferences': {
            'ageRange': DEFAULT_AGE_RANGE,
            'gender': DEFAULT_GENDER,
            'location': null,
            'maxDistance': DEFAULT_MAX_DISTANCE,
          },
          'profile': {
            'bio': '',
            'photos': userCredential.user!.photoURL != null 
                ? [userCredential.user!.photoURL] 
                : [],
            'interests': [],
          },
        });

        // Publish the public profile doc (visible to other users)
        unawaited(PublicProfileService.sync(userCredential.user!.uid));

        // Track sign up event for new Google users
        await _analytics.logSignUp(
          method: 'google',
          userType: userType,
        );
      } else {
        // Track login event for existing Google users
        await _analytics.logLogin('google');
      }

      // Save user type locally
      await SecureStorageService.setString('user_type', userType);

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Sign in with Apple ID
  /// Creates a new user document in Firestore if first sign in
  /// Returns UserCredential containing the user information
  /// Throws Exception if sign in fails or is cancelled
  Future<UserCredential> signInWithApple({required String userType}) async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);

      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

      if (!userDoc.exists) {
        final givenName = appleCredential.givenName;
        final familyName = appleCredential.familyName;
        final displayName = [givenName, familyName]
            .where((n) => n != null && n.isNotEmpty)
            .join(' ');

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': appleCredential.email ?? userCredential.user!.email ?? '',
          'name': displayName.isNotEmpty ? displayName : 'User',
          'userType': userType,
          'photoURL': userCredential.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': true,
          'preferences': {
            'ageRange': DEFAULT_AGE_RANGE,
            'gender': DEFAULT_GENDER,
            'location': null,
            'maxDistance': DEFAULT_MAX_DISTANCE,
          },
          'profile': {
            'bio': '',
            'photos': userCredential.user!.photoURL != null
                ? [userCredential.user!.photoURL]
                : [],
            'interests': [],
          },
        });

        // Publish the public profile doc (visible to other users)
        unawaited(PublicProfileService.sync(userCredential.user!.uid));

        // Track sign up event for new Apple users
        await _analytics.logSignUp(
          method: 'apple',
          userType: userType,
        );
      } else {
        // Track login event for existing Apple users
        await _analytics.logLogin('apple');
      }

      // Save user type locally
      await SecureStorageService.setString('user_type', userType);

      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Sign out the current user
  /// Clears local preferences and signs out from both Firebase and Google
  /// Throws Exception if sign out fails
  Future<void> signOut() async {
    try {
      // Mark offline before the auth session ends (writes need auth)
      try {
        await PresenceService.instance.setOffline();
      } catch (_) {}
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      // Clear local preferences
      await SecureStorageService.remove('user_type');
      
      // Reset analytics data
      await _analytics.resetAnalyticsData();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  /// Send a password reset email to the specified email address
  /// Throws Exception if email is invalid or user not found
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Send an email verification to the current user
  /// Requires the user to be signed in
  /// Throws Exception if sending fails
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      rethrow;
    }
  }

  /// Reload the current user data from Firebase
  /// Useful for refreshing user profile after changes
  /// Throws Exception if reload fails
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      debugPrint('Error reloading user: $e');
      rethrow;
    }
  }

  /// Update the user's display name and/or photo URL
  /// Updates both Firebase Auth and Firestore
  /// Throws Exception if update fails
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
      
      // Update in Firestore
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        if (displayName != null) 'name': displayName,
        if (photoURL != null) 'photoURL': photoURL,
      });
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  /// Get the current user's data from Firestore
  /// Returns null if user document doesn't exist
  /// Throws Exception if fetch fails
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      return userDoc.data();
    } catch (e) {
      debugPrint('Error getting user data: $e');
      rethrow;
    }
  }

  /// Check if the current user's email is verified
  /// Returns false if no user is signed in
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Handle auth errors
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No se encontró ningún usuario con este correo electrónico.';
        case 'wrong-password':
          return 'Contraseña incorrecta.';
        case 'email-already-in-use':
          return 'El correo electrónico ya está en uso.';
        case 'invalid-email':
          return 'Dirección de correo electrónico no válida.';
        case 'weak-password':
          return 'La contraseña es demasiado débil.';
        case 'user-disabled':
          return 'Este usuario ha sido deshabilitado.';
        case 'too-many-requests':
          return 'Demasiadas solicitudes. Inténtalo de nuevo más tarde.';
        case 'operation-not-allowed':
          return 'Operación no permitida.';
        default:
          return 'Se produjo un error: ${error.message}';
      }
    }
    return 'Se produjo un error desconocido.';
  }

  /// Whether the current user signed in with email/password.
  /// Used to know if a password is required to delete the account.
  bool get usesPasswordProvider =>
      _auth.currentUser?.providerData
          .any((p) => p.providerId == 'password') ??
      false;

  /// Delete the current user's account and all of its data.
  ///
  /// The backend performs the authoritative cascade via the Admin SDK:
  /// Postgres row anonymized, Firestore documents (users, profiles, swipes,
  /// matches, chats, listings, purchases…) and Storage files removed, and
  /// the Firebase Auth user deleted — for email, Google and Apple accounts.
  ///
  /// Identity is verified first: password users must pass [password];
  /// Google/Apple users confirm through their provider sheet only if the
  /// local session is stale and a client-side fallback is needed.
  /// This action is irreversible.
  /// Throws Exception if deletion fails.
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    final uid = user.uid;

    try {
      // Verify identity before the destructive action. For social providers
      // the backend's Admin SDK deletion does not need a recent login, but
      // a fresh token is required to authenticate the API call itself.
      if (usesPasswordProvider) {
        if (password == null || password.isEmpty) {
          throw Exception('Introduce tu contraseña para eliminar la cuenta');
        }
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: password),
        );
      }

      // Authoritative server-side deletion (Firestore + Storage + Auth + DB).
      var backendDeleted = false;
      try {
        await _authApi.deleteMe();
        backendDeleted = true;
      } catch (apiError) {
        SecureLogger.warning('Backend delete failed, using client fallback',
            data: {'error': apiError.toString()});
      }

      if (!backendDeleted) {
        // Backend unreachable/downgrade path: best-effort local cleanup.
        await _deleteAccountData(uid);
      }

      await _deleteAuthUser(user);
      await _postDeletionCleanup();
      SecureLogger.logAuth('Account deleted', userId: uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      SecureLogger.error('Delete account failed', error: e);
      rethrow;
    }
  }

  /// Deletes the Firebase Auth user. If the backend already removed it via
  /// the Admin SDK, the client may see `user-not-found` — that's success.
  /// A stale session triggers provider re-authentication (Google/Apple).
  Future<void> _deleteAuthUser(User user) async {
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return; // already deleted server-side
      if (e.code == 'requires-recent-login') {
        final providerIds =
            user.providerData.map((p) => p.providerId).toSet();
        final providerId = providerIds.contains('google.com')
            ? 'google.com'
            : providerIds.contains('apple.com')
                ? 'apple.com'
                : null;
        if (providerId != null) {
          await user.reauthenticateWithProvider(
            providerId == 'google.com'
                ? GoogleAuthProvider()
                : AppleAuthProvider(),
          );
          await user.delete();
          return;
        }
      }
      rethrow;
    }
  }

  /// Local cleanup after the account is gone: sign out of social providers
  /// (clears their cached sessions) and wipe secure storage.
  Future<void> _postDeletionCleanup() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await SecureStorageService.remove('user_type');
    await SecureStorageService.remove('is_premium');
    await SecureStorageService.remove('subscription_plan');
    await SecureStorageService.remove('subscription_end_date');
  }

  /// Best-effort client-side cleanup used only when the backend cascade is
  /// unavailable. Security rules still block some collections (handled
  /// server-side when reachable), so failures are logged, not thrown.
  Future<void> _deleteAccountData(String uid) async {
    // Storage folders are virtual prefixes: list then delete every file.
    final folders = [
      'users/$uid/profile',
      'users/$uid/apartment',
      'users/$uid/verification',
      'user_photos/$uid',
    ];
    for (final folder in folders) {
      try {
        final result = await _storage.ref(folder).listAll();
        for (final item in result.items) {
          await item.delete();
        }
      } catch (e) {
        SecureLogger.warning('Storage cleanup failed',
            data: {'folder': folder, 'error': e.toString()});
      }
    }

    // Firestore subcollections (purchases history)
    try {
      final purchases = await _firestore
          .collection('users')
          .doc(uid)
          .collection('purchases')
          .get();
      for (final doc in purchases.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      SecureLogger.warning('Purchases cleanup failed',
          data: {'error': e.toString()});
    }

    // Main user document + public profile
    await PublicProfileService.remove(uid);
    await _firestore.collection('users').doc(uid).delete();
  }
}
