
class EmailValidator {
  // Simplified email regex pattern for web compatibility
  static const String _emailPattern = r'^[\w\.\+\-]+\@[\w]+\.[\w]+$';
  
  // Common disposable email domains
  static const List<String> DISPOSABLE_DOMAINS = [
    'tempmail.com',
    'guerrillamail.com',
    'mailinator.com',
    '10minutemail.com',
    'yopmail.com',
    'trashmail.com',
    'sharklasers.com',
    'getairmail.com',
    'temp-mail.org',
    'throwawaymail.com',
    'maildrop.cc',
    'fakeinbox.com',
    'tempmail.net',
    'temp-mail.net',
    'mailtemp.com',
    'mailtemp.org',
    'mailtemp.net',
    'mailtemp.co',
    'mailtemp.io',
    'mailtemp.eu',
    'mailtemp.asia',
    'mailtemp.info',
    'mailtemp.biz',
    'mailtemp.me',
    'mailtemp.us',
    'mailtemp.uk',
    'mailtemp.ca',
    'mailtemp.au',
    'mailtemp.in',
    'mailtemp.jp',
    'mailtemp.cn',
    'mailtemp.ru',
    'mailtemp.br',
    'mailtemp.fr',
    'mailtemp.de',
    'mailtemp.it',
    'mailtemp.es',
    'mailtemp.mx',
    'mailtemp.ar',
    'mailtemp.cl',
    'mailtemp.co',
    'mailtemp.pe',
    'mailtemp.ve',
    'mailtemp.ec',
    'mailtemp.bo',
    'mailtemp.py',
    'mailtemp.uy',
    'mailtemp.pr',
    'mailtemp.do',
    'mailtemp.cu',
    'mailtemp.gt',
    'mailtemp.sv',
    'mailtemp.hn',
    'mailtemp.ni',
    'mailtemp.pa',
    'mailtemp.cr',
  ];

  // Common typo domains
  static const Map<String, String> TYPO_DOMAINS = {
    'gmial.com': 'gmail.com',
    'gmal.com': 'gmail.com',
    'gmail.co': 'gmail.com',
    'gmail.con': 'gmail.com',
    'gnail.com': 'gmail.com',
    'gmaill.com': 'gmail.com',
    'yahooo.com': 'yahoo.com',
    'yahoo.co': 'yahoo.com',
    'yahoo.con': 'yahoo.com',
    'yaho.com': 'yahoo.com',
    'hotmial.com': 'hotmail.com',
    'hotmail.co': 'hotmail.com',
    'hotmail.con': 'hotmail.com',
    'hotmil.com': 'hotmail.com',
    'outlok.com': 'outlook.com',
    'outlook.co': 'outlook.com',
    'outlook.con': 'outlook.com',
    'outloook.com': 'outlook.com',
  };

  /// Validate email address
  static EmailValidationResult validateEmail(String email) {
    final errors = <String>[];
    final warnings = <String>[];

    // Check if empty
    if (email.isEmpty) {
      errors.add('El correo electrónico es requerido');
      return EmailValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
      );
    }

    // Trim whitespace
    final trimmedEmail = email.trim();

    // Check length
    if (trimmedEmail.length > 254) {
      errors.add('El correo electrónico es demasiado largo');
    }

