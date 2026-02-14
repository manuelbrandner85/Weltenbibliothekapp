# 🛡️ **Exception Handling - Analyse & Verbesserungen**

**Datum:** 2025-02-13  
**Projekt:** Weltenbibliothek V101  

---

## 📋 **Aktueller Code - Analyse**

### **Dein Code:**
```dart
class AppException implements Exception {
  final String message;
  final Object? cause;

  AppException(this.message, {this.cause});

  @override
  String toString() => message;
}

Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } catch (e) {
    throw AppException('Operation failed', cause: e);
  }
}
```

---

## ✅ **Was gut ist:**

1. ✅ **Generic Guard-Funktion** - Wiederverwendbar für jeden Return-Typ
2. ✅ **Cause-Tracking** - Original-Exception wird gespeichert
3. ✅ **Simple API** - Einfach zu verwenden: `guard(() async => ...)`
4. ✅ **Custom Exception-Typ** - Eigene Exception-Klasse

---

## ⚠️ **Verbesserungspotenzial:**

### **Problem 1: Generische Fehlermeldung**
```dart
throw AppException('Operation failed', cause: e);
// ❌ Keine Details über den Fehler!
```

### **Problem 2: Keine Fehler-Kategorisierung**
- Netzwerk-Fehler vs. Validierungs-Fehler vs. System-Fehler
- Keine Information über Schweregrad
- Kein Error-Code für systematische Behandlung

### **Problem 3: Keine Stack-Trace-Preservation**
```dart
@override
String toString() => message;
// ❌ Stack-Trace geht verloren!
```

### **Problem 4: Keine Kontext-Informationen**
- Welche Operation ist fehlgeschlagen?
- Welche Parameter wurden verwendet?
- Zeitstempel für Debugging

---

## 🚀 **Verbesserte Version - Production-Ready**

### **1. Erweiterte AppException-Klasse**

```dart
import 'package:flutter/foundation.dart';

/// Basis-Exception-Klasse für alle App-Fehler
class AppException implements Exception {
  final String message;
  final String? code;
  final Object? cause;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;
  final DateTime timestamp;
  final ExceptionSeverity severity;

  AppException(
    this.message, {
    this.code,
    this.cause,
    this.stackTrace,
    this.context,
    this.severity = ExceptionSeverity.error,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('[$severity] $message');
    
    if (code != null) {
      buffer.writeln('Error Code: $code');
    }
    
    if (context != null && context!.isNotEmpty) {
      buffer.writeln('Context: $context');
    }
    
    if (cause != null) {
      buffer.writeln('Caused by: $cause');
    }
    
    if (kDebugMode && stackTrace != null) {
      buffer.writeln('Stack trace:\n$stackTrace');
    }
    
    return buffer.toString();
  }

  /// Konvertiere zu JSON für Logging/Analytics
  Map<String, dynamic> toJson() => {
    'message': message,
    'code': code,
    'cause': cause?.toString(),
    'context': context,
    'timestamp': timestamp.toIso8601String(),
    'severity': severity.toString(),
  };
}

/// Fehler-Schweregrad
enum ExceptionSeverity {
  debug,    // Nur für Entwicklung
  info,     // Informativ, kein Fehler
  warning,  // Warnung, App läuft weiter
  error,    // Fehler, Operation fehlgeschlagen
  critical, // Kritischer Fehler, App-Zustand gefährdet
}
```

---

### **2. Spezialisierte Exception-Typen**

