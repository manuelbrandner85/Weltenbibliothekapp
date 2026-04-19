import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 🌐 CORS-Proxy Service - Ermöglicht RSS-Feeds auf Web-Plattform
/// 
/// PROBLEM: Direkter RSS-Feed-Zugriff auf Web wird durch CORS blockiert
/// LÖSUNG: Nutze öffentliche CORS-Proxy-Services für Web, direkt für Mobile
class CORSProxyService {
  static const List<String> _corsProxies = [
    'https://api.allorigins.win/raw?url=',
    'https://corsproxy.io/?',
    'https://api.codetabs.com/v1/proxy?quest=',
  ];
  
  static int _currentProxyIndex = 0;
  static final http.Client _client = http.Client();
  
  /// Holt RSS-Feed-Inhalt mit CORS-Umgehung auf Web
  static Future<String> fetchFeed(String feedUrl) async {
    // Auf nativen Plattformen (Android/iOS) - direkter Zugriff
    if (!kIsWeb) {
      try {
        final response = await _client.get(
          Uri.parse(feedUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (compatible; WeltenbibliothekBot/1.0)',
          },
        ).timeout(const Duration(seconds: 15));
        
        if (response.statusCode == 200) {
          return response.body;
        }
        throw Exception('HTTP ${response.statusCode}');
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Direkter Feed-Zugriff fehlgeschlagen: $e');
        }
        rethrow;
      }
    }
    
    // Auf Web - nutze CORS-Proxy mit Fallback-Strategie
    for (int attempt = 0; attempt < _corsProxies.length; attempt++) {
      final proxyUrl = _corsProxies[_currentProxyIndex] + Uri.encodeComponent(feedUrl);
      
      try {
        if (kDebugMode) {
          debugPrint('🌐 Versuche CORS-Proxy ${_currentProxyIndex + 1}/${_corsProxies.length}: $_corsProxies[_currentProxyIndex]');
        }
        
        final response = await _client.get(
          Uri.parse(proxyUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'application/xml, text/xml, */*',
          },
        ).timeout(const Duration(seconds: 20));
        
        if (response.statusCode == 200) {
          if (kDebugMode) {
            debugPrint('✅ CORS-Proxy erfolgreich! Bytes: ${response.body.length}');
          }
          return response.body;
        }
        
        if (kDebugMode) {
          debugPrint('⚠️ CORS-Proxy HTTP ${response.statusCode}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ CORS-Proxy Fehler: $e');
        }
      }
      
      // Wechsle zum nächsten Proxy bei Fehler
      _currentProxyIndex = (_currentProxyIndex + 1) % _corsProxies.length;
    }
    
    throw Exception('Alle CORS-Proxies fehlgeschlagen für: $feedUrl');
  }
  
  /// Testet verfügbare CORS-Proxies (optional beim App-Start)
  static Future<void> testProxies() async {
    const testUrl = 'https://www.sciencedaily.com/rss/all.xml';
    
    for (int i = 0; i < _corsProxies.length; i++) {
      final proxyUrl = _corsProxies[i] + Uri.encodeComponent(testUrl);
      
      try {
        final response = await _client.get(Uri.parse(proxyUrl))
          .timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          if (kDebugMode) {
            debugPrint('✅ Proxy $i funktioniert: ${_corsProxies[i]}');
          }
          _currentProxyIndex = i;
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Proxy $i fehlgeschlagen: ${_corsProxies[i]}');
        }
      }
    }
  }
}
