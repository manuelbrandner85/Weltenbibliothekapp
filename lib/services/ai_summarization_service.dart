import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

/// 🤖 KI SUMMARIZATION SERVICE
/// Generates AI-powered summaries using Cloudflare AI Worker
/// Uses LLaMA 3.1 for intelligent text summarization
class AiSummarizationService {
  static const String _summaryEndpoint = '/ai/summarize';
  static const int _maxInputLength = 5000; // Max characters for summarization
  
  /// Generate TL;DR summary (3-5 sentences)
  Future<String> generateTLDR(String text) async {
    if (text.trim().isEmpty) {
      return 'Kein Text verfügbar.';
    }
    
    try {
      // Truncate if too long
      final input = text.length > _maxInputLength 
          ? text.substring(0, _maxInputLength) 
          : text;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$_summaryEndpoint'),
        headers: {
          ...ApiConfig.headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': input,
          'mode': 'tldr',
          'language': 'de',
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['summary'] as String;
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [AI SUMMARY] Error generating TL;DR: $e');
      }
      // FALLBACK: Generate simple summary
      return _generateFallbackSummary(text);
    }
  }
  
  /// Generate bullet-point summary
  Future<List<String>> generateBulletPoints(String text, {int maxPoints = 5}) async {
    if (text.trim().isEmpty) {
      return ['Kein Text verfügbar.'];
    }
    
    try {
      // Truncate if too long
      final input = text.length > _maxInputLength 
          ? text.substring(0, _maxInputLength) 
          : text;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$_summaryEndpoint'),
        headers: {
          ...ApiConfig.headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': input,
          'mode': 'bullets',
          'language': 'de',
          'max_points': maxPoints,
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final points = data['bullet_points'] as List;
          return points.cast<String>();
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [AI SUMMARY] Error generating bullet points: $e');
      }
      // FALLBACK: Generate simple bullet points
      return _generateFallbackBulletPoints(text, maxPoints);
    }
  }
  
  /// Generate key insights (advanced)
  Future<Map<String, dynamic>> generateKeyInsights(String text) async {
    if (text.trim().isEmpty) {
      return {
        'main_topic': 'Unbekannt',
        'key_points': ['Kein Text verfügbar.'],
        'entities': [],
      };
    }
    
    try {
      // Truncate if too long
      final input = text.length > _maxInputLength 
          ? text.substring(0, _maxInputLength) 
          : text;
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$_summaryEndpoint'),
        headers: {
          ...ApiConfig.headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': input,
          'mode': 'insights',
          'language': 'de',
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'main_topic': data['main_topic'] ?? 'Unbekannt',
            'key_points': (data['key_points'] as List?)?.cast<String>() ?? [],
            'entities': (data['entities'] as List?)?.cast<String>() ?? [],
          };
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [AI SUMMARY] Error generating key insights: $e');
      }
      // FALLBACK: Generate simple insights
      return {
        'main_topic': 'Analyse nicht verfügbar',
        'key_points': _generateFallbackBulletPoints(text, 3),
        'entities': <String>[],
      };
    }
  }
  
  /// FALLBACK: Simple summary (first 3 sentences)
  String _generateFallbackSummary(String text) {
    // Split into sentences
    final sentences = text.split(RegExp(r'[.!?]'));
    final filtered = sentences
        .where((s) => s.trim().isNotEmpty && s.trim().length > 20)
        .take(3)
        .toList();
    
    if (filtered.isEmpty) {
      return 'Zusammenfassung nicht verfügbar.';
    }
    
    return filtered.join('. ') + '.';
  }
  
  /// FALLBACK: Simple bullet points (split by paragraphs)
  List<String> _generateFallbackBulletPoints(String text, int maxPoints) {
    // Split into paragraphs
    final paragraphs = text.split('\n');
    final filtered = paragraphs
        .where((p) => p.trim().isNotEmpty && p.trim().length > 30)
        .take(maxPoints)
        .map((p) => p.trim().substring(0, p.trim().length > 100 ? 100 : p.trim().length) + '...')
        .toList();
    
    if (filtered.isEmpty) {
      return ['Keine Stichpunkte verfügbar.'];
    }
    
    return filtered;
  }
}
