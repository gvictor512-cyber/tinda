import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

class RateLimiter {
  // Rate limit configurations
  static const int MAX_LOGIN_ATTEMPTS = 5;
  static const int LOGIN_LOCKOUT_MINUTES = 15;
  static const int MAX_OTP_ATTEMPTS = 3;
  static const int OTP_LOCKOUT_MINUTES = 10;
  static const int MAX_API_REQUESTS_PER_MINUTE = 60;
  static const int MAX_SWIPES_PER_HOUR = 100;
  static const int MAX_MESSAGES_PER_MINUTE = 20;
  static const int MAX_REPORTS_PER_DAY = 5;

  /// Check if user can attempt login
  static Future<RateLimitResult> canAttemptLogin(String email) async {
    // Almacenamiento seguro
    final key = 'login_attempts_$email';
    
    final attempts = await SecureStorageService.getInt(key) ?? 0;
    final lockoutTime = await SecureStorageService.getInt('${key}_lockout') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Check if currently locked out
    if (lockoutTime > now) {
      final remainingMinutes = ((lockoutTime - now) / 60000).ceil();
      return RateLimitResult(
        allowed: false,
        message: 'Demasiados intentos. Intenta de nuevo en $remainingMinutes minutos.',
        remainingTime: Duration(milliseconds: lockoutTime - now),
      );
    }
    
    // Check if attempts exceeded limit
    if (attempts >= MAX_LOGIN_ATTEMPTS) {
      final lockoutEnd = now + (LOGIN_LOCKOUT_MINUTES * 60000);
      await SecureStorageService.setInt('${key}_lockout', lockoutEnd);
      await SecureStorageService.setInt(key, 0); // Reset attempts after lockout
      
      return RateLimitResult(
        allowed: false,
        message: 'Demasiados intentos. Cuenta bloqueada por $LOGIN_LOCKOUT_MINUTES minutos.',
        remainingTime: const Duration(minutes: LOGIN_LOCKOUT_MINUTES),
      );
    }
    
    return RateLimitResult(
      allowed: true,
      remainingAttempts: MAX_LOGIN_ATTEMPTS - attempts,
    );
  }

  /// Record a login attempt
  static Future<void> recordLoginAttempt(String email, bool success) async {
    // Almacenamiento seguro
    final key = 'login_attempts_$email';
    
    if (success) {
      // Reset attempts on successful login
      await SecureStorageService.remove(key);
      await SecureStorageService.remove('${key}_lockout');
    } else {
      // Increment failed attempts
      final attempts = (await SecureStorageService.getInt(key) ?? 0) + 1;
      await SecureStorageService.setInt(key, attempts);
      
      debugPrint('Login attempt failed. Total attempts: $attempts/$MAX_LOGIN_ATTEMPTS');
    }
  }

  /// Check if user can attempt OTP verification
  static Future<RateLimitResult> canAttemptOTP(String phoneNumber) async {
    // Almacenamiento seguro
    final key = 'otp_attempts_$phoneNumber';
    
    final attempts = await SecureStorageService.getInt(key) ?? 0;
    final lockoutTime = await SecureStorageService.getInt('${key}_lockout') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Check if currently locked out
    if (lockoutTime > now) {
      final remainingMinutes = ((lockoutTime - now) / 60000).ceil();
      return RateLimitResult(
        allowed: false,
        message: 'Demasiados intentos. Intenta de nuevo en $remainingMinutes minutos.',
        remainingTime: Duration(milliseconds: lockoutTime - now),
      );
    }
    
    // Check if attempts exceeded limit
    if (attempts >= MAX_OTP_ATTEMPTS) {
      final lockoutEnd = now + (OTP_LOCKOUT_MINUTES * 60000);
      await SecureStorageService.setInt('${key}_lockout', lockoutEnd);
      await SecureStorageService.setInt(key, 0);
      
      return RateLimitResult(
        allowed: false,
        message: 'Demasiados intentos. Bloqueado por $OTP_LOCKOUT_MINUTES minutos.',
        remainingTime: const Duration(minutes: OTP_LOCKOUT_MINUTES),
      );
    }
    
    return RateLimitResult(
      allowed: true,
      remainingAttempts: MAX_OTP_ATTEMPTS - attempts,
    );
  }

  /// Record an OTP attempt
  static Future<void> recordOTPAttempt(String phoneNumber, bool success) async {
    // Almacenamiento seguro
    final key = 'otp_attempts_$phoneNumber';
    
    if (success) {
      await SecureStorageService.remove(key);
      await SecureStorageService.remove('${key}_lockout');
    } else {
      final attempts = (await SecureStorageService.getInt(key) ?? 0) + 1;
      await SecureStorageService.setInt(key, attempts);
      
      debugPrint('OTP attempt failed. Total attempts: $attempts/$MAX_OTP_ATTEMPTS');
    }
  }

  /// Check if user can make API request
  static Future<RateLimitResult> canMakeAPIRequest(String endpoint) async {
    // Almacenamiento seguro
    final key = 'api_requests_$endpoint';
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneMinuteAgo = now - 60000;
    
    // Get recent requests
    final requests = await SecureStorageService.getStringList(key) ?? [];
    final recentRequests = requests
        .map((t) => int.tryParse(t))
        .whereType<int>()
        .where((t) => t > oneMinuteAgo)
        .toList();
    
    if (recentRequests.length >= MAX_API_REQUESTS_PER_MINUTE) {
      return RateLimitResult(
        allowed: false,
        message: 'Demasiadas solicitudes. Espera un momento.',
      );
    }
    
    // Add current request
    recentRequests.add(now);
    await SecureStorageService.setStringList(key, recentRequests.map((t) => t.toString()).toList());
    
    return RateLimitResult(
      allowed: true,
      remainingRequests: MAX_API_REQUESTS_PER_MINUTE - recentRequests.length,
    );
  }

