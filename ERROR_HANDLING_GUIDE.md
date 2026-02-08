# Error Handling System - Usage Guide

## Overview

The centralized error handling system provides consistent, user-friendly error management across the Weltenbibliothek app with automatic retry mechanisms and comprehensive logging.

## Features

### ✅ Typed Exceptions
- **NetworkException** - Connection issues, timeouts, server errors
- **DataException** - Data format, corruption, not found
- **StorageException** - Read/write failures, insufficient space
- **AuthException** - Authentication and authorization errors
- **ValidationException** - Input validation errors

### ✅ User-Friendly Messages
- German error messages for end users
- Technical details for debugging
- Context-specific error descriptions

### ✅ Automatic Retry
- Exponential backoff retry policy
- Configurable max attempts and delays
- Smart retry (only for network errors)

### ✅ Error Logging
- Debug-mode logging with full details
- Stack trace capture
- Centralized error tracking

## Usage Examples

### Basic Error Handling

```dart
import 'package:weltenbibliothek/utils/error_handler.dart';

Future<void> fetchData() async {
  try {
    final response = await _api.getData();
    // Process response
  } on NetworkException catch (e) {
    // Show user-friendly message
    showError(e.userMessage);
  } on DataException catch (e) {
    showError(e.userMessage);
  } catch (e, stackTrace) {
    // Convert unknown errors to AppException
    final appError = ErrorHandler.normalizeError(e, stackTrace);
    ErrorHandler.logError(appError);
    showError(appError.userMessage);
  }
}
```

### Using Error Handler

```dart
Future<List<Article>> loadArticles() async {
  try {
    final data = await _cloudflareApi.getArticles();
    return data;
  } catch (error, stackTrace) {
    // Automatic retry with fallback
    return await ErrorHandler.handleError(
      error: error,
      stackTrace: stackTrace,
      retry: () => _cloudflareApi.getArticles(),
      fallbackValue: <Article>[],
    ) ?? [];
  }
}
```

### Using withErrorHandling Extension

```dart
// Automatic error handling with fallback
final articles = await _cloudflareApi.getArticles()
    .withErrorHandling(
      fallbackValue: <Article>[],
    );

// With retry on network errors
final data = await _fetchData()
    .withErrorHandling(
      retry: () => _fetchDataFromBackup(),
      fallbackValue: defaultData,
    );
```

### Retry Policy

```dart
// Configure retry behavior
final retryPolicy = RetryPolicy(
  maxAttempts: 3,
  initialDelay: Duration(seconds: 1),
  maxDelay: Duration(seconds: 10),
  backoffMultiplier: 2.0,
);

// Execute with retry
final result = await retryPolicy.execute(() async {
  return await _cloudflareApi.fetchData();
});
```

### Custom Exceptions

```dart
// Throw specific exceptions
if (response.statusCode == 404) {
  throw DataException.notFound('Artikel');
}

if (response.statusCode == 401) {
  throw AuthException.unauthorized();
}

if (networkError) {
  throw NetworkException.noConnection();
}
```

### Validation Errors

```dart
// Single field error
if (!isValidEmail(email)) {
  throw ValidationException.invalidInput('E-Mail');
}

// Multiple field errors
final errors = <String, String>{};
if (name.isEmpty) errors['name'] = 'Name ist erforderlich';
if (!isValidEmail(email)) errors['email'] = 'Ungültige E-Mail';

if (errors.isNotEmpty) {
  throw ValidationException.multipleErrors(errors);
}
```

## Integration Examples

### Cloudflare API Service

```dart
class CloudflareApiService {
  final _retryPolicy = RetryPolicy(maxAttempts: 3);
  
  Future<List<Article>> getArticles() async {
    return await _retryPolicy.execute(() async {
      try {
        final response = await http.get(_articlesUrl);
        
        if (response.statusCode == 200) {
          return _parseArticles(response.body);
        } else if (response.statusCode >= 500) {
          throw NetworkException.serverError(response.statusCode);
        } else if (response.statusCode == 404) {
          throw DataException.notFound('Artikel');
        } else {
          throw NetworkException.unknown(response);
        }
      } on SocketException {
        throw NetworkException.noConnection();
      } on TimeoutException {
        throw NetworkException.timeout();
      } on FormatException {
        throw DataException.invalidFormat();
      }
    });
  }
}
```

### Storage Service

```dart
class StorageService {
  Future<void> saveData(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } on PathAccessException {
      throw StorageException.writeFailed();
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 28) { // ENOSPC
        throw StorageException.insufficientSpace();
      }
      throw StorageException.writeFailed();
    }
  }
  
  Future<String?> loadData(String key) async {
    try {
      return _prefs.getString(key);
    } catch (e) {
      ErrorHandler.logError(StorageException.readFailed());
      return null; // Graceful degradation
    }
  }
}
```

### UI Error Display

```dart
// Show error to user
void showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () {},
      ),
    ),
  );
}

// With retry option
void showErrorWithRetry(AppException error, VoidCallback onRetry) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error.userMessage),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 5),
      action: error is NetworkException
          ? SnackBarAction(
              label: 'Wiederholen',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    ),
  );
}
```

### Loading with Error Handling

```dart
class DataScreen extends StatefulWidget {
  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  bool _isLoading = true;
  List<Item> _items = [];
  AppException? _error;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final items = await _api.getItems();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      final appError = ErrorHandler.normalizeError(error, stackTrace);
      ErrorHandler.logError(appError);
      
      setState(() {
        _error = appError;
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!.userMessage, textAlign: TextAlign.center),
            SizedBox(height: 16),
            if (_error is NetworkException)
              ElevatedButton(
                onPressed: _loadData,
                child: Text('Wiederholen'),
              ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) => ItemTile(_items[index]),
    );
  }
}
```

## Best Practices

1. **Use specific exception types** - Makes error handling more precise
2. **Always provide user-friendly messages** - German messages for end users
3. **Log errors in debug mode** - Use ErrorHandler.logError()
4. **Implement retry for network errors** - Improves user experience
5. **Provide fallback values** - Graceful degradation instead of crashes
6. **Show retry options** - Let users retry failed network operations
7. **Capture stack traces** - Essential for debugging production issues

## Testing

Run the error handling tests:
```bash
flutter test test/error_handler_test.dart
```

All 28 tests should pass:
- Exception normalization (5 tests)
- NetworkException factories (3 tests)
- DataException factories (3 tests)
- StorageException factories (3 tests)
- AuthException factories (3 tests)
- ValidationException factories (2 tests)
- getUserMessage (2 tests)
- RetryPolicy execution (4 tests)
- ErrorHandlingExtension (3 tests)

## Migration Guide

### Before
```dart
try {
  final data = await _api.getData();
} catch (e) {
  print('Error: $e'); // Poor error handling
  showDialog(...); // Generic error dialog
}
```

### After
```dart
try {
  final data = await _api.getData();
} catch (e, stackTrace) {
  final error = ErrorHandler.normalizeError(e, stackTrace);
  ErrorHandler.logError(error);
  showError(error.userMessage); // User-friendly message
}

// Or even simpler:
final data = await _api.getData().withErrorHandling(
  fallbackValue: [],
);
```

## Future Enhancements

- Sentry/Crashlytics integration for production error tracking
- Offline error queue (retry when connection restored)
- Error analytics dashboard
- A/B testing for error messages
- Automatic bug report generation
