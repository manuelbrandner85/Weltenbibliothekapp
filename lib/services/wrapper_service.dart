/// Wrapper Service für Telegram, External Links und Media Proxy
/// Weltenbibliothek V2.4 - Link Management
class WrapperService {
  static const String _baseUrl = 'https://weltenbibliothek-api-v2.brandy13062.workers.dev';

  // ==========================================
  // #22 - TELEGRAM LINK WRAPPER
  // ==========================================

  /// Wrapped Telegram-Link erstellen
  /// Beispiel: wrapTelegramLink('great_reset_watch')
  /// → https://weltenbibliothek-api-v2.brandy13062.workers.dev/go/tg/great_reset_watch
  static String wrapTelegramLink(String username) {
    // Entferne @ falls vorhanden
    final cleanUsername = username.replaceAll('@', '');
    return '$_baseUrl/go/tg/$cleanUsername';
  }

  /// Direkter Telegram-Link (ohne Wrapper)
  /// Beispiel: directTelegramLink('great_reset_watch')
  /// → https://t.me/great_reset_watch
  static String directTelegramLink(String username) {
    final cleanUsername = username.replaceAll('@', '');
    return 'https://t.me/$cleanUsername';
  }

  // ==========================================
  // #23 - EXTERNAL LINK WRAPPER
  // ==========================================

  /// Wrapped External-Link erstellen
  /// Beispiel: wrapExternalLink('https://example.com')
  /// → https://weltenbibliothek-api-v2.brandy13062.workers.dev/out?url=https%3A%2F%2Fexample.com
  static String wrapExternalLink(String url) {
    final encodedUrl = Uri.encodeComponent(url);
    return '$_baseUrl/out?url=$encodedUrl';
  }

  // ==========================================
  // #24 - MEDIA PROXY
  // ==========================================

  /// Media-Proxy-Link erstellen
  /// Beispiel: proxyMediaLink('https://example.com/image.jpg')
  /// → https://weltenbibliothek-api-v2.brandy13062.workers.dev/media?src=https%3A%2F%2Fexample.com%2Fimage.jpg
  static String proxyMediaLink(String mediaUrl) {
    final encodedUrl = Uri.encodeComponent(mediaUrl);
    return '$_baseUrl/media?src=$encodedUrl';
  }

  // ==========================================
  // UTILITY FUNCTIONS
  // ==========================================

  /// Prüft ob URL ein Telegram-Link ist
  static bool isTelegramLink(String url) {
    return url.contains('t.me/') || url.contains('telegram.me/');
  }

  /// Extrahiert Telegram-Username aus URL
  /// Beispiel: 'https://t.me/great_reset_watch' → 'great_reset_watch'
  static String? extractTelegramUsername(String url) {
    final regex = RegExp(r't\.me/([a-zA-Z0-9_]+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  /// Prüft ob URL external ist (nicht weltenbibliothek.com)
  static bool isExternalLink(String url) {
    return !url.contains('weltenbibliothek.com') && 
           !url.contains('weltenbibliothek-api') &&
           !url.contains('brandy13062.workers.dev');
  }

  /// Automatischer Wrapper für beliebige URLs
  /// Wählt automatisch den richtigen Wrapper-Typ
  static String autoWrap(String url) {
    if (isTelegramLink(url)) {
      final username = extractTelegramUsername(url);
      if (username != null) {
        return wrapTelegramLink(username);
      }
    }
    
    if (isExternalLink(url)) {
      return wrapExternalLink(url);
    }
    
    // Internal link - no wrapping needed
    return url;
  }

  /// Batch-Wrapping für Liste von URLs
  static List<String> wrapMultiple(List<String> urls) {
    return urls.map((url) => autoWrap(url)).toList();
  }

  // ==========================================
  // TELEGRAM CHANNEL LISTE (aus Recherche)
  // ==========================================

  /// Vordefinierte Telegram-Kanäle aus Research API
  static const Map<String, List<Map<String, String>>> telegramChannels = {
    'alternative_medien': [
      {'name': 'Great Reset Watch', 'username': 'great_reset_watch'},
      {'name': 'NWO Widerstand', 'username': 'nwo_widerstand'},
      {'name': 'Freie Medien', 'username': 'freiemedien'},
    ],
    'geopolitik': [
      {'name': 'Geopolitik DE', 'username': 'geopolitik_de'},
      {'name': 'Weltordnung Analyse', 'username': 'weltordnung'},
    ],
    'gesundheit': [
      {'name': 'Impfschaden Deutschland', 'username': 'impfschaden_d'},
      {'name': 'Corona Ausschuss', 'username': 'corona_ausschuss'},
      {'name': 'Samuel Eckert', 'username': 'samueleckert'},
    ],
    'verschwoerungen': [
      {'name': 'Q Research Germany', 'username': 'qresearch_germany'},
      {'name': 'Deepstate Exposed', 'username': 'deepstate_exposed'},
    ],
    'wirtschaft': [
      {'name': 'Great Reset News', 'username': 'great_reset_news'},
      {'name': 'Finanz Crash Info', 'username': 'finanzcrash'},
    ],
  };

  /// Hole Wrapped Links für eine Kategorie
  static List<Map<String, String>> getWrappedChannels(String category) {
    final channels = telegramChannels[category] ?? [];
    return channels.map((channel) {
      return {
        'name': channel['name']!,
        'username': channel['username']!,
        'wrapped_url': wrapTelegramLink(channel['username']!),
        'direct_url': directTelegramLink(channel['username']!),
      };
    }).toList();
  }
}