  /// Check if user can swipe
  static Future<RateLimitResult> canSwipe(String userId) async {
    // Almacenamiento seguro
    final key = 'swipes_$userId';
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneHourAgo = now - 3600000;
    
    final swipes = await SecureStorageService.getStringList(key) ?? [];
    final recentSwipes = swipes
        .map((t) => int.tryParse(t))
        .whereType<int>()
        .where((t) => t > oneHourAgo)
        .toList();
    
    if (recentSwipes.length >= MAX_SWIPES_PER_HOUR) {
      return RateLimitResult(
        allowed: false,
        message: 'Has alcanzado el límite de swipes por hora. Intenta más tarde.',
      );
    }
    
    recentSwipes.add(now);
    await SecureStorageService.setStringList(key, recentSwipes.map((t) => t.toString()).toList());
    
    return RateLimitResult(
      allowed: true,
      remainingSwipes: MAX_SWIPES_PER_HOUR - recentSwipes.length,
    );
  }

  /// Check if user can send message
  static Future<RateLimitResult> canSendMessage(String userId) async {
    // Almacenamiento seguro
    final key = 'messages_$userId';
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneMinuteAgo = now - 60000;
    
    final messages = await SecureStorageService.getStringList(key) ?? [];
    final recentMessages = messages
        .map((t) => int.tryParse(t))
        .whereType<int>()
        .where((t) => t > oneMinuteAgo)
        .toList();
    
    if (recentMessages.length >= MAX_MESSAGES_PER_MINUTE) {
      return RateLimitResult(
        allowed: false,
        message: 'Estás enviando mensajes muy rápido. Espera un momento.',
      );
    }
    
    recentMessages.add(now);
    await SecureStorageService.setStringList(key, recentMessages.map((t) => t.toString()).toList());
    
    return RateLimitResult(
      allowed: true,
      remainingMessages: MAX_MESSAGES_PER_MINUTE - recentMessages.length,
    );
  }

  /// Check if user can report
  static Future<RateLimitResult> canReport(String userId) async {
    // Almacenamiento seguro
    final key = 'reports_$userId';
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneDayAgo = now - 86400000;
    
    final reports = await SecureStorageService.getStringList(key) ?? [];
    final recentReports = reports
        .map((t) => int.tryParse(t))
        .whereType<int>()
        .where((t) => t > oneDayAgo)
        .toList();
    
    if (recentReports.length >= MAX_REPORTS_PER_DAY) {
      return RateLimitResult(
        allowed: false,
        message: 'Has alcanzado el límite de reportes por día.',
      );
    }
    
    recentReports.add(now);
    await SecureStorageService.setStringList(key, recentReports.map((t) => t.toString()).toList());
    
    return RateLimitResult(
      allowed: true,
      remainingReports: MAX_REPORTS_PER_DAY - recentReports.length,
    );
  }

  /// Reset rate limits for a user (admin function)
  static Future<void> resetRateLimits(String userId) async {
    // Almacenamiento seguro
    final keys = [
      'login_attempts_$userId',
      'login_attempts_${userId}_lockout',
      'otp_attempts_$userId',
      'otp_attempts_${userId}_lockout',
      'swipes_$userId',
      'messages_$userId',
      'reports_$userId',
    ];
    
    for (final key in keys) {
      await SecureStorageService.remove(key);
    }
    
    debugPrint('Rate limits reset for user: $userId');
  }

  /// Get rate limit status for a user
  static Future<Map<String, dynamic>> getRateLimitStatus(String userId) async {
    // Almacenamiento seguro
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final loginAttempts = await SecureStorageService.getInt('login_attempts_$userId') ?? 0;
    final loginLockout = await SecureStorageService.getInt('login_attempts_${userId}_lockout') ?? 0;
    final otpAttempts = await SecureStorageService.getInt('otp_attempts_$userId') ?? 0;
    
    final swipes = await SecureStorageService.getStringList('swipes_$userId') ?? [];
    final recentSwipes = swipes
        .map((t) => int.tryParse(t))
        .whereType<int>()
        .where((t) => t > now - 3600000)
        .toList();
    
    final messages = await SecureStorageService.getStringList('messages_$userId') ?? [];
    final recentMessages = messages
        .map((t) => int.tryParse(t))
        .whereType<int>()
        .where((t) => t > now - 60000)
        .toList();
    
    return {
      'loginAttempts': loginAttempts,
      'loginLockedOut': loginLockout > now,
      'loginLockoutRemaining': loginLockout > now ? Duration(milliseconds: loginLockout - now).inMinutes : 0,
      'otpAttempts': otpAttempts,
      'swipesLastHour': recentSwipes.length,
      'messagesLastMinute': recentMessages.length,
      'maxSwipesPerHour': MAX_SWIPES_PER_HOUR,
      'maxMessagesPerMinute': MAX_MESSAGES_PER_MINUTE,
    };
  }
}

class RateLimitResult {
  final bool allowed;
  final String? message;
  final Duration? remainingTime;
  final int? remainingAttempts;
  final int? remainingRequests;
  final int? remainingSwipes;
  final int? remainingMessages;
  final int? remainingReports;

  RateLimitResult({
    required this.allowed,
    this.message,
    this.remainingTime,
    this.remainingAttempts,
    this.remainingRequests,
    this.remainingSwipes,
    this.remainingMessages,
    this.remainingReports,
  });

  @override
  String toString() {
    return 'RateLimitResult(allowed: $allowed, message: $message)';
  }
}
