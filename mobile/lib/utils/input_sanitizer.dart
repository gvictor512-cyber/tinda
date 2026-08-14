import 'dart:convert';

class InputSanitizer {
  /// Sanitize a string input to prevent XSS attacks
  static String sanitizeString(String input) {
    if (input.isEmpty) return input;
    
    // Remove null bytes
    String sanitized = input.replaceAll('\x00', '');
    
    // Escape HTML entities
    sanitized = _escapeHtml(sanitized);
    
    // Remove potentially dangerous characters
    sanitized = _removeDangerousChars(sanitized);
    
    // Trim whitespace
    sanitized = sanitized.trim();
    
    return sanitized;
  }

  /// Sanitize email address
  static String sanitizeEmail(String email) {
    if (email.isEmpty) return email;
    
    String sanitized = email.trim().toLowerCase();
    
    // Remove potentially dangerous characters
    sanitized = sanitized.replaceAll(RegExp(r'[<>]'), '');
    
    // Only allow valid email characters
    sanitized = sanitized.replaceAll(RegExp(r'[^\w\.\-\@]'), '');
    
    return sanitized;
  }

  /// Sanitize phone number
  static String sanitizePhoneNumber(String phone) {
    if (phone.isEmpty) return phone;
    
    // Remove all non-digit characters except + for international format
    String sanitized = phone.replaceAll(RegExp(r'[^\d\+]'), '');
    
    // Ensure it starts with + for international format or is just digits
    if (sanitized.startsWith('+')) {
      // Keep the + and digits only
      sanitized = '+${sanitized.substring(1).replaceAll(RegExp(r'[^\d]'), '')}';
    } else {
      // Remove any remaining non-digits
      sanitized = sanitized.replaceAll(RegExp(r'[^\d]'), '');
    }
    
    return sanitized;
  }

  /// Sanitize username
  static String sanitizeUsername(String username) {
    if (username.isEmpty) return username;
    
    String sanitized = username.trim();
    
    // Only allow alphanumeric, underscore, and hyphen
    sanitized = sanitized.replaceAll(RegExp(r'[^\w\-]'), '');
    
    // Remove consecutive special characters
    sanitized = sanitized.replaceAll(RegExp(r'[_\-]{2,}'), '_');
    
    // Remove leading/trailing special characters
    sanitized = sanitized.replaceAll(RegExp(r'^[_\-]+|[_\-]+$'), '');
    
    return sanitized;
  }

  /// Sanitize bio or description text
  static String sanitizeBio(String bio) {
    if (bio.isEmpty) return bio;
    
    String sanitized = bio.trim();
    
    // Escape HTML but preserve basic formatting
    sanitized = _escapeHtml(sanitized);
    
    // Limit length
    const maxLength = 500;
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }
    
    return sanitized;
  }

  /// Sanitize URL
  static String sanitizeUrl(String url) {
    if (url.isEmpty) return url;
    
    String sanitized = url.trim();
    
    // Remove javascript: protocol
    sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    
    // Remove data: protocol
    sanitized = sanitized.replaceAll(RegExp(r'data:', caseSensitive: false), '');
    
    // Remove vbscript: protocol
    sanitized = sanitized.replaceAll(RegExp(r'vbscript:', caseSensitive: false), '');
    
    // Ensure URL starts with http:// or https://
    if (!sanitized.startsWith('http://') && !sanitized.startsWith('https://')) {
      sanitized = 'https://$sanitized';
    }
    
    return sanitized;
  }

  /// Sanitize numeric input
  static String sanitizeNumber(String input) {
    if (input.isEmpty) return input;
    
    // Remove all non-digit characters except decimal point and minus sign
    String sanitized = input.replaceAll(RegExp(r'[^\d\.\-]'), '');
    
    // Ensure only one decimal point
    final parts = sanitized.split('.');
    if (parts.length > 2) {
      sanitized = '${parts[0]}.${parts.sublist(1).join()}';
    }
    
    // Ensure minus sign is only at the beginning
    if (sanitized.contains('-') && !sanitized.startsWith('-')) {
      sanitized = sanitized.replaceAll('-', '');
    }
    
    return sanitized;
  }

  /// Sanitize a list of strings
  static List<String> sanitizeStringList(List<String> inputs) {
    return inputs.map((input) => sanitizeString(input)).toList();
  }

  /// Validate and sanitize JSON input
  static Map<String, dynamic>? sanitizeJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return _sanitizeMap(decoded);
    } catch (e) {
      return null;
    }
  }

  /// Recursively sanitize a Map
  static Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in map.entries) {
      final key = sanitizeString(entry.key);
      final value = entry.value;
      
      if (value is String) {
        sanitized[key] = sanitizeString(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeMap(value);
      } else if (value is List) {
        sanitized[key] = _sanitizeList(value);
      } else {
        sanitized[key] = value;
      }
    }
    
    return sanitized;
  }

  /// Recursively sanitize a List
  static List<dynamic> _sanitizeList(List<dynamic> list) {
    final sanitized = <dynamic>[];
    
    for (final item in list) {
      if (item is String) {
        sanitized.add(sanitizeString(item));
      } else if (item is Map<String, dynamic>) {
        sanitized.add(_sanitizeMap(item));
      } else if (item is List) {
        sanitized.add(_sanitizeList(item));
      } else {
        sanitized.add(item);
      }
    }
    
    return sanitized;
  }

  /// Escape HTML special characters
  static String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Remove dangerous characters that could be used in injection attacks
  static String _removeDangerousChars(String input) {
    // Remove characters that could be used in SQL injection
    String sanitized = input.replaceAll(RegExp(r"[';]"), '');
    
    // Remove characters that could be used in command injection
    sanitized = sanitized.replaceAll(RegExp(r'[|&;$<>]'), '');
    
    // Remove null bytes and other control characters
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    
    return sanitized;
  }

  /// Validate if a string contains only safe characters
  static bool isSafeString(String input) {
    // Check for common XSS patterns
    final xssPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'data:', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'expression\s*\(', caseSensitive: false),
    ];

    for (final pattern in xssPatterns) {
      if (pattern.hasMatch(input)) {
        return false;
      }
    }

    return true;
  }

  /// Sanitize search query
  static String sanitizeSearchQuery(String query) {
    if (query.isEmpty) return query;
    
    String sanitized = query.trim();
    
    // Remove HTML tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Remove special SQL characters
    sanitized = sanitized.replaceAll(RegExp(r"[';]"), '');
    
    // Limit length
    const maxLength = 100;
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }
    
    return sanitized;
  }

  /// Sanitize file name
  static String sanitizeFileName(String fileName) {
    if (fileName.isEmpty) return fileName;
    
    String sanitized = fileName.trim();
    
    // Remove path traversal attempts
    sanitized = sanitized.replaceAll(RegExp(r'\.\.'), '');
    sanitized = sanitized.replaceAll(RegExp(r'/'), '');
    sanitized = sanitized.replaceAll(RegExp(r'\\'), '');
    
    // Remove dangerous characters
    sanitized = sanitized.replaceAll(RegExp(r'[<>:"|?*]'), '');
    
    // Limit length
    const maxLength = 255;
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }
    
    return sanitized;
  }
}
