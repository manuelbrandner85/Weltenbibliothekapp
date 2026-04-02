import 'package:flutter/foundation.dart';
import 'openclaw_gateway_service.dart';
import 'cloudflare_api_service.dart';

/// 🤖 AI Service Manager mit automatischem Fallback
/// 
/// Versucht zuerst OpenClaw (Hostinger VPS),
/// fällt bei Nichtverfügbarkeit auf Cloudflare AI zurück
class AIServiceManager {
  final OpenClawGatewayService _openClaw = OpenClawGatewayService();
  final CloudflareApiService _cloudflare = CloudflareApiService();
  
  // Singleton
  static final AIServiceManager _instance = AIServiceManager._internal();
  factory AIServiceManager() => _instance;
  AIServiceManager._internal();
  
  // Cache für Verfügbarkeit (30 Sekunden)
  DateTime? _lastCheck;
  bool? _openClawAvailable;
  static const Duration _checkCacheDuration = Duration(seconds: 30);
  
  // ═══════════════════════════════════════════════════════════
  // SMART AI SERVICE SELECTION
  // ═══════════════════════════════════════════════════════════
  
  /// Prüft ob OpenClaw verfügbar ist (mit Caching)
  Future<bool> get isOpenClawAvailable async {
    // Cache-Check
    if (_lastCheck != null && 
        _openClawAvailable != null &&
        DateTime.now().difference(_lastCheck!) < _checkCacheDuration) {
      return _openClawAvailable!;
    }
    
    // Neue Prüfung
    _openClawAvailable = await _openClaw.isAvailable();
    _lastCheck = DateTime.now();
    
    if (_openClawAvailable!) {
      debugPrint('✅ OpenClaw AI verfügbar (Hostinger VPS)');
    } else {
      debugPrint('⚠️ OpenClaw nicht verfügbar, nutze Cloudflare Fallback');
    }
    
    return _openClawAvailable!;
  }
  
  // ═══════════════════════════════════════════════════════════
  // RECHERCHE
  // ═══════════════════════════════════════════════════════════
  
  /// Recherche mit Auto-Fallback
  Future<Map<String, dynamic>> research({
    required String query,
    List<String> sources = const ['official', 'alternative'],
    int maxResults = 10,
  }) async {
    try {
      if (await isOpenClawAvailable) {
        return await _openClaw.research(
          query: query,
          sources: sources,
          maxResults: maxResults,
        );
      }
    } catch (e) {
      debugPrint('⚠️ OpenClaw research failed, using Cloudflare: $e');
    }
    
    // Fallback to Cloudflare
    final articles = await _cloudflare.search(query: query);
    return {
      'results': articles,
      'source': 'cloudflare',
      'query': query,
    };
  }
  
  // ═══════════════════════════════════════════════════════════
  // PROPAGANDA-DETEKTOR
  // ═══════════════════════════════════════════════════════════
  
  /// Propaganda-Analyse mit Auto-Fallback
  Future<Map<String, dynamic>> detectPropaganda({
    required String text,
  }) async {
    try {
      if (await isOpenClawAvailable) {
        return await _openClaw.detectPropaganda(text: text);
      }
    } catch (e) {
      debugPrint('⚠️ OpenClaw propaganda detection failed, using fallback: $e');
    }
    
    // Simple Fallback (kann später durch Cloudflare AI ersetzt werden)
    return {
      'analysis': 'Propaganda-Analyse-Fehler. Bitte versuche es später erneut.',
      'score': 50,
      'techniques': [],
      'source': 'fallback',
      'error': 'OpenClaw nicht verfügbar',
    };
  }
  
  // ═══════════════════════════════════════════════════════════
  // TRAUM-ANALYSE
  // ═══════════════════════════════════════════════════════════
  
  /// Traum-Analyse mit Auto-Fallback
  Future<Map<String, dynamic>> analyzeDream({
    required String dreamText,
    String? mood,
    List<String>? symbols,
  }) async {
    try {
      if (await isOpenClawAvailable) {
        return await _openClaw.analyzeDream(
          dreamText: dreamText,
          mood: mood,
          symbols: symbols,
        );
      }
    } catch (e) {
      debugPrint('⚠️ OpenClaw dream analysis failed, using fallback: $e');
    }
    
    // Fallback: Basic-Analyse
    return {
      'analysis': 'Traum-Analyse erfordert OpenClaw AI. Bitte konfiguriere OpenClaw auf deinem Hostinger VPS.',
      'symbols': symbols ?? [],
      'chakras': [],
      'source': 'fallback',
      'error': 'OpenClaw nicht verfügbar',
    };
  }
  
  // ═══════════════════════════════════════════════════════════
  // CHAKRA-EMPFEHLUNGEN
  // ═══════════════════════════════════════════════════════════
  
  /// Chakra-Empfehlungen mit Auto-Fallback
  Future<Map<String, dynamic>> getChakraRecommendations({
    required String chakra,
    List<String>? symptoms,
    String? intention,
  }) async {
    try {
      if (await isOpenClawAvailable) {
        return await _openClaw.getChakraRecommendations(
          chakra: chakra,
          symptoms: symptoms,
          intention: intention,
        );
      }
    } catch (e) {
      debugPrint('⚠️ OpenClaw chakra recommendations failed, using fallback: $e');
    }
    
    // Fallback: Basic recommendations
    return _getBasicChakraRecommendations(chakra);
  }
  
