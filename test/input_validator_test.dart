import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/utils/input_validator.dart';

void main() {
  group('InputValidator - String Validation', () {
    test('validateNotEmpty - valid input', () {
      final result = InputValidator.validateNotEmpty('Test', 'Field');
      expect(result.isValid, true);
    });
    
    test('validateNotEmpty - empty input', () {
      final result = InputValidator.validateNotEmpty('', 'Field');
      expect(result.isValid, false);
      expect(result.errorMessage, contains('darf nicht leer sein'));
    });
    
    test('validateLength - valid length', () {
      final result = InputValidator.validateLength(
        'Hello',
        'Field',
        minLength: 2,
        maxLength: 10,
      );
      expect(result.isValid, true);
    });
    
    test('validateLength - too short', () {
      final result = InputValidator.validateLength(
        'A',
        'Field',
        minLength: 2,
        maxLength: 10,
      );
      expect(result.isValid, false);
      expect(result.errorMessage, contains('mindestens'));
    });
    
    test('validateLength - too long', () {
      final result = InputValidator.validateLength(
        'This is a very long string',
        'Field',
        minLength: 2,
        maxLength: 10,
      );
      expect(result.isValid, false);
      expect(result.errorMessage, contains('maximal'));
    });
    
    test('validateName - valid name', () {
      final result = InputValidator.validateName('John Doe', 'Name');
      expect(result.isValid, true);
    });
    
    test('validateName - valid German name', () {
      final result = InputValidator.validateName('Müller-Schmidt', 'Name');
      expect(result.isValid, true);
    });
    
    test('validateName - invalid characters', () {
      final result = InputValidator.validateName('John123', 'Name');
      expect(result.isValid, false);
      expect(result.errorMessage, contains('ungültige Zeichen'));
    });
  });
  
  group('InputValidator - Email Validation', () {
    test('validateEmail - valid email', () {
      final result = InputValidator.validateEmail('test@example.com');
      expect(result.isValid, true);
    });
    
    test('validateEmail - invalid format', () {
      final result = InputValidator.validateEmail('invalid-email');
      expect(result.isValid, false);
      expect(result.errorMessage, contains('Ungültige E-Mail'));
    });
    
    test('validateEmail - empty', () {
      final result = InputValidator.validateEmail('');
      expect(result.isValid, false);
    });
  });
  
  group('InputValidator - Date Validation', () {
    test('validateBirthDate - valid date', () {
      final date = DateTime(1990, 1, 1);
      final result = InputValidator.validateBirthDate(date);
      expect(result.isValid, true);
    });
    
    test('validateBirthDate - future date', () {
      final date = DateTime.now().add(const Duration(days: 1));
      final result = InputValidator.validateBirthDate(date);
      expect(result.isValid, false);
    });
    
    test('validateBirthDate - too old', () {
      final date = DateTime(1800, 1, 1);
      final result = InputValidator.validateBirthDate(date);
      expect(result.isValid, false);
    });
  });
  
  group('InputValidator - Content Sanitization', () {
    test('sanitizeText - removes HTML tags', () {
      final input = '<script>alert("XSS")</script>';
      final sanitized = InputValidator.sanitizeText(input);
      expect(sanitized, contains('&lt;'));
      expect(sanitized, contains('&gt;'));
    });
    
    test('sanitizeSearchQuery - removes SQL characters', () {
      final input = "'; DROP TABLE users; --";
      final sanitized = InputValidator.sanitizeSearchQuery(input);
      expect(sanitized, isNot(contains(';')));
      expect(sanitized, isNot(contains("'")));
    });
    
    test('validateChatMessage - valid message', () {
      final result = InputValidator.validateChatMessage('Hello, world!');
      expect(result.isValid, true);
    });
    
    test('validateChatMessage - too long', () {
      final longMessage = 'A' * 6000;
      final result = InputValidator.validateChatMessage(longMessage);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('maximal'));
    });
  });
  
  group('InputValidator - Numeric Validation', () {
    test('validateNumber - valid number', () {
      final result = InputValidator.validateNumber('42', 'Field');
      expect(result.isValid, true);
    });
    
    test('validateNumber - not a number', () {
      final result = InputValidator.validateNumber('abc', 'Field');
      expect(result.isValid, false);
      expect(result.errorMessage, contains('muss eine Zahl sein'));
    });
    
    test('validateNumber - below minimum', () {
      final result = InputValidator.validateNumber('5', 'Field', min: 10);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('mindestens'));
    });
    
    test('validateNumber - above maximum', () {
      final result = InputValidator.validateNumber('100', 'Field', max: 50);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('maximal'));
    });
  });
  
  group('InputValidator - URL Validation', () {
    test('validateUrl - valid HTTP URL', () {
      final result = InputValidator.validateUrl('http://example.com');
      expect(result.isValid, true);
    });
    
    test('validateUrl - valid HTTPS URL', () {
      final result = InputValidator.validateUrl('https://example.com/path');
      expect(result.isValid, true);
    });
    
    test('validateUrl - invalid URL', () {
      final result = InputValidator.validateUrl('not-a-url');
      expect(result.isValid, false);
      expect(result.errorMessage, contains('Ungültige URL'));
    });
  });
}