```dart
/// Netzwerk-bezogene Fehler
class NetworkException extends AppException {
  final int? statusCode;
  final String? url;

  NetworkException(
    super.message, {
    this.statusCode,
    this.url,
    super.cause,
    super.stackTrace,
  }) : super(
    code: 'NETWORK_ERROR',
    severity: ExceptionSeverity.error,
    context: {
      'statusCode': statusCode,
      'url': url,
    },
  );
}

/// Validierungs-Fehler
class ValidationException extends AppException {
  final Map<String, String> errors;

  ValidationException(
    super.message,
    this.errors, {
    super.cause,
    super.stackTrace,
  }) : super(
    code: 'VALIDATION_ERROR',
    severity: ExceptionSeverity.warning,
    context: {'errors': errors},
  );
}

/// Backend-API-Fehler
class BackendException extends AppException {
  final int statusCode;
  final String? endpoint;

  BackendException(
    super.message, {
    required this.statusCode,
    this.endpoint,
    super.cause,
    super.stackTrace,
  }) : super(
    code: 'BACKEND_ERROR',
    severity: ExceptionSeverity.error,
    context: {
      'statusCode': statusCode,
      'endpoint': endpoint,
    },
  );
}

/// Authentication/Authorization Fehler
class AuthException extends AppException {
  AuthException(
    super.message, {
    super.cause,
    super.stackTrace,
  }) : super(
    code: 'AUTH_ERROR',
    severity: ExceptionSeverity.error,
  );
}

/// Storage/Database Fehler
class StorageException extends AppException {
  final String? operation;

  StorageException(
    super.message, {
    this.operation,
    super.cause,
    super.stackTrace,
  }) : super(
    code: 'STORAGE_ERROR',
    severity: ExceptionSeverity.error,
    context: {'operation': operation},
  );
}
```

---

### **3. Verbesserte Guard-Funktion mit Kontext**

```dart
/// Generic Guard-Funktion mit Error-Handling und Logging
Future<T> guard<T>(
  Future<T> Function() action, {
  String? operationName,
  Map<String, dynamic>? context,
  Future<T> Function(Object error, StackTrace stackTrace)? onError,
  bool rethrow = true,
}) async {
  try {
    if (kDebugMode && operationName != null) {
      debugPrint('🔄 Starting operation: $operationName');
    }
    
    final result = await action();
    
    if (kDebugMode && operationName != null) {
      debugPrint('✅ Operation completed: $operationName');
    }
    
    return result;
    
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('❌ Error in ${operationName ?? "operation"}: $e');
    }
    
    // Custom Error-Handler aufrufen (falls vorhanden)
    if (onError != null) {
      try {
        return await onError(e, stackTrace);
      } catch (recoveryError) {
        if (kDebugMode) {
          debugPrint('⚠️ Error recovery failed: $recoveryError');
        }
      }
    }
    
    // AppException direkt weiterwerfen
    if (e is AppException) {
      if (rethrow) rethrow;
      throw e;
    }
    
    // Andere Exceptions wrappen
    final wrappedException = AppException(
      operationName != null 
        ? 'Operation "$operationName" failed' 
        : 'Operation failed',
      code: 'OPERATION_FAILED',
      cause: e,
      stackTrace: stackTrace,
      context: context,
    );
    
    if (rethrow) throw wrappedException;
    return throw wrappedException;
  }
}

/// Synchrone Version der Guard-Funktion
T guardSync<T>(
  T Function() action, {
  String? operationName,
  Map<String, dynamic>? context,
  T Function(Object error, StackTrace stackTrace)? onError,
  bool rethrow = true,
}) {
  try {
    if (kDebugMode && operationName != null) {
      debugPrint('🔄 Starting operation: $operationName');
    }
    
    final result = action();
    
    if (kDebugMode && operationName != null) {
      debugPrint('✅ Operation completed: $operationName');
    }
    
    return result;
    
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('❌ Error in ${operationName ?? "operation"}: $e');
    }
    
    if (onError != null) {
      try {
        return onError(e, stackTrace);
      } catch (recoveryError) {
        if (kDebugMode) {
          debugPrint('⚠️ Error recovery failed: $recoveryError');
        }
      }
    }
    
    if (e is AppException) {
      if (rethrow) rethrow;
      throw e;
    }
    
    final wrappedException = AppException(
      operationName != null 
        ? 'Operation "$operationName" failed' 
        : 'Operation failed',
      code: 'OPERATION_FAILED',
      cause: e,
      stackTrace: stackTrace,
      context: context,
    );
    
    if (rethrow) throw wrappedException;
    return throw wrappedException;
  }
}
```

