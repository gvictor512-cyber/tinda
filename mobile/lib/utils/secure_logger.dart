import 'package:flutter/foundation.dart';
import 'dart:convert';

class SecureLogger {
  // Sensitive fields to redact
  static const List<String> SENSITIVE_FIELDS = [
    'password',
    'token',
    'secret',
    'apiKey',
    'accessToken',
    'refreshToken',
    'auth',
    'creditCard',
    'ssn',
    'socialSecurity',
    'pin',
    'otp',
    'verificationCode',
    'session',
    'cookie',
  ];

  // Patterns to redact
  static const List<String> SENSITIVE_PATTERNS = [
    r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', // Bearer tokens
    r'Basic\s+[A-Za-z0-9\-._~+/]+=*', // Basic auth
    r'[A-Za-z0-9]{32,}', // Potential API keys or tokens
    r'\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}', // Credit card numbers
    r'\d{3}[-\s]?\d{2}[-\s]?\d{4}', // SSN pattern
  ];

  /// Log a debug message with sensitive data redacted
  static void debug(String message, {Map<String, dynamic>? data, String? userId}) {
    if (kDebugMode) {
      final sanitized = _sanitizeData(data);
      final prefix = userId != null ? '[User: ${_maskUserId(userId)}] ' : '';
      debugPrint('$prefix$message ${sanitized != null ? jsonEncode(sanitized) : ''}');
    }
  }

  /// Log an info message
  static void info(String message, {Map<String, dynamic>? data, String? userId}) {
    if (kDebugMode) {
      final sanitized = _sanitizeData(data);
      final prefix = userId != null ? '[User: ${_maskUserId(userId)}] ' : '';
      debugPrint('ℹ️ $prefix$message ${sanitized != null ? jsonEncode(sanitized) : ''}');
    }
  }

  /// Log a warning message
  static void warning(String message, {Map<String, dynamic>? data, String? userId}) {
    if (kDebugMode) {
      final sanitized = _sanitizeData(data);
      final prefix = userId != null ? '[User: ${_maskUserId(userId)}] ' : '';
      debugPrint('⚠️ $prefix$message ${sanitized != null ? jsonEncode(sanitized) : ''}');
    }
  }

