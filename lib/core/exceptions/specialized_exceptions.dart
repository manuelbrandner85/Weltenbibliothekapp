import 'app_exception.dart';

// ============================================
// NETWORK & API EXCEPTIONS
// ============================================

/// Netzwerk-bezogene Fehler
/// 
/// Verwendung für:
/// - HTTP-Request-Fehler
/// - Timeout-Errors
/// - Connection-Probleme
/// - Server-Errors
class NetworkException extends AppException {
  /// HTTP-Status-Code (falls vorhanden)
  final int? statusCode;
  
  /// URL die aufgerufen wurde
  final String? url;
  
  /// HTTP-Methode (GET, POST, etc.)
  final String? method;

  NetworkException(
    super.message, {
    this.statusCode,
    this.url,
    this.method,
    super.cause,
    super.stackTrace,
  }) : super(
    code: 'NETWORK_ERROR',
    severity: ExceptionSeverity.error,
    context: {
      if (statusCode != null) 'statusCode': statusCode,
      if (url != null) 'url': url,
      if (method != null) 'method': method,
    },
  );

  /// Ist dies ein Timeout-Fehler?
  bool get isTimeout => 
    cause.toString().contains('timeout') || 
    message.toLowerCase().contains('timeout');
  
  /// Ist dies ein Server-Fehler (5xx)?
  bool get isServerError => 
    statusCode != null && statusCode! >= 500 && statusCode! < 600;
  
  /// Ist dies ein Client-Fehler (4xx)?
  bool get isClientError => 
    statusCode != null && statusCode! >= 400 && statusCode! < 500;
}

/// Backend-API-spezifische Fehler
/// 
/// Verwendung für:
/// - REST-API-Fehler
/// - GraphQL-Errors
/// - WebSocket-Errors
class BackendException extends AppException {
  /// HTTP-Status-Code
  final int statusCode;
  
  /// API-Endpoint der aufgerufen wurde
  final String? endpoint;
  
  /// Response-Body (falls vorhanden)
  final String? responseBody;

  BackendException(
    super.message, {
    required this.statusCode,
    this.endpoint,
    this.responseBody,
    super.cause,
    super.stackTrace,
  }) : super(
    code: 'BACKEND_ERROR',
    severity: ExceptionSeverity.error,
    context: {
      'statusCode': statusCode,
      if (endpoint != null) 'endpoint': endpoint,
      if (responseBody != null) 'responseBody': responseBody,
    },
  );

  /// Factory für häufige Backend-Fehler
  factory BackendException.unauthorized(String? endpoint) {
    return BackendException(
      'Unauthorized access',
      statusCode: 401,
      endpoint: endpoint,
    );
  }

  factory BackendException.notFound(String? endpoint) {
    return BackendException(
      'Resource not found',
      statusCode: 404,
      endpoint: endpoint,
    );
  }

  factory BackendException.serverError(String? endpoint) {
    return BackendException(
      'Internal server error',
      statusCode: 500,
      endpoint: endpoint,
    );
  }
}

// ============================================
// VALIDATION EXCEPTIONS
// ============================================

/// Validierungs-Fehler für Eingaben
/// 
/// Verwendung für:
/// - Form-Validierung
/// - Input-Checks
/// - Business-Rule-Violations
class ValidationException extends AppException {
  /// Map von Feld-Namen zu Fehlermeldungen
  final Map<String, String> errors;

  ValidationException(
    super.message,
    this.errors, {
    super.cause,
    super.stackTrace,
  }) : super(
    code: 'VALIDATION_ERROR',
    severity: ExceptionSeverity.warning,
    context: {'fieldErrors': errors},
  );

  /// Hat dieses Feld einen Fehler?
  bool hasFieldError(String fieldName) => errors.containsKey(fieldName);
  
  /// Hole Fehlermeldung für Feld
  String? getFieldError(String fieldName) => errors[fieldName];
  
  /// Anzahl der Fehler
  int get errorCount => errors.length;

  /// Factory für einzelne Feld-Fehler
  factory ValidationException.singleField(String fieldName, String error) {
    return ValidationException(
      'Validation failed: $fieldName',
      {fieldName: error},
    );
  }
}

// ============================================
// AUTH & SECURITY EXCEPTIONS
// ============================================

/// Authentication/Authorization Fehler
/// 
/// Verwendung für:
/// - Login-Fehler
/// - Token-Probleme
/// - Permission-Denied
class AuthException extends AppException {
  /// Auth-Fehler-Typ
  final AuthErrorType errorType;

  AuthException(
    super.message, {
    this.errorType = AuthErrorType.unknown,
    super.cause,
    super.stackTrace,
  }) : super(
    code: 'AUTH_ERROR',
    severity: ExceptionSeverity.error,
    context: {'errorType': errorType.name},
  );

  /// Factory-Methoden für häufige Auth-Fehler
  factory AuthException.invalidCredentials() {
    return AuthException(
      'Invalid username or password',
      errorType: AuthErrorType.invalidCredentials,
    );
  }

  factory AuthException.sessionExpired() {
    return AuthException(
      'Your session has expired. Please login again.',
      errorType: AuthErrorType.sessionExpired,
    );
  }

  factory AuthException.permissionDenied() {
    return AuthException(
      'You do not have permission to perform this action',
      errorType: AuthErrorType.permissionDenied,
    );
  }

  factory AuthException.tokenInvalid() {
    return AuthException(
      'Authentication token is invalid',
      errorType: AuthErrorType.tokenInvalid,
    );
  }
}

/// Typ des Auth-Fehlers
enum AuthErrorType {
  unknown,
  invalidCredentials,
  sessionExpired,
  tokenInvalid,
  permissionDenied,
  accountLocked,
  accountNotFound,
}

