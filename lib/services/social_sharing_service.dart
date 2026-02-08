// =====================================================================
// SOCIAL SHARING SERVICE v1.0
// =====================================================================
// Comprehensive social media sharing service
// Features:
// - Multiple platforms (WhatsApp, Telegram, Twitter, Facebook, Email)
// - Custom share templates
// - Share tracking
// - Referral system
// =====================================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

// =====================================================================
// SHARE PLATFORM
// =====================================================================

enum SharePlatform {
  whatsapp,
  telegram,
  twitter,
  facebook,
  email,
  copy,
}

extension SharePlatformExtension on SharePlatform {
  String get label {
    switch (this) {
      case SharePlatform.whatsapp:
        return 'WhatsApp';
      case SharePlatform.telegram:
        return 'Telegram';
      case SharePlatform.twitter:
        return 'Twitter';
      case SharePlatform.facebook:
        return 'Facebook';
      case SharePlatform.email:
        return 'Email';
      case SharePlatform.copy:
        return 'Link kopieren';
    }
  }

  String get icon {
    switch (this) {
      case SharePlatform.whatsapp:
        return '💬';
      case SharePlatform.telegram:
        return '✈️';
      case SharePlatform.twitter:
        return '🐦';
      case SharePlatform.facebook:
        return '📘';
      case SharePlatform.email:
        return '📧';
      case SharePlatform.copy:
        return '🔗';
    }
  }

  String get color {
    switch (this) {
      case SharePlatform.whatsapp:
        return '#25D366';
      case SharePlatform.telegram:
        return '#0088CC';
      case SharePlatform.twitter:
        return '#1DA1F2';
      case SharePlatform.facebook:
        return '#4267B2';
      case SharePlatform.email:
        return '#EA4335';
      case SharePlatform.copy:
        return '#757575';
    }
  }
}

// =====================================================================
// SHARE RECORD
// =====================================================================

class ShareRecord {
  final String id;
  final SharePlatform platform;
  final String contentType; // 'narrative', 'achievement', 'profile'
  final String contentId;
  final DateTime sharedAt;

  ShareRecord({
    required this.id,
    required this.platform,
    required this.contentType,
    required this.contentId,
    required this.sharedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'platform': platform.toString(),
        'contentType': contentType,
        'contentId': contentId,
        'sharedAt': sharedAt.toIso8601String(),
      };

  factory ShareRecord.fromJson(Map<String, dynamic> json) => ShareRecord(
        id: json['id'] as String,
        platform: SharePlatform.values.firstWhere(
          (e) => e.toString() == json['platform'],
        ),
        contentType: json['contentType'] as String,
        contentId: json['contentId'] as String,
        sharedAt: DateTime.parse(json['sharedAt'] as String),
      );
}

// =====================================================================
// SOCIAL SHARING SERVICE
// =====================================================================

class SocialSharingService {
  static final SocialSharingService _instance = SocialSharingService._internal();
  factory SocialSharingService() => _instance;
  SocialSharingService._internal();

  static const String _shareHistoryKey = 'share_history';
  static const String _referralCountKey = 'referral_count';
  static const String _baseUrl = 'https://weltenbibliothek.app'; // Production URL

  SharedPreferences? _prefs;
  List<ShareRecord> _shareHistory = [];
  int _referralCount = 0;

  // =====================================================================
  // INITIALIZATION
  // =====================================================================

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadShareHistory();
      _referralCount = _prefs?.getInt(_referralCountKey) ?? 0;
      
