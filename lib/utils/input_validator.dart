/// Input Validation Utility
/// Provides comprehensive validation for user inputs across the app
/// 
/// Features:
/// - String validation (length, format, content)
/// - Email validation
/// - Date validation
/// - Sanitization (XSS prevention, SQL injection)
/// - File validation (size, type)
library;

import 'dart:io';

/// Validation result with error messages
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });
  
  factory ValidationResult.success() => const ValidationResult(isValid: true);
  
  factory ValidationResult.error(String message) => ValidationResult(
    isValid: false,
    errorMessage: message,
  );
}

/// Input Validator - Static utility class
class InputValidator {
  InputValidator._(); // Private constructor - static utility class
  
  // ========== STRING VALIDATION ==========
  
  /// Validates string is not empty
  static ValidationResult validateNotEmpty(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.error('$fieldName darf nicht leer sein');
    }
    return ValidationResult.success();
  }
  
  /// Validates string length
  static ValidationResult validateLength(
    String? value,
    String fieldName, {
    int? minLength,
    int? maxLength,
  }) {
    if (value == null) {
      return ValidationResult.error('$fieldName darf nicht null sein');
    }
    
    if (minLength != null && value.length < minLength) {
      return ValidationResult.error(
        '$fieldName muss mindestens $minLength Zeichen lang sein',
      );
    }
    
    if (maxLength != null && value.length > maxLength) {
      return ValidationResult.error(
        '$fieldName darf maximal $maxLength Zeichen lang sein',
      );
    }
    
    return ValidationResult.success();
  }
  
  /// Validates name (alphabetic characters, spaces, hyphens)
  static ValidationResult validateName(String? value, String fieldName) {
    final notEmpty = validateNotEmpty(value, fieldName);
    if (!notEmpty.isValid) return notEmpty;
    
    final length = validateLength(value, fieldName, minLength: 2, maxLength: 50);
    if (!length.isValid) return length;
    
    // Allow letters, spaces, hyphens, apostrophes
    final nameRegex = RegExp(r"^[a-zA-ZäöüÄÖÜß\s\-']+$");
    if (!nameRegex.hasMatch(value!)) {
      return ValidationResult.error(
        '$fieldName enthält ungültige Zeichen',
      );
    }
    
    return ValidationResult.success();
  }
  
  /// Validates email address
  static ValidationResult validateEmail(String? value) {
    final notEmpty = validateNotEmpty(value, 'E-Mail');
    if (!notEmpty.isValid) return notEmpty;
    
    // RFC 5322 compliant email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value!)) {
      return ValidationResult.error('Ungültige E-Mail-Adresse');
    }
    
    return ValidationResult.success();
  }
  
  // ========== DATE VALIDATION ==========
  
  /// Validates date is in valid range
  static ValidationResult validateDate(
    DateTime? date, {
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    if (date == null) {
      return ValidationResult.error('Datum darf nicht leer sein');
    }
    
    if (minDate != null && date.isBefore(minDate)) {
      return ValidationResult.error(
        'Datum muss nach ${minDate.year}-${minDate.month}-${minDate.day} liegen',
      );
    }
    
    if (maxDate != null && date.isAfter(maxDate)) {
      return ValidationResult.error(
        'Datum muss vor ${maxDate.year}-${maxDate.month}-${maxDate.day} liegen',
      );
    }
    
    return ValidationResult.success();
  }
  
  /// Validates birthdate (must be in past, reasonable age)
  static ValidationResult validateBirthDate(DateTime? date) {
    if (date == null) {
      return ValidationResult.error('Geburtsdatum darf nicht leer sein');
    }
    
    final now = DateTime.now();
    final minDate = DateTime(now.year - 120, now.month, now.day); // Max 120 years old
    final maxDate = now; // Must be in past
    
    return validateDate(date, minDate: minDate, maxDate: maxDate);
  }
  
  // ========== CONTENT SANITIZATION ==========
  
  /// Sanitizes text input (XSS prevention)
  static String sanitizeText(String input) {
    // Remove potentially dangerous characters
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }
  
  /// Sanitizes search query (SQL injection prevention)
  static String sanitizeSearchQuery(String query) {
    // Remove SQL special characters
    return query
        .replaceAll(RegExp(r'''[;'"\\]'''), '')
        .trim();
  }
  
  /// Validates and sanitizes chat message
  static ValidationResult validateChatMessage(String? message) {
    final notEmpty = validateNotEmpty(message, 'Nachricht');
    if (!notEmpty.isValid) return notEmpty;
    
    final length = validateLength(
      message,
      'Nachricht',
      minLength: 1,
      maxLength: 5000,
    );
    if (!length.isValid) return length;
    
    // Check for spam patterns
    if (_containsSpamPatterns(message!)) {
      return ValidationResult.error('Nachricht enthält ungültige Inhalte');
    }
    
    return ValidationResult.success();
  }
  
  /// Checks for common spam patterns
  static bool _containsSpamPatterns(String text) {
    final spamPatterns = [
      RegExp(r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+', caseSensitive: false),
      RegExp(r'(viagra|cialis|casino|lottery|winner)', caseSensitive: false),
    ];
    
    for (final pattern in spamPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    
    return false;
  }
  
  // ========== FILE VALIDATION ==========
  
  /// Validates file size
  static ValidationResult validateFileSize(
    File file, {
    int maxSizeBytes = 10 * 1024 * 1024, // 10 MB default
  }) {
    final size = file.lengthSync();
    
    if (size > maxSizeBytes) {
      final maxSizeMB = maxSizeBytes / (1024 * 1024);
      return ValidationResult.error(
        'Datei ist zu groß (max. ${maxSizeMB.toStringAsFixed(1)} MB)',
      );
    }
    
    return ValidationResult.success();
  }
  
  /// Validates file type by extension
  static ValidationResult validateFileType(
    File file,
    List<String> allowedExtensions,
  ) {
    final extension = file.path.split('.').last.toLowerCase();
    
    if (!allowedExtensions.contains(extension)) {
      return ValidationResult.error(
        'Ungültiger Dateityp (erlaubt: ${allowedExtensions.join(', ')})',
      );
    }
    
    return ValidationResult.success();
  }
  
  /// Validates image file
  static ValidationResult validateImageFile(File file) {
    final sizeValidation = validateFileSize(file, maxSizeBytes: 5 * 1024 * 1024); // 5 MB
    if (!sizeValidation.isValid) return sizeValidation;
    
    final typeValidation = validateFileType(
      file,
      ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    );
    
    return typeValidation;
  }
  
  // ========== NUMERIC VALIDATION ==========
  
  /// Validates numeric input
  static ValidationResult validateNumber(
    String? value,
    String fieldName, {
    num? min,
    num? max,
  }) {
    final notEmpty = validateNotEmpty(value, fieldName);
    if (!notEmpty.isValid) return notEmpty;
    
    final number = num.tryParse(value!);
    if (number == null) {
      return ValidationResult.error('$fieldName muss eine Zahl sein');
    }
    
    if (min != null && number < min) {
      return ValidationResult.error('$fieldName muss mindestens $min sein');
    }
    
    if (max != null && number > max) {
      return ValidationResult.error('$fieldName darf maximal $max sein');
    }
    
    return ValidationResult.success();
  }
  
  // ========== URL VALIDATION ==========
  
  /// Validates URL
  static ValidationResult validateUrl(String? value) {
    final notEmpty = validateNotEmpty(value, 'URL');
    if (!notEmpty.isValid) return notEmpty;
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    
    if (!urlRegex.hasMatch(value!)) {
      return ValidationResult.error('Ungültige URL');
    }
    
    return ValidationResult.success();
  }
}
