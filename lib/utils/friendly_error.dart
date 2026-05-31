// friendlyError -- mappt rohe Exceptions auf user-freundliche deutsche
// Meldungen.
//
// FIX (#10): Vorher landeten an einigen Stellen rohe Exception-Texte
// ("SocketException: Failed host lookup ...", Stacktraces) direkt in
// SnackBars. Das verwirrt User. Dieser Helper uebersetzt die haeufigsten
// Fehlerklassen in klare Saetze.
//
// Verwendung:
//   } catch (e) {
//     showSnack(friendlyError(e));
//   }

import 'dart:async';
import 'dart:io' if (dart.library.html) '../stubs/dart_io_stub.dart';

import '../services/admin_api_client.dart';

String friendlyError(Object? e, {String fallback = 'Etwas ist schiefgelaufen. Bitte spaeter erneut versuchen.'}) {
  if (e == null) return fallback;

  // Eigene typisierte Fehler haben schon gute Messages.
  if (e is AdminApiException) return e.userMessage;

  final s = e.toString().toLowerCase();

  if (e is TimeoutException || s.contains('timeout') || s.contains('timed out')) {
    return 'Zeitueberschreitung -- der Server antwortet gerade nicht. '
        'Bitte erneut versuchen.';
  }
  if (e is SocketException ||
      s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('network is unreachable') ||
      s.contains('connection refused') ||
      s.contains('connection closed')) {
    return 'Keine Internetverbindung. Bitte WLAN/Mobilfunk pruefen.';
  }
  if (s.contains('403') || s.contains('forbidden') || s.contains('unauthorized') || s.contains('401')) {
    return 'Keine Berechtigung. Bitte App neu starten und anmelden.';
  }
  if (s.contains('404') || s.contains('not found')) {
    return 'Inhalt nicht gefunden.';
  }
  if (s.contains('429') || s.contains('rate')) {
    return 'Zu viele Anfragen -- bitte kurz warten.';
  }
  if (s.contains('500') || s.contains('502') || s.contains('503') || s.contains('504')) {
    return 'Server-Fehler. Bitte spaeter erneut versuchen.';
  }
  if (e is FormatException || s.contains('formatexception')) {
    return 'Daten konnten nicht verarbeitet werden.';
  }
  if (e is TlsException || s.contains('handshake') || s.contains('certificate')) {
    return 'Sichere Verbindung fehlgeschlagen.';
  }

  return fallback;
}