---

## 📝 **Verwendungsbeispiele**

### **Beispiel 1: Einfache Verwendung**
```dart
// Vorher
final result = await guard(() async {
  return await apiCall();
});

// Nachher - mit Kontext
final result = await guard(
  () async => await apiCall(),
  operationName: 'Fetch User Profile',
  context: {'userId': userId},
);
```

---

### **Beispiel 2: Mit Error-Recovery**
```dart
final user = await guard(
  () async => await fetchUser(userId),
  operationName: 'Fetch User',
  onError: (error, stackTrace) async {
    // Fallback: Return cached user
    debugPrint('⚠️ API failed, using cached data');
    return await getCachedUser(userId);
  },
);
```

---

### **Beispiel 3: Spezialisierte Exceptions werfen**
```dart
Future<User> loginUser(String email, String password) async {
  return guard(
    () async {
      // Validierung
      if (email.isEmpty || password.isEmpty) {
        throw ValidationException(
          'Invalid credentials',
          {
            'email': email.isEmpty ? 'Email is required' : '',
            'password': password.isEmpty ? 'Password is required' : '',
          },
        );
      }
      
      // API-Call
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        body: {'email': email, 'password': password},
      );
      
      if (response.statusCode == 401) {
        throw AuthException('Invalid credentials');
      }
      
      if (response.statusCode != 200) {
        throw NetworkException(
          'Login failed',
          statusCode: response.statusCode,
          url: '$baseUrl/auth/login',
        );
      }
      
      return User.fromJson(jsonDecode(response.body));
    },
    operationName: 'User Login',
    context: {'email': email},
  );
}
```

---

### **Beispiel 4: UI Error-Handling**
```dart
Future<void> _handleLogin() async {
  setState(() => _isLoading = true);
  
  try {
    final user = await loginUser(_emailController.text, _passwordController.text);
    
    // Success
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => HomeScreen(user: user),
    ));
    
  } on ValidationException catch (e) {
    // Validierungs-Fehler → Felder markieren
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.orange,
      ),
    );
    
  } on AuthException catch (e) {
    // Auth-Fehler → Anmeldedaten falsch
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ ${e.message}'),
        backgroundColor: Colors.red,
      ),
    );
    
  } on NetworkException catch (e) {
    // Netzwerk-Fehler → Retry-Option
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Network Error'),
        content: Text(e.message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogin(); // Retry
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
  } on AppException catch (e) {
    // Generischer App-Fehler
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.message}')),
    );
    
  } finally {
    setState(() => _isLoading = false);
  }
}
```

---

## 🔧 **Integration ins bestehende Projekt**

### **Datei-Struktur:**
```
lib/
  core/
    exceptions/
      app_exception.dart           # Basis-Exception
      specialized_exceptions.dart  # Network, Auth, etc.
      exception_guard.dart         # guard() Funktionen
      exception_handler.dart       # Globaler Handler
```

---

### **Schritt 1: exception_guard.dart erstellen**
```dart
// lib/core/exceptions/exception_guard.dart
import 'package:flutter/foundation.dart';
import 'app_exception.dart';

// Hier den verbesserten guard() Code einfügen
```

---

### **Schritt 2: In Services verwenden**
```dart
// Beispiel: webrtc_voice_service.dart
Future<bool> joinRoom({...}) async {
  return guard(
    () async {
      // Bestehender Code
      final backendResponse = await VoiceBackendService.join(...);
      // ...
      return true;
    },
    operationName: 'Join Voice Room',
    context: {
      'roomId': roomId,
      'userId': userId,
      'world': world,
    },
    onError: (error, stackTrace) async {
      // Cleanup bei Fehler
      await _cleanup();
      return false;
    },
  );
}
```

---

## 📊 **Vergleich: Vorher vs. Nachher**

