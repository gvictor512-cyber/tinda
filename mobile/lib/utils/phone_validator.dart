
class PhoneValidator {
  // Country codes and their formats
  static const Map<String, PhoneCountryInfo> COUNTRY_CODES = {
    'ES': PhoneCountryInfo(
      name: 'Spain',
      code: '34',
      minLength: 9,
      maxLength: 9,
      pattern: r'^[6-9]\d{8}$',
      example: '612345678',
    ),
    'US': PhoneCountryInfo(
      name: 'United States',
      code: '1',
      minLength: 10,
      maxLength: 10,
      pattern: r'^[2-9]\d{9}$',
      example: '2125551234',
    ),
    'MX': PhoneCountryInfo(
      name: 'Mexico',
      code: '52',
      minLength: 10,
      maxLength: 10,
      pattern: r'^[1-9]\d{9}$',
      example: '5512345678',
    ),
    'AR': PhoneCountryInfo(
      name: 'Argentina',
      code: '54',
      minLength: 10,
      maxLength: 10,
      pattern: r'^[1-9]\d{9}$',
      example: '1112345678',
    ),
    'CO': PhoneCountryInfo(
      name: 'Colombia',
      code: '57',
      minLength: 10,
      maxLength: 10,
      pattern: r'^[1-9]\d{9}$',
      example: '3121234567',
    ),
    'PE': PhoneCountryInfo(
      name: 'Peru',
      code: '51',
      minLength: 9,
      maxLength: 9,
      pattern: r'^[1-9]\d{8}$',
      example: '987654321',
    ),
    'CL': PhoneCountryInfo(
      name: 'Chile',
      code: '56',
      minLength: 9,
      maxLength: 9,
      pattern: r'^[1-9]\d{8}$',
      example: '912345678',
    ),
    'BR': PhoneCountryInfo(
      name: 'Brazil',
      code: '55',
      minLength: 10,
      maxLength: 11,
      pattern: r'^[1-9]\d{9,10}$',
      example: '11987654321',
    ),
    'FR': PhoneCountryInfo(
      name: 'France',
      code: '33',
      minLength: 9,
      maxLength: 9,
      pattern: r'^[1-9]\d{8}$',
      example: '612345678',
    ),
    'DE': PhoneCountryInfo(
      name: 'Germany',
      code: '49',
      minLength: 10,
      maxLength: 11,
      pattern: r'^[1-9]\d{9,10}$',
      example: '15123456789',
    ),
    'IT': PhoneCountryInfo(
      name: 'Italy',
      code: '39',
      minLength: 9,
      maxLength: 10,
      pattern: r'^[3]\d{8,9}$',
      example: '3123456789',
    ),
    'GB': PhoneCountryInfo(
      name: 'United Kingdom',
      code: '44',
      minLength: 10,
      maxLength: 10,
      pattern: r'^[1-9]\d{9}$',
      example: '7123456789',
    ),
    'PT': PhoneCountryInfo(
      name: 'Portugal',
      code: '351',
      minLength: 9,
      maxLength: 9,
      pattern: r'^[2-9]\d{8}$',
      example: '912345678',
    ),
  };

