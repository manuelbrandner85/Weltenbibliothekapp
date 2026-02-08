# Input Validation Layer - Usage Guide

## Overview

The `InputValidator` utility provides comprehensive input validation for the Weltenbibliothek app. It helps ensure data quality, security, and user experience by validating all user inputs before processing.

## Features

### ✅ String Validation
- Not empty checks
- Length constraints (min/max)
- Name validation (alphabetic + spaces + hyphens)
- Special character handling

### ✅ Email Validation
- RFC 5322 compliant
- Format verification
- Empty check

### ✅ Date Validation
- Range validation (min/max dates)
- Birthdate validation (reasonable age range)
- Future date prevention

### ✅ Content Sanitization
- XSS prevention (HTML tag escaping)
- SQL injection prevention
- Spam pattern detection
- Chat message validation

### ✅ File Validation
- Size limits
- Type checking (by extension)
- Image-specific validation

### ✅ Numeric Validation
- Number format verification
- Range validation (min/max)

### ✅ URL Validation
- HTTP/HTTPS protocol validation
- Format verification

## Usage Examples

### Basic Validation

```dart
import 'package:weltenbibliothek/utils/input_validator.dart';

// Validate name
final nameResult = InputValidator.validateName(
  nameController.text,
  'Name',
);

if (!nameResult.isValid) {
  // Show error to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(nameResult.errorMessage!)),
  );
  return;
}
```

### Form Validation

```dart
// In a TextFormField
TextFormField(
  controller: _emailController,
  decoration: InputDecoration(labelText: 'E-Mail'),
  validator: (value) {
    final result = InputValidator.validateEmail(value);
    return result.isValid ? null : result.errorMessage;
  },
)
```

### Chat Message Validation

```dart
Future<void> _sendMessage() async {
  final message = _messageController.text;
  
  // Validate message
  final validation = InputValidator.validateChatMessage(message);
  if (!validation.isValid) {
    showError(validation.errorMessage!);
    return;
  }
  
  // Sanitize before sending
  final sanitized = InputValidator.sanitizeText(message);
  
  // Send sanitized message
  await _cloudflareApi.sendChatMessage(sanitized);
}
```

### Search Query Sanitization

```dart
void _performSearch(String query) {
  // Sanitize search query to prevent SQL injection
  final sanitizedQuery = InputValidator.sanitizeSearchQuery(query);
  
  // Perform search with sanitized query
  final results = await _searchService.search(sanitizedQuery);
  // ...
}
```

### Profile Data Validation

```dart
Future<void> _saveProfile() async {
  // Validate first name
  final firstNameValidation = InputValidator.validateName(
    _firstNameController.text,
    'Vorname',
  );
  if (!firstNameValidation.isValid) {
    showError(firstNameValidation.errorMessage!);
    return;
  }
  
  // Validate last name
  final lastNameValidation = InputValidator.validateName(
    _lastNameController.text,
    'Nachname',
  );
  if (!lastNameValidation.isValid) {
    showError(lastNameValidation.errorMessage!);
    return;
  }
  
  // Validate birthdate
  final birthdateValidation = InputValidator.validateBirthDate(
    _selectedBirthDate,
  );
  if (!birthdateValidation.isValid) {
    showError(birthdateValidation.errorMessage!);
    return;
  }
  
  // All valid - save profile
  await _storageService.saveProfile(...);
}
```

### Image Upload Validation

```dart
Future<void> _uploadImage(File imageFile) async {
  // Validate image file
  final validation = InputValidator.validateImageFile(imageFile);
  
  if (!validation.isValid) {
    showError(validation.errorMessage!);
    return;
  }
  
  // Upload valid image
  await _cloudflareApi.uploadMedia(imageFile);
}
```

## Integration Checklist

### Profile Screens
- ✅ `lib/screens/shared/profile_editor_screen.dart` - Add name, email validation
- ✅ `lib/screens/energie_world_wrapper.dart` - Validate profile data
- ✅ `lib/screens/materie_world_wrapper.dart` - Validate profile data

### Chat Screens
- ✅ `lib/screens/energie/energie_live_chat_screen.dart` - Validate & sanitize messages
- ✅ `lib/screens/materie/materie_live_chat_screen.dart` - Validate & sanitize messages

### Search/Research Screens
- ✅ `lib/screens/recherche_screen_v2.dart` - Sanitize search queries
- ✅ `lib/screens/materie/enhanced_recherche_tab.dart` - Sanitize queries

### Tool Screens
- ✅ All tool screens with text inputs - Add appropriate validation
- ✅ Calculator screens - Validate numeric inputs

### Community Features
- ✅ Post creation - Validate content length and sanitize
- ✅ Comments - Validate and sanitize
- ✅ User-generated content - Full sanitization

## Security Benefits

### XSS Prevention
Prevents cross-site scripting attacks by escaping HTML tags in user input.

### SQL Injection Prevention
Sanitizes search queries by removing SQL special characters.

### Spam Prevention
Detects common spam patterns (URLs, keywords) in chat messages.

### Data Integrity
Ensures all data meets format and length requirements before storage.

## Best Practices

1. **Always validate user input** before processing or storing
2. **Sanitize before display** to prevent XSS attacks
3. **Show clear error messages** to guide users
4. **Use appropriate validators** for each field type
5. **Combine validators** when multiple checks are needed

## Testing

Run the validation tests:
```bash
flutter test test/input_validator_test.dart
```

All 25 tests should pass:
- String validation (8 tests)
- Email validation (3 tests)
- Date validation (3 tests)
- Content sanitization (4 tests)
- Numeric validation (4 tests)
- URL validation (3 tests)

## Future Enhancements

- Phone number validation
- Password strength validation
- Credit card number validation (if needed)
- Custom regex pattern validation
- Async validation (e.g., check if email exists)