      if (kDebugMode) {
        print('✅ SocialSharingService initialized');
        print('   📊 Total shares: ${_shareHistory.length}');
        print('   👥 Referrals: $_referralCount');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SocialSharingService init error: $e');
      }
    }
  }

  // =====================================================================
  // SHARE METHODS
  // =====================================================================

  Future<bool> shareNarrative({
    required String narrativeId,
    required String narrativeTitle,
    required SharePlatform platform,
  }) async {
    final shareUrl = '$_baseUrl/narrative/$narrativeId';
    final shareText = '📖 $narrativeTitle\n\nEntdecke diese faszinierende Geschichte in der Weltenbibliothek!';
    
    return await _share(
      platform: platform,
      text: shareText,
      url: shareUrl,
      contentType: 'narrative',
      contentId: narrativeId,
    );
  }

  Future<bool> shareAchievement({
    required String achievementId,
    required String achievementName,
    required SharePlatform platform,
  }) async {
    final shareUrl = '$_baseUrl/achievements';
    final shareText = '🏆 Ich habe "$achievementName" freigeschaltet!\n\nSchau dir meine Erfolge in der Weltenbibliothek an!';
    
    return await _share(
      platform: platform,
      text: shareText,
      url: shareUrl,
      contentType: 'achievement',
      contentId: achievementId,
    );
  }

  Future<bool> shareProfile({
    required String username,
    required int level,
    required int achievementCount,
    required SharePlatform platform,
  }) async {
    final shareUrl = '$_baseUrl/profile';
    final shareText = '👤 $username - Level $level\n🏆 $achievementCount Achievements\n\nSieh dir mein Profil in der Weltenbibliothek an!';
    
    return await _share(
      platform: platform,
      text: shareText,
      url: shareUrl,
      contentType: 'profile',
      contentId: username,
    );
  }

  Future<bool> shareApp({
    required SharePlatform platform,
  }) async {
    final shareUrl = _baseUrl;
    final shareText = '📚 Entdecke die Weltenbibliothek!\n\nEine App voller faszinierender Geschichten, Geheimnisse und Wissen aus aller Welt. 🌍';
    
    return await _share(
      platform: platform,
      text: shareText,
      url: shareUrl,
      contentType: 'app',
      contentId: 'weltenbibliothek',
    );
  }

  // =====================================================================
  // CORE SHARE LOGIC
  // =====================================================================

  Future<bool> _share({
    required SharePlatform platform,
    required String text,
    required String url,
    required String contentType,
    required String contentId,
  }) async {
    try {
      String shareUrl;
      
      switch (platform) {
        case SharePlatform.whatsapp:
          shareUrl = 'https://wa.me/?text=${Uri.encodeComponent('$text\n\n$url')}';
          break;
          
        case SharePlatform.telegram:
          shareUrl = 'https://t.me/share/url?url=${Uri.encodeComponent(url)}&text=${Uri.encodeComponent(text)}';
          break;
          
        case SharePlatform.twitter:
          shareUrl = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(text)}&url=${Uri.encodeComponent(url)}';
          break;
          
        case SharePlatform.facebook:
          shareUrl = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}';
          break;
          
        case SharePlatform.email:
          shareUrl = 'mailto:?subject=${Uri.encodeComponent('Weltenbibliothek')}&body=${Uri.encodeComponent('$text\n\n$url')}';
          break;
          
        case SharePlatform.copy:
          // For copy, return false to trigger clipboard copy in UI
          return false;
      }

      final uri = Uri.parse(shareUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Track share
        await _trackShare(platform, contentType, contentId);
        
        if (kDebugMode) {
          print('✅ Shared $contentType via ${platform.label}');
        }
        
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Cannot launch $shareUrl');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Share error: $e');
      }
      return false;
    }
  }

  // =====================================================================
  // TRACKING
  // =====================================================================

  Future<void> _trackShare(
    SharePlatform platform,
    String contentType,
    String contentId,
  ) async {
    try {
      final record = ShareRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        platform: platform,
        contentType: contentType,
        contentId: contentId,
        sharedAt: DateTime.now(),
      );

      _shareHistory.add(record);
      await _saveShareHistory();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Track share error: $e');
      }
    }
  }

  Future<void> _loadShareHistory() async {
    try {
      final historyJson = _prefs?.getString(_shareHistoryKey);
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        _shareHistory = decoded.map((json) => ShareRecord.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Load share history error: $e');
      }
    }
  }

  Future<void> _saveShareHistory() async {
    try {
      final historyJson = json.encode(
        _shareHistory.map((r) => r.toJson()).toList(),
      );
      await _prefs?.setString(_shareHistoryKey, historyJson);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Save share history error: $e');
      }
    }
  }

  // =====================================================================
  // REFERRAL SYSTEM
  // =====================================================================

  Future<void> incrementReferralCount() async {
    try {
      _referralCount++;
      await _prefs?.setInt(_referralCountKey, _referralCount);
      
      if (kDebugMode) {
        print('👥 Referral count: $_referralCount');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Increment referral error: $e');
      }
    }
  }

  // =====================================================================
  // GETTERS & STATS
  // =====================================================================

  List<ShareRecord> get shareHistory => _shareHistory;
  int get totalShares => _shareHistory.length;
  int get referralCount => _referralCount;

  Map<SharePlatform, int> get sharesByPlatform {
    final Map<SharePlatform, int> counts = {};
    for (var platform in SharePlatform.values) {
      counts[platform] = _shareHistory
          .where((r) => r.platform == platform)
          .length;
    }
    return counts;
  }

  Map<String, int> get sharesByContentType {
    final Map<String, int> counts = {};
    for (var record in _shareHistory) {
      counts[record.contentType] = (counts[record.contentType] ?? 0) + 1;
    }
    return counts;
  }

  List<ShareRecord> getRecentShares({int limit = 10}) {
    final sorted = _shareHistory.toList()
      ..sort((a, b) => b.sharedAt.compareTo(a.sharedAt));
    return sorted.take(limit).toList();
  }
}