  /// Validate phone number
  static PhoneValidationResult validatePhone(String phone, {String? countryCode}) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check if empty
    if (phone.isEmpty) {
      errors.add('El número de teléfono es requerido');
      return PhoneValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
      );
    }

    // Remove all non-digit characters except +
    String cleaned = phone.replaceAll(RegExp(r'[^\d\+]'), '');

    // Check if it starts with +
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // Check if it's too short
    if (cleaned.length < 8) {
      errors.add('El número de teléfono es demasiado corto');
    }

    // Check if it's too long
    if (cleaned.length > 15) {
      errors.add('El número de teléfono es demasiado largo');
    }

    // Try to detect country code
    String? detectedCountry;
    String phoneNumber = cleaned;

    if (countryCode != null) {
      final countryInfo = COUNTRY_CODES[countryCode.toUpperCase()];
      if (countryInfo != null) {
        if (cleaned.startsWith(countryInfo.code)) {
          phoneNumber = cleaned.substring(countryInfo.code.length);
          detectedCountry = countryCode.toUpperCase();
        } else {
          phoneNumber = cleaned;
          detectedCountry = countryCode.toUpperCase();
        }
      }
    } else {
      // Auto-detect country code
      for (final entry in COUNTRY_CODES.entries) {
        if (cleaned.startsWith(entry.value.code)) {
          phoneNumber = cleaned.substring(entry.value.code.length);
          detectedCountry = entry.key;
          break;
        }
      }
    }

    // Validate against country-specific rules if country detected
    if (detectedCountry != null) {
      final countryInfo = COUNTRY_CODES[detectedCountry];
      if (countryInfo != null) {
        if (phoneNumber.length < countryInfo.minLength) {
          errors.add('El número debe tener al menos ${countryInfo.minLength} dígitos');
        }
        if (phoneNumber.length > countryInfo.maxLength) {
          errors.add('El número no puede tener más de ${countryInfo.maxLength} dígitos');
        }
        if (!RegExp(countryInfo.pattern).hasMatch(phoneNumber)) {
          errors.add('El formato del número no es válido para ${countryInfo.name}');
        }
      }
    } else {
      // Generic validation for unknown country
      if (phoneNumber.length < 8) {
        warnings.add('El número parece demasiado corto para un formato internacional');
      }
      if (phoneNumber.length > 12) {
        warnings.add('El número parece demasiado largo para un formato internacional');
      }
    }

    // Check for invalid patterns
    if (RegExp(r'^0+$').hasMatch(phoneNumber)) {
      errors.add('El número de teléfono no es válido');
    }

    if (RegExp(r'^1+$').hasMatch(phoneNumber)) {
      errors.add('El número de teléfono no es válido');
    }

    if (RegExp(r'(\d)\1{5,}').hasMatch(phoneNumber)) {
      warnings.add('El número contiene dígitos repetidos');
    }

    final isValid = errors.isEmpty;
    final formatted = isValid ? formatPhone(phone, countryCode: detectedCountry) : null;

    return PhoneValidationResult(
      isValid: isValid,
      errors: errors,
      warnings: warnings,
      countryCode: detectedCountry,
      formattedNumber: formatted,
      sanitizedNumber: isValid ? '+$cleaned' : null,
    );
  }

  /// Format phone number for display
  static String formatPhone(String phone, {String? countryCode}) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d\+]'), '');
    
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    String? detectedCountry = countryCode;
    String phoneNumber = cleaned;

    if (detectedCountry == null) {
      for (final entry in COUNTRY_CODES.entries) {
        if (cleaned.startsWith(entry.value.code)) {
          phoneNumber = cleaned.substring(entry.value.code.length);
          detectedCountry = entry.key;
          break;
        }
      }
    } else {
      final countryInfo = COUNTRY_CODES[detectedCountry.toUpperCase()];
      if (countryInfo != null && cleaned.startsWith(countryInfo.code)) {
        phoneNumber = cleaned.substring(countryInfo.code.length);
      }
    }

    // Format based on country
    if (detectedCountry != null) {
      switch (detectedCountry.toUpperCase()) {
        case 'US':
        case 'CA':
          if (phoneNumber.length == 10) {
            return '+1 (${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)}-${phoneNumber.substring(6)}';
          }
          break;
        case 'ES':
          if (phoneNumber.length == 9) {
            return '+34 ${phoneNumber.substring(0, 3)} ${phoneNumber.substring(3, 6)} ${phoneNumber.substring(6)}';
          }
          break;
        case 'FR':
          if (phoneNumber.length == 9) {
            return '+33 ${phoneNumber.substring(0, 1)} ${phoneNumber.substring(1, 4)} ${phoneNumber.substring(4, 7)} ${phoneNumber.substring(7)}';
          }
          break;
        case 'GB':
          if (phoneNumber.length == 10) {
            return '+44 ${phoneNumber.substring(0, 4)} ${phoneNumber.substring(4, 7)} ${phoneNumber.substring(7)}';
          }
          break;
      }
    }

    // Default formatting
    return '+$cleaned';
  }

  /// Normalize phone number to international format
  static String normalizePhone(String phone, {String? countryCode}) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d\+]'), '');
    
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // Add country code if not present
    if (countryCode != null) {
      final countryInfo = COUNTRY_CODES[countryCode.toUpperCase()];
      if (countryInfo != null && !cleaned.startsWith(countryInfo.code)) {
        cleaned = '${countryInfo.code}$cleaned';
      }
    }

    return '+$cleaned';
  }

  /// Extract country code from phone number
  static String? extractCountryCode(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d\+]'), '');
    
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    for (final entry in COUNTRY_CODES.entries) {
      if (cleaned.startsWith(entry.value.code)) {
        return entry.key;
      }
    }

    return null;
  }

  /// Get country info by code
  static PhoneCountryInfo? getCountryInfo(String countryCode) {
    return COUNTRY_CODES[countryCode.toUpperCase()];
  }

  /// Get all supported countries
  static List<PhoneCountryInfo> getAllCountries() {
    return COUNTRY_CODES.values.toList();
  }

  /// Check if phone number is valid format (basic check)
  static bool isValidFormat(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d\+]'), '');
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned.length >= 8 && cleaned.length <= 15 && RegExp(r'^\d+$').hasMatch(cleaned);
  }
}

class PhoneCountryInfo {
  final String name;
  final String code;
  final int minLength;
  final int maxLength;
  final String pattern;
  final String example;

  const PhoneCountryInfo({
    required this.name,
    required this.code,
    required this.minLength,
    required this.maxLength,
    required this.pattern,
    required this.example,
  });
}

class PhoneValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final String? countryCode;
  final String? formattedNumber;
  final String? sanitizedNumber;

  PhoneValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    this.countryCode,
    this.formattedNumber,
    this.sanitizedNumber,
  });

  @override
  String toString() {
    return 'PhoneValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
  }
}