  /// Log an error message
  static void error(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data, String? userId}) {
    if (kDebugMode) {
      final sanitized = _sanitizeData(data);
      final prefix = userId != null ? '[User: ${_maskUserId(userId)}] ' : '';
      debugPrint('❌ $prefix$message');
      
      if (error != null) {
        debugPrint('   Error: ${_sanitizeError(error)}');
      }
      
      if (stackTrace != null) {
        debugPrint('   Stack: ${_sanitizeStackTrace(stackTrace)}');
      }
      
      if (sanitized != null) {
        debugPrint('   Data: ${jsonEncode(sanitized)}');
      }
    }
  }

  /// Log a security event
  static void security(String event, {Map<String, dynamic>? context, String? userId}) {
    if (kDebugMode) {
      final sanitized = _sanitizeData(context);
      final prefix = userId != null ? '[User: ${_maskUserId(userId)}] ' : '';
      debugPrint('🔒 SECURITY: $prefix$event ${sanitized != null ? jsonEncode(sanitized) : ''}');
    }
  }

  /// Sanitize data by redacting sensitive information
  static Map<String, dynamic>? _sanitizeData(Map<String, dynamic>? data) {
    if (data == null) return null;
    
    final sanitized = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (_isSensitiveField(key)) {
        sanitized[key] = '[REDACTED]';
      } else if (value is String) {
        sanitized[key] = _sanitizeString(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeData(value);
      } else if (value is List) {
        sanitized[key] = _sanitizeList(value);
      } else {
        sanitized[key] = value;
      }
    }
    
    return sanitized;
  }

  /// Sanitize a list of data
  static List<dynamic> _sanitizeList(List<dynamic> list) {
    final sanitized = <dynamic>[];
    
    for (final item in list) {
      if (item is String) {
        sanitized.add(_sanitizeString(item));
      } else if (item is Map<String, dynamic>) {
        sanitized.add(_sanitizeData(item));
      } else if (item is List) {
        sanitized.add(_sanitizeList(item));
      } else {
        sanitized.add(item);
      }
    }
    
    return sanitized;
  }

  /// Sanitize a string by redacting sensitive patterns
  static String _sanitizeString(String input) {
    String sanitized = input;
    
    // Redact sensitive patterns
    for (final pattern in SENSITIVE_PATTERNS) {
      sanitized = sanitized.replaceAll(RegExp(pattern), '[REDACTED]');
    }
    
    return sanitized;
  }

  /// Check if a field name is sensitive
  static bool _isSensitiveField(String fieldName) {
    final lowerFieldName = fieldName.toLowerCase();
    return SENSITIVE_FIELDS.any((sensitive) => lowerFieldName.contains(sensitive.toLowerCase()));
  }

  /// Mask user ID for logging
  static String _maskUserId(String userId) {
    if (userId.length <= 8) {
      return '***';
    }
    return '${userId.substring(0, 4)}***${userId.substring(userId.length - 4)}';
  }

  /// Sanitize error message
  static String _sanitizeError(dynamic error) {
    String errorString = error.toString();
    
    // Remove potential sensitive information from error messages
    errorString = errorString.replaceAll(RegExp(r'password["\s:=]+[^\s,}]+', caseSensitive: false), 'password: [REDACTED]');
    errorString = errorString.replaceAll(RegExp(r'token["\s:=]+[^\s,}]+', caseSensitive: false), 'token: [REDACTED]');
    errorString = errorString.replaceAll(RegExp(r'key["\s:=]+[^\s,}]+', caseSensitive: false), 'key: [REDACTED]');
    errorString = errorString.replaceAll(RegExp(r'secret["\s:=]+[^\s,}]+', caseSensitive: false), 'secret: [REDACTED]');
    
    return errorString;
  }

  /// Sanitize stack trace
  static String _sanitizeStackTrace(StackTrace stackTrace) {
    String traceString = stackTrace.toString();
    
    // Remove query parameters from URLs in stack trace
    traceString = traceString.replaceAll(RegExp(r'\?[^\s]+'), '?[REDACTED]');
    
    return traceString;
  }

  /// Log API request
  static void logRequest(String method, String endpoint, {Map<String, dynamic>? params, String? userId}) {
    if (kDebugMode) {
      final sanitizedParams = _sanitizeData(params);
      final prefix = userId != null ? '[User: ${_maskUserId(userId)}] ' : '';
      debugPrint('📡 API REQUEST: $prefix$method $endpoint ${sanitizedParams != null ? jsonEncode(sanitizedParams) : ''}');
    }
  }

  /// Log API response
  static void logResponse(String method, String endpoint, int statusCode, {dynamic data, String? userId}) {
    if (kDebugMode) {
      final sanitizedData = data is Map<String, dynamic> ? _sanitizeData(data) : data;
      final prefix = userId != null ? '[User: ${_maskUserId(userId)}] ' : '';
      debugPrint('📡 API RESPONSE: $prefix$method $endpoint $statusCode ${sanitizedData != null ? jsonEncode(sanitizedData) : ''}');
    }
  }

  /// Log database operation
  static void logDatabase(String operation, String collection, {String? documentId, Map<String, dynamic>? data, String? userId}) {
    if (kDebugMode) {
      final sanitizedData = _sanitizeData(data);
      final prefix = userId != null ? '[User: ${_maskUserId(userId)}] ' : '';
      final docInfo = documentId != null ? ' [doc: ${_maskUserId(documentId)}]' : '';
      debugPrint('💾 DB: $prefix$operation $collection$docInfo ${sanitizedData != null ? jsonEncode(sanitizedData) : ''}');
    }
  }

  /// Log authentication event
  static void logAuth(String event, {String? userId, String? method}) {
    if (kDebugMode) {
      final prefix = userId != null ? '[User: ${_maskUserId(userId)}] ' : '';
      final methodInfo = method != null ? ' via $method' : '';
      debugPrint('🔐 AUTH: $prefix$event$methodInfo');
    }
  }

  /// Log validation error
  static void logValidation(String field, String error, {String? userId}) {
    if (kDebugMode) {
      final prefix = userId != null ? '[User: ${_maskUserId(userId)}] ' : '';
      debugPrint('✅ VALIDATION: $prefix$field: $error');
    }
  }

  /// Log performance metric
  static void logPerformance(String operation, Duration duration, {Map<String, dynamic>? context}) {
    if (kDebugMode) {
      final sanitizedContext = _sanitizeData(context);
      debugPrint('⏱️ PERFORMANCE: $operation took ${duration.inMilliseconds}ms ${sanitizedContext != null ? jsonEncode(sanitizedContext) : ''}');
    }
  }
}
