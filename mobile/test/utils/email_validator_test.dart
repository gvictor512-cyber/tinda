import 'package:flutter_test/flutter_test.dart';
import 'package:roommatematch/utils/email_validator.dart';

void main() {
  group('EmailValidator.validateEmail', () {
    test('accepts a standard gmail address', () {
      final result = EmailValidator.validateEmail('user@gmail.com');
      expect(result.isValid, true);
      expect(result.errors, isEmpty);
      expect(result.sanitizedEmail, 'user@gmail.com');
    });

    test('trims and lowercases valid emails', () {
      final result = EmailValidator.validateEmail('  User@Gmail.com  ');
      expect(result.isValid, true);
      expect(result.sanitizedEmail, 'user@gmail.com');
    });

    test('accepts multi-level domains like mail.co.uk', () {
      final result = EmailValidator.validateEmail('user@mail.co.uk');
      expect(result.isValid, true);
      expect(result.errors, isEmpty);
    });

    test('rejects an empty email', () {
      final result = EmailValidator.validateEmail('');
      expect(result.isValid, false);
      expect(result.errors, isNotEmpty);
    });

    test('rejects an email without @', () {
      expect(EmailValidator.validateEmail('usergmail.com').isValid, false);
    });

    test('rejects an email with more than one @', () {
      expect(
        EmailValidator.validateEmail('a@b@c.com').isValid,
        false,
      );
    });

    test('rejects an email with consecutive dots', () {
      expect(EmailValidator.validateEmail('a..b@gmail.com').isValid, false);
    });

    test('rejects a domain without a dot', () {
      expect(EmailValidator.validateEmail('a@gmail').isValid, false);
    });

    test('flags disposable domains with a warning but stays valid', () {
      final result = EmailValidator.validateEmail('x@yopmail.com');
      expect(result.isValid, true);
      expect(result.isDisposable, true);
      expect(result.warnings, isNotEmpty);
    });

    test('suggests a correction for typo domains', () {
      final result = EmailValidator.validateEmail('u@gmial.com');
      expect(result.hasTypo, true);
      expect(result.suggestedDomain, 'gmail.com');
    });
  });

  group('EmailValidator helpers', () {
    test('isValidFormat matches validateEmail for common cases', () {
      expect(EmailValidator.isValidFormat('user@gmail.com'), true);
      expect(EmailValidator.isValidFormat('not-an-email'), false);
    });

    test('isDisposableEmail detects disposable domains', () {
      expect(EmailValidator.isDisposableEmail('a@mailinator.com'), true);
      expect(EmailValidator.isDisposableEmail('a@gmail.com'), false);
    });

    test('normalizeEmail trims and lowercases', () {
      expect(EmailValidator.normalizeEmail('  A@B.COM '), 'a@b.com');
    });

    test('extractDomain and extractLocalPart split correctly', () {
      expect(EmailValidator.extractDomain('user@mail.co.uk'), 'mail.co.uk');
      expect(EmailValidator.extractLocalPart('user@mail.co.uk'), 'user');
      expect(EmailValidator.extractDomain('invalid'), isNull);
    });
  });
}
