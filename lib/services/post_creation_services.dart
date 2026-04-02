import 'package:flutter/foundation.dart';

/// 🚀 POST CREATION HELPER SERVICES
/// Alle Services für die 10 neuen Features

/// ═══════════════════════════════════════════════════════════════════════════
/// FEATURE 1: EMOJI PICKER - Emoji Categories & Data
/// ═══════════════════════════════════════════════════════════════════════════

class EmojiService {
  static const Map<String, List<String>> emojiCategories = {
    'Smileys': ['😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚', '😋'],
    'Gesten': ['👋', '🤚', '🖐', '✋', '🖖', '👌', '🤌', '🤏', '✌', '🤞', '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝', '👍'],
    'Herzen': ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟'],
    'Symbole': ['✨', '⭐', '🌟', '💫', '✅', '❌', '🔥', '💧', '🌈', '☀️', '🌙', '⚡', '☁️', '🌸', '🌺', '🌻', '🌹', '🌷', '🌼'],
    'Objekte': ['📱', '💻', '⌚', '📷', '📚', '📖', '✏️', '📝', '🎨', '🎭', '🎪', '🎬', '🎵', '🎸', '🎹', '🎺', '🎻', '🥁', '🎮'],
  };
  
  static List<String> getAllEmojis() {
    return emojiCategories.values.expand((list) => list).toList();
  }
  
  static List<String> getFrequentEmojis() {
    // TODO: Load from user preferences
    return ['😀', '❤️', '👍', '🔥', '✨', '🎉', '💯', '👏'];
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FEATURE 7: HASHTAG SUGGESTIONS - Trending & Popular Tags
/// ═══════════════════════════════════════════════════════════════════════════

class HashtagService {
  // Trending Hashtags (kann später aus Analytics kommen)
  static const Map<String, List<String>> trendingTags = {
    'energie': [
      'Spiritualität', 'Meditation', 'Chakra', 'Energie', 'Bewusstsein',
      'Transformation', 'Heilung', 'Manifestation', 'Achtsamkeit', 'Yoga',
    ],
    'materie': [
      'Forschung', 'Wissenschaft', 'Technologie', 'Innovation', 'Geopolitik',
      'Wirtschaft', 'Bildung', 'Gesellschaft', 'Umwelt', 'Zukunft',
    ],
  };
  
  static List<String> getTrendingTags(String worldType) {
    return trendingTags[worldType] ?? [];
  }
  
  static List<String> searchTags(String query, String worldType) {
    if (query.isEmpty) return getTrendingTags(worldType);
    
    final allTags = getTrendingTags(worldType);
    return allTags
        .where((tag) => tag.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
  
  static String formatTag(String tag) {
    // Entferne # wenn vorhanden, füge es dann wieder hinzu
    final clean = tag.replaceAll('#', '').trim();
    return clean.isEmpty ? '' : '#$clean';
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FEATURE 9: MENTION SYSTEM - User Search & Autocomplete
/// ═══════════════════════════════════════════════════════════════════════════

class MentionService {
  // Mock user database (später aus Firestore)
  static const List<Map<String, String>> mockUsers = [
    {'username': 'ManuelBrandner', 'avatar': '👨‍💼'},
    {'username': 'SarahMueller', 'avatar': '👩‍🔬'},
    {'username': 'MaxSchmidt', 'avatar': '👨‍🎓'},
    {'username': 'LisaWagner', 'avatar': '👩‍💻'},
    {'username': 'TomBecker', 'avatar': '👨‍🏫'},
  ];
  
  static List<Map<String, String>> searchUsers(String query) {
    if (query.isEmpty) return mockUsers.take(5).toList();
    
    return mockUsers
        .where((user) => user['username']!.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();
  }
  
  static List<String> extractMentions(String text) {
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }
  
  static String formatMention(String username) {
    return '@$username';
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FEATURE 10: LINK PREVIEW - URL Metadata Extraction
/// ═══════════════════════════════════════════════════════════════════════════

class LinkPreviewService {
  static final RegExp _urlRegex = RegExp(
    r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
    caseSensitive: false,
  );
  
  static List<String> extractUrls(String text) {
    final matches = _urlRegex.allMatches(text);
    return matches.map((m) => m.group(0)!).toList();
  }
  
  static Future<Map<String, dynamic>?> fetchLinkPreview(String url) async {
    try {
      // Simplified - in production use a proper metadata extraction service
      final uri = Uri.parse(url);
      
      // Mock data for demo (später echte API verwenden)
      return {
        'url': url,
        'title': 'Link Preview',
        'description': 'Beschreibung des Links...',
        'imageUrl': null,
        'domain': uri.host,
      };
      
      // Production: Use meta scraping API oder og:tags parsen
      // final response = await http.get(Uri.parse(url));
      // return _parseMetadata(response.body);
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Link preview error: $e');
      }
      return null;
    }
  }
  
  static String getDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return url;
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FEATURE 5: IMAGE EDITOR - Filter & Transform Helpers
/// ═══════════════════════════════════════════════════════════════════════════

class ImageEditorService {
  static const List<Map<String, dynamic>> filters = [
    {'name': 'Original', 'icon': '🖼️'},
    {'name': 'B&W', 'icon': '⬛'},
    {'name': 'Vintage', 'icon': '📷'},
    {'name': 'Warm', 'icon': '🔥'},
    {'name': 'Cool', 'icon': '❄️'},
    {'name': 'Bright', 'icon': '☀️'},
  ];
  
  // Diese Methoden würden mit image_editor Package implementiert
  static Future<dynamic> cropImage(dynamic imageFile) async {
    // TODO: Implement with image_cropper package
    return imageFile;
  }
  
  static Future<dynamic> applyFilter(dynamic imageFile, String filterName) async {
    // TODO: Implement with image package filters
    return imageFile;
  }
  
  static Future<dynamic> addText(dynamic imageFile, String text) async {
    // TODO: Implement text overlay
    return imageFile;
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FEATURE 6 & 8: DRAFT & SCHEDULED POSTS - Storage Service
/// ═══════════════════════════════════════════════════════════════════════════

class DraftService {
  // Diese würden mit Hive/Firestore implementiert
  
  static Future<void> saveDraft(Map<String, dynamic> draftData) async {
    // TODO: Save to Hive post_drafts box
    if (kDebugMode) {
      debugPrint('💾 Draft saved: ${draftData['content']}');
    }
  }
  
  static Future<List<Map<String, dynamic>>> getDrafts(String worldType) async {
    // TODO: Load from Hive
    return [];
  }
  
  static Future<void> deleteDraft(String draftId) async {
    // TODO: Delete from Hive
  }
  
  static Future<void> schedulePost(Map<String, dynamic> postData, DateTime scheduledFor) async {
    // TODO: Save to scheduled_posts box
    // TODO: Set up background notification/service
    if (kDebugMode) {
      debugPrint('⏰ Post scheduled for: $scheduledFor');
    }
  }
  
  static Future<List<Map<String, dynamic>>> getScheduledPosts(String worldType) async {
    // TODO: Load from Hive
    return [];
  }
}
