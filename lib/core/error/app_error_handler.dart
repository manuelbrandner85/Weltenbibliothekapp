import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Zentrale Error-Handling-Klasse.
///
/// Mappt Exceptions auf benutzerfreundliche deutsche Meldungen und zeigt
/// sie als SnackBar an. Ersetzt die vier alten Muster (try/catch + debugPrint,
/// try/catch + SnackBar, Error-State-Flag, kein try/catch).
///
/// Verwendung:
/// ```dart
/// try {
///   await service.doSomething();
/// } catch (e, st) {
///   AppErrorHandler.handle(context, e, stackTrace: st);
/// }
/// ```
class AppErrorHandler {
  AppErrorHandler._();

  /// Behandelt einen beliebigen Fehler und zeigt eine SnackBar an.
  ///
  /// - [context]: Kontext für die SnackBar (wenn null → nur Logging).
  /// - [error]: Die Exception / das Objekt aus dem `catch`-Block.
  /// - [stackTrace]: Optional, für Debug-Ausgabe.
  /// - [fallbackMessage]: Wenn gesetzt, überschreibt die automatische Meldung.
  static void handle(
    BuildContext? context,
    Object error, {
    StackTrace? stackTrace,
    String? fallbackMessage,
  }) {
    final message = fallbackMessage ?? _mapToUserMessage(error);

    if (kDebugMode) {
      debugPrint('⚠️ [AppErrorHandler] $error');
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }

    if (context == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _severityColor(error),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Gibt die benutzerfreundliche Meldung zurück ohne SnackBar anzuzeigen.
  /// Nützlich für Error-State-Widgets.
  static String messageFor(Object error) => _mapToUserMessage(error);

  // ── Mapping ────────────────────────────────────────────────────────────

  static String _mapToUserMessage(Object error) {
    // Netzwerk / Connectivity
    if (error is SocketException) return 'Keine Verbindung';
    if (error is HttpException) return 'Keine Verbindung';

    // Timeout
    if (error is TimeoutException) return 'Zeitüberschreitung, erneut versuchen';

    // Supabase Auth
    if (error is AuthException) return 'Bitte erneut anmelden';

    // Supabase Postgrest / Storage / generic
    if (error is PostgrestException) {
      if (error.code == 'PGRST301' || error.code == '401') {
        return 'Bitte erneut anmelden';
      }
      return 'Etwas ist schiefgelaufen';
    }
    if (error is StorageException) return 'Etwas ist schiefgelaufen';

    // Strings & generic
    final raw = error.toString().toLowerCase();
    if (raw.contains('timeout') || raw.contains('timed out')) {
      return 'Zeitüberschreitung, erneut versuchen';
    }
    if (raw.contains('socketexception') ||
        raw.contains('no internet') ||
        raw.contains('failed host lookup') ||
        raw.contains('connection')) {
      return 'Keine Verbindung';
    }
    if (raw.contains('nicht eingeloggt') ||
        raw.contains('unauthorized') ||
        raw.contains('invalid jwt') ||
        raw.contains('jwt expired')) {
      return 'Bitte erneut anmelden';
    }

    return 'Etwas ist schiefgelaufen';
  }

  static Color _severityColor(Object error) {
    if (error is AuthException) return Colors.orange.shade800;
    if (error is SocketException ||
        error is TimeoutException ||
        error is HttpException) {
      return Colors.blueGrey.shade700;
    }
    return Colors.red.shade700;
  }
}
