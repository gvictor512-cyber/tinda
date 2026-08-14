
class PasswordValidator {
  // Minimum password length
  static const int MIN_LENGTH = 8;
  
  // Maximum password length
  static const int MAX_LENGTH = 128;
  
  // Common weak passwords to reject
  static const List<String> COMMON_PASSWORDS = [
    'password',
    '123456',
    '12345678',
    '123456789',
    '12345',
    '1234',
    '111111',
    '1234567',
    'sunshine',
    'qwerty',
    'iloveyou',
    'princess',
    'admin',
    'welcome',
    'login',
    'password123',
    '123123',
    'abc123',
    'letmein',
    'monkey',
    'dragon',
    'baseball',
    'football',
    'master',
    'superman',
    'shadow',
    'mustang',
    'michael',
    'jennifer',
    'charlie',
    'andrew',
    'joshua',
    'matthew',
    'jessica',
    'daniel',
    'password1',
    '1234567890',
    'qwerty123',
    'admin123',
    'root',
    'toor',
    'pass',
    'test',
    'guest',
    'user',
  ];

  /// Validate password strength and return validation result
  static PasswordValidationResult validatePassword(
    String password, {
    String? userEmail,
    String? userName,
  }) {
    final errors = <String>[];
    final warnings = <String>[];
    int strengthScore = 0;

    // Check length
    if (password.length < MIN_LENGTH) {
      errors.add('La contraseña debe tener al menos $MIN_LENGTH caracteres');
    } else if (password.length < 12) {
      warnings.add('Se recomienda una contraseña de al menos 12 caracteres');
    } else {
      strengthScore += 20;
    }

    if (password.length > MAX_LENGTH) {
      errors.add('La contraseña no puede exceder $MAX_LENGTH caracteres');
    }

    // Check for uppercase letters
    if (!password.contains(RegExp(r'[A-Z]'))) {
      warnings.add('Incluye letras mayúsculas para mayor seguridad');
    } else {
      strengthScore += 20;
    }

    // Check for lowercase letters
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('La contraseña debe contener letras minúsculas');
    } else {
      strengthScore += 20;
    }

    // Check for numbers
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('La contraseña debe contener al menos un número');
    } else {
      strengthScore += 20;
    }

    // Check for special characters
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      warnings.add('Incluye caracteres especiales para mayor seguridad');
    } else {
      strengthScore += 20;
    }

    // Check for common passwords
    final lowerPassword = password.toLowerCase();
    for (var common in COMMON_PASSWORDS) {
      if (lowerPassword.contains(common)) {
        errors.add('Esta contraseña es demasiado común y no es segura');
        break;
      }
    }

    // Check for sequential characters
    if (_hasSequentialChars(password)) {
      warnings.add('Evita caracteres secuenciales (1234, abcd)');
    }

    // Check for repeated characters
    if (_hasRepeatedChars(password)) {
      warnings.add('Evita caracteres repetidos (aaaa, 1111)');
    }

    // Check if password contains email or username
    if (userEmail != null && password.toLowerCase().contains(userEmail.toLowerCase())) {
      errors.add('La contraseña no debe contener tu correo electrónico');
    }

    if (userName != null && password.toLowerCase().contains(userName.toLowerCase())) {
      errors.add('La contraseña no debe contener tu nombre de usuario');
    }

    // Check for whitespace
    if (password.contains(' ')) {
      errors.add('La contraseña no debe contener espacios en blanco');
    }

    final isValid = errors.isEmpty;
    final strength = _calculateStrength(strengthScore, password.length);

    return PasswordValidationResult(
      isValid: isValid,
      errors: errors,
      warnings: warnings,
      strength: strength,
      strengthScore: strengthScore,
    );
  }

  /// Check if password has sequential characters
  static bool _hasSequentialChars(String password) {
    final lowerPassword = password.toLowerCase();
    
    // Check for sequential numbers
    for (int i = 0; i < lowerPassword.length - 2; i++) {
      if (lowerPassword.codeUnitAt(i + 1) == lowerPassword.codeUnitAt(i) + 1 &&
          lowerPassword.codeUnitAt(i + 2) == lowerPassword.codeUnitAt(i) + 2) {
        return true;
      }
    }
    
    return false;
  }

  /// Check if password has repeated characters
  static bool _hasRepeatedChars(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i] == password[i + 2]) {
        return true;
      }
    }
    return false;
  }

  /// Calculate password strength based on score
  static PasswordStrength _calculateStrength(int score, int length) {
    if (score >= 80 && length >= 12) {
      return PasswordStrength.veryStrong;
    } else if (score >= 60 && length >= 10) {
      return PasswordStrength.strong;
    } else if (score >= 40 && length >= 8) {
      return PasswordStrength.medium;
    } else if (score >= 20) {
      return PasswordStrength.weak;
    } else {
      return PasswordStrength.veryWeak;
    }
  }

  /// Generate a secure random password
  static String generateSecurePassword({int length = 16}) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const special = '!@#\$%^&*(),.?":{}|<>';
    const allChars = '$uppercase$lowercase$numbers$special';

    final random = DateTime.now().millisecondsSinceEpoch;
    final password = StringBuffer();

    // Ensure at least one character from each category
    password.write(uppercase[random % uppercase.length]);
    password.write(lowercase[random % lowercase.length]);
    password.write(numbers[random % numbers.length]);
    password.write(special[random % special.length]);

    // Fill the rest with random characters
    for (int i = 4; i < length; i++) {
      password.write(allChars[random % allChars.length]);
    }

    // Shuffle the password
    final passwordList = password.toString().split('');
    passwordList.shuffle();
    return passwordList.join();
  }
}

/// Password validation result
class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final PasswordStrength strength;
  final int strengthScore;

  PasswordValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.strength,
    required this.strengthScore,
  });

  @override
  String toString() {
    return 'PasswordValidationResult(isValid: $isValid, strength: $strength, errors: $errors, warnings: $warnings)';
  }
}

/// Password strength levels
enum PasswordStrength {
  veryWeak,
  weak,
  medium,
  strong,
  veryStrong,
}

extension PasswordStrengthExtension on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.veryWeak:
        return 'Muy débil';
      case PasswordStrength.weak:
        return 'Débil';
      case PasswordStrength.medium:
        return 'Media';
      case PasswordStrength.strong:
        return 'Fuerte';
      case PasswordStrength.veryStrong:
        return 'Muy fuerte';
    }
  }

  String get description {
    switch (this) {
      case PasswordStrength.veryWeak:
        return 'Esta contraseña es muy vulnerable';
      case PasswordStrength.weak:
        return 'Esta contraseña puede ser mejorada';
      case PasswordStrength.medium:
        return 'Esta contraseña es aceptable';
      case PasswordStrength.strong:
        return 'Esta contraseña es segura';
      case PasswordStrength.veryStrong:
        return 'Esta contraseña es muy segura';
    }
  }

  double get progress {
    switch (this) {
      case PasswordStrength.veryWeak:
        return 0.2;
      case PasswordStrength.weak:
        return 0.4;
      case PasswordStrength.medium:
        return 0.6;
      case PasswordStrength.strong:
        return 0.8;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }
}
