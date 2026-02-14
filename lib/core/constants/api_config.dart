/// 🌐 API CONFIGURATION
/// 
/// Central configuration for all API endpoints

class ApiConfig {
  // Private constructor
  ApiConfig._();

  /// Cloudflare Worker Base URL
  static const String baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';
  
  /// API Timeout
  static const Duration timeout = Duration(seconds: 30);
  
  /// Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