| Feature | Vorher | Nachher |
|---------|--------|---------|
| **Fehlermeldung** | Generic "Operation failed" | Spezifische Operation + Kontext |
| **Error-Codes** | ❌ Keine | ✅ Strukturierte Codes |
| **Stack-Trace** | ❌ Verloren | ✅ Preserved |
| **Kontext-Infos** | ❌ Keine | ✅ Parameter, Timestamp, etc. |
| **Error-Recovery** | ❌ Nicht möglich | ✅ Callback-basiert |
| **Fehler-Kategorien** | ❌ Alle gleich | ✅ Network, Auth, Validation, etc. |
| **Logging** | ❌ Manuell | ✅ Automatisch mit Debug-Prints |
| **JSON-Export** | ❌ Nicht möglich | ✅ Für Analytics/Monitoring |

---

## 🎯 **Best Practices**

### ✅ **DO:**
1. **Spezifische Exception-Typen** für verschiedene Fehler-Kategorien
2. **Kontext-Informationen** mitgeben (Parameter, Operation, etc.)
3. **Stack-Traces** preservieren für Debugging
4. **Error-Recovery** implementieren wo sinnvoll
5. **Logging** automatisieren (Debug-Prints, Analytics)

### ❌ **DON'T:**
1. **Generische Fehler** werfen ("Error", "Failed", etc.)
2. **Stack-Traces** verschlucken oder ignorieren
3. **Alle Exceptions** gleich behandeln
4. **Sensible Daten** in Exception-Messages loggen
5. **Exceptions** für Flow-Control verwenden

---

## 🚀 **Empfohlene Implementierung**

### **Option 1: Vollständige Integration (Empfohlen)**
1. Erstelle `lib/core/exceptions/` Verzeichnis
2. Kopiere alle verbesserten Klassen
3. Migriere Services schrittweise
4. Teste Error-Handling in UI

### **Option 2: Minimale Integration**
1. Erweitere nur die `AppException` Klasse
2. Füge `operationName` zu `guard()` hinzu
3. Behalte bestehende Exception-Handhabung

---

## 📚 **Zusätzliche Features (Optional)**

### **1. Globaler Exception-Handler**
```dart
// lib/core/exceptions/exception_handler.dart
class GlobalExceptionHandler {
  static void handleException(Object error, StackTrace stackTrace) {
    if (error is AppException) {
      _logToAnalytics(error);
      _showUserFeedback(error);
    } else {
      _logUnhandledException(error, stackTrace);
    }
  }
  
  static void _logToAnalytics(AppException e) {
    // Firebase Analytics, Sentry, etc.
  }
  
  static void _showUserFeedback(AppException e) {
    // Toast, SnackBar, Dialog
  }
}
```

---

### **2. Exception-Monitoring**
```dart
// Integration mit Firebase Crashlytics
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<T> guardWithMonitoring<T>(
  Future<T> Function() action, {
  String? operationName,
}) async {
  try {
    return await action();
  } catch (e, stackTrace) {
    // Log to Crashlytics
    FirebaseCrashlytics.instance.recordError(
      e,
      stackTrace,
      reason: operationName,
    );
    
    rethrow;
  }
}
```

---

## 📋 **Checkliste für Migration**

- [ ] Erstelle Exception-Klassen in `lib/core/exceptions/`
- [ ] Migriere `guard()` Funktion
- [ ] Teste mit einem Service (z.B. `VoiceBackendService`)
- [ ] Implementiere UI Error-Handling
- [ ] Füge Logging/Analytics hinzu (optional)
- [ ] Dokumentiere Exception-Typen für Team
- [ ] Teste Error-Recovery-Szenarien

---

**Zusammenfassung:** Dein Basis-Code ist gut! Mit den vorgeschlagenen Verbesserungen wird er production-ready mit strukturiertem Error-Handling, Kontext-Informationen und Error-Recovery.

**Status:** ✅ **Bereit für Integration**

---

*Erstellt am: 2025-02-13*  
*Autor: AI Development Team*