  /// Basis Chakra-Empfehlungen (Fallback)
  Map<String, dynamic> _getBasicChakraRecommendations(String chakra) {
    final recommendations = {
      'Wurzelchakra': {
        'stones': ['Roter Jaspis', 'Hämatit', 'Schwarzer Turmalin'],
        'frequency': '396 Hz',
        'color': 'Rot',
        'affirmation': 'Ich bin sicher und geerdet.',
      },
      'Sakralchakra': {
        'stones': ['Karneol', 'Orangencalcit', 'Mondstein'],
        'frequency': '417 Hz',
        'color': 'Orange',
        'affirmation': 'Ich lasse meine Kreativität fließen.',
      },
      'Solarplexuschakra': {
        'stones': ['Citrin', 'Tigerauge', 'Bernstein'],
        'frequency': '528 Hz',
        'color': 'Gelb',
        'affirmation': 'Ich bin voller Kraft und Selbstvertrauen.',
      },
      'Herzchakra': {
        'stones': ['Rosenquarz', 'Grüner Aventurin', 'Jade'],
        'frequency': '639 Hz',
        'color': 'Grün/Rosa',
        'affirmation': 'Ich öffne mein Herz für bedingungslose Liebe.',
      },
      'Halschakra': {
        'stones': ['Blauer Chalcedon', 'Aquamarin', 'Türkis'],
        'frequency': '741 Hz',
        'color': 'Blau',
        'affirmation': 'Ich kommuniziere klar und authentisch.',
      },
      'Stirnchakra': {
        'stones': ['Lapislazuli', 'Amethyst', 'Sodalith'],
        'frequency': '852 Hz',
        'color': 'Indigo',
        'affirmation': 'Ich vertraue meiner Intuition.',
      },
      'Kronenchakra': {
        'stones': ['Bergkristall', 'Amethyst', 'Selenit'],
        'frequency': '963 Hz',
        'color': 'Violett/Weiß',
        'affirmation': 'Ich bin verbunden mit dem Universum.',
      },
    };
    
    return {
      'recommendations': recommendations[chakra] ?? recommendations['Herzchakra'],
      'chakra': chakra,
      'source': 'fallback',
      'note': 'Für detaillierte Empfehlungen, konfiguriere OpenClaw AI.',
    };
  }
  
  // ═══════════════════════════════════════════════════════════
  // MEDITATION-GENERATOR
  // ═══════════════════════════════════════════════════════════
  
  /// Meditation-Generator mit Auto-Fallback
  Future<Map<String, dynamic>> generateMeditation({
    required String intention,
    int duration = 10,
    String? chakra,
    String? theme,
  }) async {
    try {
      if (await isOpenClawAvailable) {
        return await _openClaw.generateMeditation(
          intention: intention,
          duration: duration,
          chakra: chakra,
          theme: theme,
        );
      }
    } catch (e) {
      debugPrint('⚠️ OpenClaw meditation generation failed, using fallback: $e');
    }
    
    // Fallback: Basic meditation script
    return {
      'script': _getBasicMeditationScript(intention, duration),
      'duration': duration,
      'intention': intention,
      'source': 'fallback',
      'note': 'Für personalisierte Meditationen, konfiguriere OpenClaw AI.',
    };
  }
  
  String _getBasicMeditationScript(String intention, int duration) {
    return '''
Geführte Meditation ($duration Minuten): $intention

1. Vorbereitung (2 Min)
Setze dich bequem hin, schließe die Augen.
Atme tief durch die Nase ein, durch den Mund aus.
Wiederhole dies 5 Mal.

2. Körper-Scan (3 Min)
Spüre deinen Körper von Kopf bis Fuß.
Entspanne jeden Bereich bewusst.

3. Visualisierung (${duration - 6} Min)
Stelle dir vor: $intention
Fühle, wie sich diese Vision manifestiert.

4. Integration (1 Min)
Bring deine Aufmerksamkeit zurück in den Raum.
Öffne langsam die Augen.
''';
  }
  
  // ═══════════════════════════════════════════════════════════
  // CHAT ENHANCEMENT
  // ═══════════════════════════════════════════════════════════
  
  /// Smart Reply Suggestions
  Future<List<String>> getSuggestedReplies({
    required String message,
    String? context,
    int maxSuggestions = 3,
  }) async {
    try {
      if (await isOpenClawAvailable) {
        return await _openClaw.getSuggestedReplies(
          message: message,
          context: context,
          maxSuggestions: maxSuggestions,
        );
      }
    } catch (e) {
      debugPrint('⚠️ OpenClaw suggested replies failed: $e');
    }
    
    // Fallback: Keine Vorschläge
    return [];
  }
  
  // ═══════════════════════════════════════════════════════════
  // STATUS & DEBUGGING
  // ═══════════════════════════════════════════════════════════
  
  /// System Status abrufen
  Future<Map<String, dynamic>> getSystemStatus() async {
    final openClawStatus = await _openClaw.getStatus();
    
    return {
      'openclaw': {
        'available': await isOpenClawAvailable,
        'url': OpenClawGatewayService.gatewayUrl,
        'status': openClawStatus,
      },
      'cloudflare': {
        'available': true,
        'url': CloudflareApiService.baseUrl,
      },
      'active_service': await isOpenClawAvailable ? 'openclaw' : 'cloudflare',
    };
  }
  
  /// Cache zurücksetzen
  void resetCache() {
    _lastCheck = null;
    _openClawAvailable = null;
  }
}