    // Check for basic format
    if (!trimmedEmail.contains('@')) {
      errors.add('El correo electrónico debe contener @');
      return EmailValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
      );
    }

    // Split email
    final parts = trimmedEmail.split('@');
    if (parts.length != 2) {
      errors.add('El correo electrónico debe tener exactamente un @');
      return EmailValidationResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
      );
    }

    final localPart = parts[0];
    final domain = parts[1];

    // Validate local part
    if (localPart.isEmpty) {
      errors.add('Falta la parte local del correo electrónico');
    } else if (localPart.length > 64) {
      errors.add('La parte local del correo electrónico es demasiado larga');
    }

    // Validate domain
    if (domain.isEmpty) {
      errors.add('Falta el dominio del correo electrónico');
    } else if (domain.length > 255) {
      errors.add('El dominio del correo electrónico es demasiado largo');
    } else if (!domain.contains('.')) {
      errors.add('El dominio del correo electrónico debe contener al menos un punto');
    }

    // Check for consecutive dots
    if (trimmedEmail.contains('..')) {
      errors.add('El correo electrónico no puede contener puntos consecutivos');
    }

    // Check for leading/trailing dots
    if (localPart.startsWith('.') || localPart.endsWith('.')) {
      errors.add('La parte local no puede empezar o terminar con un punto');
    }

    if (domain.startsWith('.') || domain.endsWith('.')) {
      errors.add('El dominio no puede empezar o terminar con un punto');
    }

    // Check for invalid characters
    if (!RegExp(_emailPattern).hasMatch(trimmedEmail)) {
      errors.add('El formato del correo electrónico no es válido');
    }

    // Check for disposable email
    final lowerDomain = domain.toLowerCase();
    if (DISPOSABLE_DOMAINS.contains(lowerDomain)) {
      warnings.add('Este dominio de correo es temporal. Usa un correo permanente.');
    }

    // Check for common typos
    if (TYPO_DOMAINS.containsKey(lowerDomain)) {
      final suggestedDomain = TYPO_DOMAINS[lowerDomain];
      warnings.add('¿Quisiste decir @$suggestedDomain?');
    }

    // Check for common invalid patterns
    if (trimmedEmail.contains('+') && !trimmedEmail.contains('@gmail.com')) {
      warnings.add('El uso de + en el correo puede no ser compatible con todos los servicios');
    }

    final isValid = errors.isEmpty;
    final isDisposable = DISPOSABLE_DOMAINS.contains(lowerDomain);
    final hasTypo = TYPO_DOMAINS.containsKey(lowerDomain);

    return EmailValidationResult(
      isValid: isValid,
      errors: errors,
      warnings: warnings,
      isDisposable: isDisposable,
      hasTypo: hasTypo,
      suggestedDomain: hasTypo ? TYPO_DOMAINS[lowerDomain] : null,
      sanitizedEmail: isValid ? trimmedEmail.toLowerCase() : null,
    );
  }

  /// Suggest correction for typo domain
  static String? suggestCorrection(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return null;

    final domain = parts[1].toLowerCase();
    return TYPO_DOMAINS[domain];
  }

  /// Check if email is from a disposable domain
  static bool isDisposableEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return false;

    final domain = parts[1].toLowerCase();
    return DISPOSABLE_DOMAINS.contains(domain);
  }

  /// Normalize email (lowercase, trim)
  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  /// Extract domain from email
  static String? extractDomain(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return null;
    return parts[1].toLowerCase();
  }

  /// Extract local part from email
  static String? extractLocalPart(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return null;
    return parts[0];
  }

  /// Validate multiple emails
  static List<EmailValidationResult> validateEmails(List<String> emails) {
    return emails.map((email) => validateEmail(email)).toList();
  }

  /// Check if email format is valid (basic check)
  static bool isValidFormat(String email) {
    return RegExp(_emailPattern).hasMatch(email.trim());
  }

  /// Get email provider
  static String? getProvider(String email) {
    final domain = extractDomain(email);
    if (domain == null) return null;

    final parts = domain.split('.');
    if (parts.length >= 2) {
      return parts[0];
    }
    return domain;
  }

  /// Check if email is from a specific provider
  static bool isFromProvider(String email, String provider) {
    final emailProvider = getProvider(email);
    return emailProvider?.toLowerCase() == provider.toLowerCase();
  }
}

class EmailValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final bool isDisposable;
  final bool hasTypo;
  final String? suggestedDomain;
  final String? sanitizedEmail;

  EmailValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    this.isDisposable = false,
    this.hasTypo = false,
    this.suggestedDomain,
    this.sanitizedEmail,
  });

  @override
  String toString() {
    return 'EmailValidationResult(isValid: $isValid, errors: $errors, warnings: $warnings)';
  }
}