// ============================================
// STORAGE & DATA EXCEPTIONS
// ============================================

/// Storage/Database Fehler
/// 
/// Verwendung für:
/// - Lokale Hive-Datenbank
/// - Shared Preferences
/// - File-System-Operationen
class StorageException extends AppException {
  /// Art der Storage-Operation
  final String? operation;
  
  /// Betroffener Key/Identifier
  final String? key;

  StorageException(
    super.message, {
    this.operation,
    this.key,
    super.cause,
    super.stackTrace,
  }) : super(
    code: 'STORAGE_ERROR',
    severity: ExceptionSeverity.error,
    context: {
      if (operation != null) 'operation': operation,
      if (key != null) 'key': key,
    },
  );

  /// Factory für häufige Storage-Fehler
  factory StorageException.readFailed(String key) {
    return StorageException(
      'Failed to read from storage',
      operation: 'read',
      key: key,
    );
  }

  factory StorageException.writeFailed(String key) {
    return StorageException(
      'Failed to write to storage',
      operation: 'write',
      key: key,
    );
  }

  factory StorageException.notInitialized() {
    return StorageException(
      'Storage not initialized. Call init() first.',
      operation: 'initialization',
    );
  }
}

// ============================================
// WEBRTC & VOICE EXCEPTIONS
// ============================================

/// WebRTC/Voice-spezifische Fehler
/// 
/// Verwendung für:
/// - Voice-Room-Fehler
/// - WebRTC-Connection-Problems
/// - Microphone-Access-Issues
class VoiceException extends AppException {
  /// Room-ID (falls relevant)
  final String? roomId;
  
  /// User-ID (falls relevant)
  final String? userId;

  VoiceException(
    super.message, {
    this.roomId,
    this.userId,
    super.cause,
    super.stackTrace,
  }) : super(
    code: 'VOICE_ERROR',
    severity: ExceptionSeverity.error,
    context: {
      if (roomId != null) 'roomId': roomId,
      if (userId != null) 'userId': userId,
    },
  );

  /// Factory für häufige Voice-Fehler
  factory VoiceException.roomFull(String roomId) {
    return VoiceException(
      'Voice room is full (max 10 participants)',
      roomId: roomId,
    );
  }

  factory VoiceException.permissionDenied() {
    return VoiceException(
      'Microphone permission denied',
    );
  }

  factory VoiceException.connectionFailed(String roomId) {
    return VoiceException(
      'Failed to connect to voice room',
      roomId: roomId,
    );
  }
}

/// Raum-Kapazitäts-Fehler
/// 
/// Spezialisierung für "Room Full" Fehler
class RoomFullException extends VoiceException {
  /// Aktuelle Teilnehmerzahl
  final int currentCount;
  
  /// Maximale Teilnehmerzahl
  final int maxCount;

  RoomFullException({
    required String roomId,
    required this.currentCount,
    required this.maxCount,
  }) : super(
    'Voice room "$roomId" is full ($currentCount/$maxCount participants)',
    roomId: roomId,
  );
}

// ============================================
// CONFIGURATION & INITIALIZATION EXCEPTIONS
// ============================================

/// Konfigurations-Fehler
/// 
/// Verwendung für:
/// - Missing API-Keys
/// - Invalid Configuration
/// - Setup-Probleme
class ConfigurationException extends AppException {
  /// Name der fehlenden/fehlerhaften Konfiguration
  final String configKey;

  ConfigurationException(
    super.message, {
    required this.configKey,
    super.cause,
    super.stackTrace,
  }) : super(
    code: 'CONFIG_ERROR',
    severity: ExceptionSeverity.critical,
    context: {'configKey': configKey},
  );

  factory ConfigurationException.missingApiKey(String keyName) {
    return ConfigurationException(
      'Missing required API key: $keyName',
      configKey: keyName,
    );
  }

  factory ConfigurationException.invalidConfig(String keyName, String reason) {
    return ConfigurationException(
      'Invalid configuration for $keyName: $reason',
      configKey: keyName,
    );
  }
}

// ============================================
// BUSINESS LOGIC EXCEPTIONS
// ============================================

/// Business-Logic-Fehler
/// 
/// Verwendung für:
/// - Geschäftsregel-Verletzungen
/// - Domain-spezifische Fehler
/// - State-Probleme
class BusinessLogicException extends AppException {
  /// Rule die verletzt wurde
  final String rule;

  BusinessLogicException(
    super.message, {
    required this.rule,
    super.cause,
    super.stackTrace,
  }) : super(
    code: 'BUSINESS_LOGIC_ERROR',
    severity: ExceptionSeverity.warning,
    context: {'rule': rule},
  );
}

// ============================================
// TIMEOUT EXCEPTIONS
// ============================================

/// Timeout-Fehler
/// 
/// Verwendung für:
/// - Operation-Timeouts
/// - Response-Timeouts
/// - Connection-Timeouts
class TimeoutException extends AppException {
  /// Timeout-Dauer
  final Duration timeout;
  
  /// Art der Operation die timeout hatte
  final String? operation;

  TimeoutException(
    super.message, {
    required this.timeout,
    this.operation,
    super.cause,
    super.stackTrace,
  }) : super(
    code: 'TIMEOUT_ERROR',
    severity: ExceptionSeverity.error,
    context: {
      'timeoutSeconds': timeout.inSeconds,
      if (operation != null) 'operation': operation,
    },
  );

  factory TimeoutException.operationTimeout(String operation, Duration timeout) {
    return TimeoutException(
      'Operation "$operation" timed out after ${timeout.inSeconds}s',
      timeout: timeout,
      operation: operation,
    );
  }
}
