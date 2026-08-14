import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/phone_validator.dart';
import '../utils/input_sanitizer.dart';
import '../utils/rate_limiter.dart';
import '../utils/secure_logger.dart';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Verification levels
  static const int LEVEL_NONE = 0;
  static const int LEVEL_EMAIL = 1;
  static const int LEVEL_PHONE = 2;
  static const int LEVEL_IDENTITY = 3;
  static const int LEVEL_COMPLETE = 4;
  static const int LEVEL_PREMIUM = 5; // Premium verification with manual review

  // Verification code expiration time (10 minutes)
  static const int VERIFICATION_CODE_EXPIRY_MINUTES = 10;

  // Verification code length
  static const int VERIFICATION_CODE_LENGTH = 4;

  // Send verification code to phone (mock implementation)
  Future<bool> sendPhoneVerification(String phoneNumber) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      SecureLogger.warning('Unauthenticated phone verification attempt');
      return false;
    }

    try {
      // Validate phone number
      final phoneValidation = PhoneValidator.validatePhone(phoneNumber);
      if (!phoneValidation.isValid) {
        throw Exception(phoneValidation.errors.join(', '));
      }

      // Sanitize phone number
      final sanitizedPhone = PhoneValidator.normalizePhone(phoneNumber);

      SecureLogger.debug('Sending phone verification', userId: currentUser.uid, data: {
        'phone': PhoneValidator.extractCountryCode(phoneNumber),
      });

      // In production, this would use Firebase Phone Auth
      // For now, we'll simulate sending a code
      
      final verificationCode = _generateVerificationCode();
      
      // Store verification code temporarily
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone_verification_code', verificationCode);
      await prefs.setString('phone_number', sanitizedPhone);
      await prefs.setInt('phone_code_timestamp', DateTime.now().millisecondsSinceEpoch);

      // In production, send SMS with the code
      SecureLogger.debug('Verification code generated', data: {
        'phone': sanitizedPhone,
      });

      return true;
    } catch (e) {
      SecureLogger.error('Failed to send phone verification', error: e);
      throw Exception('Error al enviar código de verificación: $e');
    }
  }

  // Verify phone number with code
  Future<bool> verifyPhoneNumber(String code) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        SecureLogger.warning('Unauthenticated phone verification attempt');
        return false;
      }

      // Check rate limiting for OTP attempts
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phone_number') ?? '';
      final rateLimitResult = await RateLimiter.canAttemptOTP(phoneNumber);
      if (!rateLimitResult.allowed) {
        throw Exception(rateLimitResult.message);
      }

      final storedCode = prefs.getString('phone_verification_code');
      final timestamp = prefs.getInt('phone_code_timestamp') ?? 0;

      // Check if code is expired
      final codeAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (codeAge > VERIFICATION_CODE_EXPIRY_MINUTES * 60 * 1000) {
        await RateLimiter.recordOTPAttempt(phoneNumber, false);
        throw Exception('Código de verificación caducado');
      }

      if (storedCode != code) {
        await RateLimiter.recordOTPAttempt(phoneNumber, false);
        throw Exception('Código de verificación no válido');
      }

      SecureLogger.logAuth('Phone verified', userId: currentUser.uid);

      // Update user verification status
      await _firestore.collection('users').doc(currentUser.uid).update({
        'verification': {
          'phone': {
            'verified': true,
            'phoneNumber': phoneNumber,
            'verifiedAt': FieldValue.serverTimestamp(),
          },
          'level': LEVEL_PHONE,
        },
      });

      // Clear temporary data
      await prefs.remove('phone_verification_code');
      await prefs.remove('phone_code_timestamp');

      await RateLimiter.recordOTPAttempt(phoneNumber, true);

      return true;
    } catch (e) {
      SecureLogger.error('Failed to verify phone number', error: e);
      throw Exception('Error al verificar número de teléfono: $e');
    }
  }

  // Verify email (triggered by Firebase Auth)
  Future<bool> verifyEmail() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('Usuario no autenticado - no se puede verificar correo');
      return false;
    }

    try {
      // Reload user to get updated email verification status
      await currentUser.reload();

      if (currentUser.emailVerified == true) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'verification': {
            'email': {
              'verified': true,
              'email': currentUser.email,
              'verifiedAt': FieldValue.serverTimestamp(),
            },
            'level': LEVEL_EMAIL,
          },
        });

        return true;
      }

      return false;
    } catch (e) {
      throw Exception('Error al verificar correo electrónico: $e');
    }
  }

  // Upload identity document (mock implementation)
  Future<bool> uploadIdentityDocument({
    required String documentType,
    required String documentNumber,
    required String frontImageUrl,
    String? backImageUrl,
    required String selfieImageUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      SecureLogger.warning('Unauthenticated identity document upload attempt');
      return false;
    }

    try {
      // Validate inputs
      if (documentType.isEmpty) {
        throw Exception('El tipo de documento es requerido');
      }
      if (documentNumber.isEmpty) {
        throw Exception('El número de documento es requerido');
      }
      if (frontImageUrl.isEmpty) {
        throw Exception('La imagen frontal del documento es requerida');
      }
      if (selfieImageUrl.isEmpty) {
        throw Exception('La selfie es requerida');
      }

      // Sanitize inputs
      final sanitizedDocType = InputSanitizer.sanitizeString(documentType);
      final sanitizedDocNumber = InputSanitizer.sanitizeString(documentNumber);
      final sanitizedFrontUrl = InputSanitizer.sanitizeUrl(frontImageUrl);
      final sanitizedBackUrl = backImageUrl != null ? InputSanitizer.sanitizeUrl(backImageUrl) : null;
      final sanitizedSelfieUrl = InputSanitizer.sanitizeUrl(selfieImageUrl);

      SecureLogger.security('Identity document uploaded', userId: currentUser.uid, context: {
        'documentType': sanitizedDocType,
      });

      // In production, this would integrate with identity verification services
      // like Onfido, Stripe Identity, etc.
      
      await _firestore.collection('users').doc(currentUser.uid).update({
        'verification': {
          'identity': {
            'documentType': sanitizedDocType,
            'documentNumber': sanitizedDocNumber,
            'frontImageUrl': sanitizedFrontUrl,
            'backImageUrl': sanitizedBackUrl,
            'selfieImageUrl': sanitizedSelfieUrl,
            'submittedAt': FieldValue.serverTimestamp(),
            'status': 'pending',
          },
          'level': LEVEL_IDENTITY,
        },
      });

      // Create verification request document
      await _firestore.collection('verification_requests').add({
        'userId': currentUser.uid,
        'documentType': sanitizedDocType,
        'documentNumber': sanitizedDocNumber,
        'frontImageUrl': sanitizedFrontUrl,
        'backImageUrl': sanitizedBackUrl,
        'selfieImageUrl': sanitizedSelfieUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      SecureLogger.error('Failed to upload identity document', error: e);
      throw Exception('Error al subir documento de identidad: $e');
    }
  }

  // Get verification status
  Future<Map<String, dynamic>> getVerificationStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('Usuario no autenticado - devolviendo estado de verificación por defecto');
      return {
        'level': LEVEL_NONE,
        'emailVerified': false,
        'phoneVerified': false,
        'identityVerified': false,
      };
    }

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();

      final verification = userData?['verification'] as Map<String, dynamic>?;
      
      if (verification == null) {
        return {
          'level': LEVEL_NONE,
          'emailVerified': false,
          'phoneVerified': false,
          'identityVerified': false,
        };
      }

      return {
        'level': verification['level'] ?? LEVEL_NONE,
        'emailVerified': verification['email']?['verified'] ?? false,
        'phoneVerified': verification['phone']?['verified'] ?? false,
        'identityVerified': verification['identity']?['status'] == 'approved',
        'identityStatus': verification['identity']?['status'] ?? 'none',
      };
    } catch (e) {
      debugPrint('Error al obtener estado de verificación: $e');
      rethrow;
    }
  }

  // Check if user is verified
  Future<bool> isVerified() async {
    final status = await getVerificationStatus();
    return status['level'] >= LEVEL_PHONE;
  }

  // Check if user is fully verified
  Future<bool> isFullyVerified() async {
    final status = await getVerificationStatus();
    return status['level'] >= LEVEL_COMPLETE;
  }

  // Get verification badge
  String getVerificationBadge(int level) {
    switch (level) {
      case LEVEL_EMAIL:
        return '✓ Correo verificado';
      case LEVEL_PHONE:
        return '✓✓ Teléfono verificado';
      case LEVEL_IDENTITY:
        return '✓✓✓ Identidad verificada';
      case LEVEL_COMPLETE:
        return '✓✓✓✓ Completamente verificado';
      case LEVEL_PREMIUM:
        return '⭐ Premium Verificado';
      default:
        return 'No verificado';
    }
  }

  // Request Premium verification (manual review)
  Future<bool> requestPremiumVerification({
    required String fullName,
    required String idNumber,
    required String idType,
    List<String>? idDocumentUrls,
    String? additionalInfo,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      SecureLogger.warning('Unauthenticated premium verification request');
      return false;
    }

    try {
      // Validate inputs
      if (fullName.isEmpty) {
        throw Exception('El nombre completo es requerido');
      }
      if (idNumber.isEmpty) {
        throw Exception('El número de identificación es requerido');
      }
      if (idType.isEmpty) {
        throw Exception('El tipo de identificación es requerido');
      }

      // Sanitize inputs
      final sanitizedName = InputSanitizer.sanitizeString(fullName);
      final sanitizedIdNumber = InputSanitizer.sanitizeString(idNumber);
      final sanitizedIdType = InputSanitizer.sanitizeString(idType);
      final sanitizedDocUrls = idDocumentUrls?.map((url) => InputSanitizer.sanitizeUrl(url)).toList();
      final sanitizedInfo = additionalInfo != null ? InputSanitizer.sanitizeBio(additionalInfo) : null;

      SecureLogger.security('Premium verification requested', userId: currentUser.uid);

      // Create verification request
      await _firestore.collection('verification_requests').add({
        'userId': currentUser.uid,
        'type': 'premium',
        'fullName': sanitizedName,
        'idNumber': sanitizedIdNumber,
        'idType': sanitizedIdType,
        'idDocumentUrls': sanitizedDocUrls ?? [],
        'additionalInfo': sanitizedInfo,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      // Update user verification status to pending
      await _firestore.collection('users').doc(currentUser.uid).update({
        'verification.premium': {
          'status': 'pending',
          'requestedAt': FieldValue.serverTimestamp(),
        },
      });

      return true;
    } catch (e) {
      SecureLogger.error('Failed to request premium verification', error: e);
      rethrow;
    }
  }

  // Admin: Approve Premium verification
  Future<bool> approvePremiumVerification(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verification.premium.status': 'approved',
        'verification.premium.approvedAt': FieldValue.serverTimestamp(),
        'verification.level': LEVEL_PREMIUM,
        'isPremiumVerified': true,
      });

      // Update verification request
      final requestsQuery = await _firestore
          .collection('verification_requests')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'premium')
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in requestsQuery.docs) {
        await doc.reference.update({
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Failed to approve premium verification: $e');
      rethrow;
    }
  }

  // Admin: Reject Premium verification
  Future<bool> rejectPremiumVerification(String userId, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verification.premium.status': 'rejected',
        'verification.premium.rejectedAt': FieldValue.serverTimestamp(),
        'verification.premium.rejectionReason': reason,
      });

      // Update verification request
      final requestsQuery = await _firestore
          .collection('verification_requests')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'premium')
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in requestsQuery.docs) {
        await doc.reference.update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectionReason': reason,
        });
      }

      return true;
    } catch (e) {
      debugPrint('Failed to reject premium verification: $e');
      rethrow;
    }
  }

  // Check if user has Premium verification badge
  Future<bool> hasPremiumBadge() async {
    final status = await getVerificationStatus();
    return status['level'] >= LEVEL_PREMIUM;
  }

  // Request email verification
  Future<bool> requestEmailVerification() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('Usuario no autenticado - no se puede solicitar verificación de correo');
      return false;
    }

    try {
      await currentUser.sendEmailVerification();
      return true;
    } catch (e) {
      throw Exception('Failed to send email verification: $e');
    }
  }

  // Resend phone verification code
  Future<bool> resendPhoneVerification() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phone_number');

    if (phoneNumber == null) {
      throw Exception('No phone number found');
    }

    return await sendPhoneVerification(phoneNumber);
  }

  // Generate verification code (for testing)
  String _generateVerificationCode() {
    final random = DateTime.now().millisecondsSinceEpoch % (10 * VERIFICATION_CODE_LENGTH);
    return random.toString().padLeft(VERIFICATION_CODE_LENGTH, '0');
  }

  // Admin: Approve identity verification
  Future<bool> approveIdentityVerification(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verification.identity.status': 'approved',
        'verification.identity.approvedAt': FieldValue.serverTimestamp(),
        'verification.level': LEVEL_COMPLETE,
      });

      // Update verification request
      final requestsQuery = await _firestore
          .collection('verification_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in requestsQuery.docs) {
        await doc.reference.update({
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Failed to approve verification: $e');
      rethrow;
    }
  }

  // Admin: Reject identity verification
  Future<bool> rejectIdentityVerification(String userId, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verification.identity.status': 'rejected',
        'verification.identity.rejectedAt': FieldValue.serverTimestamp(),
        'verification.identity.rejectionReason': reason,
        'verification.level': LEVEL_PHONE, // Downgrade to phone level
      });

      // Update verification request
      final requestsQuery = await _firestore
          .collection('verification_requests')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (var doc in requestsQuery.docs) {
        await doc.reference.update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectionReason': reason,
        });
      }

      return true;
    } catch (e) {
      debugPrint('Failed to reject verification: $e');
      rethrow;
    }
  }

  // Get verification requirements for features
  Map<String, int> getFeatureRequirements() {
    return {
      'basic_matching': LEVEL_NONE,
      'chat': LEVEL_EMAIL,
      'location_search': LEVEL_PHONE,
      'premium_features': LEVEL_IDENTITY,
      'boost_profile': LEVEL_PHONE,
      'see_who_liked': LEVEL_IDENTITY,
    };
  }

  // Check if user can use feature
  Future<bool> canUseFeature(String feature) async {
    final status = await getVerificationStatus();
    final requirements = getFeatureRequirements();
    final requiredLevel = requirements[feature] ?? LEVEL_NONE;

    return status['level'] >= requiredLevel;
  }

  // Get verification progress
  Future<Map<String, dynamic>> getVerificationProgress() async {
    final status = await getVerificationStatus();
    
    return {
      'email': status['emailVerified'] ?? false,
      'phone': status['phoneVerified'] ?? false,
      'identity': status['identityVerified'] ?? false,
      'currentLevel': status['level'] ?? LEVEL_NONE,
      'maxLevel': LEVEL_COMPLETE,
      'progress': (status['level'] ?? 0) / LEVEL_COMPLETE,
    };
  }
}
