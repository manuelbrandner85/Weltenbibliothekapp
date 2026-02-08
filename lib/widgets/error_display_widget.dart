/// 🎨 WELTENBIBLIOTHEK - ERROR DISPLAY WIDGET
/// Professional error handling with retry functionality

import 'package:flutter/material.dart';

class ErrorDisplayWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final IconData? errorIcon;
  final Color? backgroundColor;

  const ErrorDisplayWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.retryButtonText = 'Erneut versuchen',
    this.errorIcon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Determine error type and styling
    final bool isNetworkError = error.contains('Internetverbindung') || 
                                 error.contains('Network') ||
                                 error.contains('Verbindung');
    
    final bool isServerError = error.contains('Server') ||
                               error.contains('503') ||
                               error.contains('502');
    
    final IconData displayIcon = errorIcon ?? 
        (isNetworkError ? Icons.wifi_off : 
         isServerError ? Icons.cloud_off : 
         Icons.error_outline);
    
    final Color displayColor = isNetworkError ? Colors.orange :
                               isServerError ? Colors.red :
                               Colors.red.shade400;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon with Animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  displayIcon,
                  size: 64,
                  color: displayColor,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Error Title
            Text(
              _getErrorTitle(error),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Error Message
            Text(
              _getErrorMessage(error),
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              
              // Retry Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryButtonText!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: displayColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ],
            
            // Help Text
            if (isNetworkError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tipp: Überprüfe deine WLAN- oder Mobile Datenverbindung',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getErrorTitle(String error) {
    if (error.contains('Internetverbindung') || error.contains('Network')) {
      return '⚠️ Keine Verbindung';
    } else if (error.contains('Server') || error.contains('503') || error.contains('502')) {
      return '🔧 Server-Problem';
    } else if (error.contains('401') || error.contains('Authentifizierung')) {
      return '🔐 Authentifizierung fehlgeschlagen';
    } else if (error.contains('403') || error.contains('Zugriff verweigert')) {
      return '🚫 Zugriff verweigert';
    } else if (error.contains('404') || error.contains('nicht gefunden')) {
      return '🔍 Nicht gefunden';
    } else {
      return '❌ Fehler aufgetreten';
    }
  }

  String _getErrorMessage(String error) {
    // Remove technical details in parentheses for user display
    final cleanError = error.split('(').first.trim();
    
    if (cleanError.isEmpty || cleanError.length < 10) {
      return error; // Show full error if too short
    }
    
    return cleanError;
  }
}


/// 🎨 LOADING STATE WIDGET
/// Professional skeleton loader with shimmer effect

class LoadingStateWidget extends StatefulWidget {
  final String? message;
  final bool showProgress;

  const LoadingStateWidget({
    super.key,
    this.message,
    this.showProgress = false,
  });

  @override
  State<LoadingStateWidget> createState() => _LoadingStateWidgetState();
}

class _LoadingStateWidgetState extends State<LoadingStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Loading Indicator
          RotationTransition(
            turns: _controller,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF9B59B6),
                    const Color(0xFF8E44AD),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9B59B6).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          
          if (widget.message != null) ...[
            const SizedBox(height: 24),
            Text(
              widget.message!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          if (widget.showProgress) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF9B59B6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


/// 🎨 EMPTY STATE WIDGET
/// Professional empty state with action button

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (onAction != null && actionText != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B59B6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
