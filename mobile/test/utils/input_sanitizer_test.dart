import 'package:flutter_test/flutter_test.dart';
import 'package:roommatematch/utils/input_sanitizer.dart';

void main() {
  group('InputSanitizer.sanitizeEmail', () {
    test('lowercases, trims and removes dangerous characters', () {
      expect(
        InputSanitizer.sanitizeEmail('  User<Name>@Gmail.com '),
        'username@gmail.com',
      );
    });
  });

  group('InputSanitizer.sanitizePhoneNumber', () {
    test('keeps digits and the leading +', () {
      expect(
        InputSanitizer.sanitizePhoneNumber('+34 600-123-456'),
        '+34600123456',
      );
    });

    test('strips non-digits from local numbers', () {
      expect(InputSanitizer.sanitizePhoneNumber('(600) 123 456'), '600123456');
    });
  });

  group('InputSanitizer.sanitizeUrl', () {
    test('removes javascript: scheme', () {
      final result = InputSanitizer.sanitizeUrl('javascript:alert(1)');
      expect(result.toLowerCase().contains('javascript:'), false);
    });

    test('adds https:// when missing', () {
      expect(InputSanitizer.sanitizeUrl('example.com'), 'https://example.com');
    });

    test('keeps an existing https scheme', () {
      expect(
        InputSanitizer.sanitizeUrl('https://example.com'),
        'https://example.com',
      );
    });
  });

  group('InputSanitizer.sanitizeString', () {
    test('escapes and strips script injection attempts', () {
      final result = InputSanitizer.sanitizeString('<script>alert(1)</script>');
      expect(result.contains('<script>'), false);
      expect(result.contains('<'), false);
      expect(result.contains('>'), false);
    });
  });

  group('InputSanitizer.sanitizeSearchQuery', () {
    test('removes quotes, semicolons and HTML tags', () {
      expect(InputSanitizer.sanitizeSearchQuery("<b>a';</b>"), 'a');
    });
  });

  group('InputSanitizer.sanitizeBio', () {
    test('truncates long bios to 500 characters', () {
      final bio = 'a' * 600;
      expect(InputSanitizer.sanitizeBio(bio).length, lessThanOrEqualTo(500));
    });
  });

  group('InputSanitizer.sanitizeFileName', () {
    test('removes path traversal and dangerous characters', () {
      final result = InputSanitizer.sanitizeFileName('../../etc/passwd');
      expect(result.contains('..'), false);
      expect(result.contains('/'), false);
    });
  });

  group('InputSanitizer.isSafeString', () {
    test('detects XSS patterns', () {
      expect(InputSanitizer.isSafeString('<script>x</script>'), false);
      expect(InputSanitizer.isSafeString('texto normal'), true);
    });
  });
}
