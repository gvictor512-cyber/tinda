import 'package:flutter_test/flutter_test.dart';
import 'package:roommatematch/utils/password_validator.dart';

void main() {
  group('PasswordValidator.validatePassword', () {
    test('rejects passwords shorter than the minimum length', () {
      final result = PasswordValidator.validatePassword('Ab1!xyz');
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.contains('8')), true);
    });

    test('rejects passwords without a number', () {
      final result = PasswordValidator.validatePassword('Abcdefgh!xyz');
      expect(result.isValid, false);
    });

    test('rejects passwords without a lowercase letter', () {
      final result = PasswordValidator.validatePassword('ABCDEFG1!');
      expect(result.isValid, false);
    });

    test('rejects common passwords even with extra characters', () {
      final result = PasswordValidator.validatePassword('Xpassword99!');
      expect(result.isValid, false);
    });

    test('rejects passwords containing the user email', () {
      final result = PasswordValidator.validatePassword(
        'User@gmail.com1!',
        userEmail: 'user@gmail.com',
      );
      expect(result.isValid, false);
    });

    test('rejects passwords containing whitespace', () {
      final result = PasswordValidator.validatePassword('Ab cdef1!xy');
      expect(result.isValid, false);
    });

    test('accepts a strong password', () {
      final result = PasswordValidator.validatePassword('Str0ng!Xqzv#9Lm');
      expect(result.isValid, true);
      expect(result.strengthScore, greaterThanOrEqualTo(80));
      expect(
        result.strength,
        anyOf(PasswordStrength.strong, PasswordStrength.veryStrong),
      );
    });

    test('flags sequential and repeated characters as warnings', () {
      final result = PasswordValidator.validatePassword('Aabcd1111!x');
      expect(result.warnings, isNotEmpty);
    });
  });

  group('PasswordValidator.generateSecurePassword', () {
    test('generates a password of the requested length', () {
      expect(PasswordValidator.generateSecurePassword(length: 20).length, 20);
    });

    test('generated passwords pass the format requirements', () {
      final generated = PasswordValidator.generateSecurePassword(length: 16);
      expect(generated.contains(RegExp(r'[A-Z]')), true);
      expect(generated.contains(RegExp(r'[a-z]')), true);
      expect(generated.contains(RegExp(r'[0-9]')), true);
    });
  });
}
