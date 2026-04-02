// =====================================================================
// USER CONTENT SERVICE v1.0
// =====================================================================
// User-generated content management
// Features:
// - Create narratives
// - Draft system
// - Submission queue
// - Moderation status
// - User profiles
// =====================================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// =====================================================================
// CONTENT STATUS
// =====================================================================

enum ContentStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected,
  published,
}

extension ContentStatusExtension on ContentStatus {
  String get label {
    switch (this) {
      case ContentStatus.draft:
        return 'Entwurf';
      case ContentStatus.submitted:
        return 'Eingereicht';
      case ContentStatus.underReview:
        return 'In Prüfung';
      case ContentStatus.approved:
        return 'Genehmigt';
      case ContentStatus.rejected:
        return 'Abgelehnt';
      case ContentStatus.published:
        return 'Veröffentlicht';
    }
  }

  String get icon {
    switch (this) {
      case ContentStatus.draft:
        return '📝';
      case ContentStatus.submitted:
        return '📤';
      case ContentStatus.underReview:
        return '🔍';
      case ContentStatus.approved:
        return '✅';
      case ContentStatus.rejected:
        return '❌';
      case ContentStatus.published:
        return '🌟';
    }
  }
}

// =====================================================================
// USER NARRATIVE
// =====================================================================

class UserNarrative {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String description;
  final String content;
  final String category;
  final List<String> tags;
  final ContentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? rejectionReason;
  final int views;
  final int likes;

  UserNarrative({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.description,
    required this.content,
    required this.category,
    required this.tags,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.rejectionReason,
    this.views = 0,
    this.likes = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'title': title,
        'description': description,
        'content': content,
        'category': category,
        'tags': tags,
        'status': status.toString(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'rejectionReason': rejectionReason,
        'views': views,
        'likes': likes,
      };

  factory UserNarrative.fromJson(Map<String, dynamic> json) => UserNarrative(
        id: json['id'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        content: json['content'] as String,
        category: json['category'] as String,
        tags: List<String>.from(json['tags'] as List),
        status: ContentStatus.values.firstWhere(
          (e) => e.toString() == json['status'],
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        rejectionReason: json['rejectionReason'] as String?,
        views: json['views'] as int? ?? 0,
        likes: json['likes'] as int? ?? 0,
      );

  UserNarrative copyWith({
    String? title,
    String? description,
    String? content,
    String? category,
    List<String>? tags,
    ContentStatus? status,
    String? rejectionReason,
    int? views,
    int? likes,
  }) =>
      UserNarrative(
        id: id,
        authorId: authorId,
        authorName: authorName,
        title: title ?? this.title,
        description: description ?? this.description,
        content: content ?? this.content,
        category: category ?? this.category,
        tags: tags ?? this.tags,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        rejectionReason: rejectionReason ?? this.rejectionReason,
        views: views ?? this.views,
        likes: likes ?? this.likes,
      );
}

// =====================================================================
// USER CONTENT SERVICE
// =====================================================================

class UserContentService {
  static final UserContentService _instance = UserContentService._internal();
  factory UserContentService() => _instance;
  UserContentService._internal();

  static const String _narrativesKey = 'user_narratives';
  static const String _currentUserId = 'user_manuel';
  static const String _currentUserName = 'Manuel';

  SharedPreferences? _prefs;
  List<UserNarrative> _narratives = [];

  // Available categories
  static const List<String> categories = [
    'Geschichte',
    'Wissenschaft',
    'Mysterien',
    'Kultur',
    'Technologie',
    'Natur',
    'Philosophie',
    'Kunst',
  ];

  // =====================================================================
  // INITIALIZATION
  // =====================================================================

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadNarratives();
      
      if (kDebugMode) {
        print('✅ UserContentService initialized');
        print('   📝 Total narratives: ${_narratives.length}');
        print('   📤 Drafts: ${_getDraftCount()}');
        print('   🌟 Published: ${_getPublishedCount()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ UserContentService init error: $e');
      }
    }
  }

  // =====================================================================
  // CRUD OPERATIONS
  // =====================================================================

  Future<UserNarrative> createNarrative({
    required String title,
    required String description,
    required String content,
    required String category,
    required List<String> tags,
  }) async {
    try {
      final narrative = UserNarrative(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        authorId: _currentUserId,
        authorName: _currentUserName,
        title: title,
        description: description,
        content: content,
        category: category,
        tags: tags,
        status: ContentStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _narratives.add(narrative);
      await _saveNarratives();

      if (kDebugMode) {
        print('✅ Narrative created: ${narrative.title}');
      }

      return narrative;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Create narrative error: $e');
      }
      rethrow;
    }
  }

  Future<void> updateNarrative(UserNarrative narrative) async {
    try {
      final index = _narratives.indexWhere((n) => n.id == narrative.id);
      if (index != -1) {
        _narratives[index] = narrative;
        await _saveNarratives();

        if (kDebugMode) {
          print('✅ Narrative updated: ${narrative.title}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Update narrative error: $e');
      }
    }
  }

  Future<void> deleteNarrative(String narrativeId) async {
    try {
      _narratives.removeWhere((n) => n.id == narrativeId);
      await _saveNarratives();

      if (kDebugMode) {
        print('✅ Narrative deleted: $narrativeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Delete narrative error: $e');
      }
    }
  }

  // =====================================================================
  // STATUS CHANGES
  // =====================================================================

  Future<void> submitNarrative(String narrativeId) async {
    try {
      final narrative = _narratives.firstWhere((n) => n.id == narrativeId);
      final updated = narrative.copyWith(status: ContentStatus.submitted);
      await updateNarrative(updated);

      if (kDebugMode) {
        print('✅ Narrative submitted: ${narrative.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Submit narrative error: $e');
      }
    }
  }

  Future<void> approveNarrative(String narrativeId) async {
    try {
      final narrative = _narratives.firstWhere((n) => n.id == narrativeId);
      final updated = narrative.copyWith(status: ContentStatus.approved);
      await updateNarrative(updated);

      if (kDebugMode) {
        print('✅ Narrative approved: ${narrative.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Approve narrative error: $e');
      }
    }
  }

  Future<void> rejectNarrative(String narrativeId, String reason) async {
    try {
      final narrative = _narratives.firstWhere((n) => n.id == narrativeId);
      final updated = narrative.copyWith(
        status: ContentStatus.rejected,
        rejectionReason: reason,
      );
      await updateNarrative(updated);

      if (kDebugMode) {
        print('❌ Narrative rejected: ${narrative.title}');
        print('   Reason: $reason');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Reject narrative error: $e');
      }
    }
  }

  Future<void> publishNarrative(String narrativeId) async {
    try {
      final narrative = _narratives.firstWhere((n) => n.id == narrativeId);
      final updated = narrative.copyWith(status: ContentStatus.published);
      await updateNarrative(updated);

      if (kDebugMode) {
        print('🌟 Narrative published: ${narrative.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Publish narrative error: $e');
      }
    }
  }

  // =====================================================================
  // DATA PERSISTENCE
  // =====================================================================

  Future<void> _loadNarratives() async {
    try {
      final narrativesJson = _prefs?.getString(_narrativesKey);
      if (narrativesJson != null) {
        final List<dynamic> decoded = json.decode(narrativesJson);
        _narratives = decoded.map((json) => UserNarrative.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Load narratives error: $e');
      }
    }
  }

  Future<void> _saveNarratives() async {
    try {
      final narrativesJson = json.encode(
        _narratives.map((n) => n.toJson()).toList(),
      );
      await _prefs?.setString(_narrativesKey, narrativesJson);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Save narratives error: $e');
      }
    }
  }

  // =====================================================================
  // QUERIES & GETTERS
  // =====================================================================

  List<UserNarrative> get allNarratives => _narratives;

  List<UserNarrative> get myNarratives =>
      _narratives.where((n) => n.authorId == _currentUserId).toList();

  List<UserNarrative> getNarrativesByStatus(ContentStatus status) =>
      _narratives.where((n) => n.status == status).toList();

  List<UserNarrative> getDrafts() =>
      _narratives.where((n) => n.status == ContentStatus.draft).toList();

  List<UserNarrative> getPublished() =>
      _narratives.where((n) => n.status == ContentStatus.published).toList();

  UserNarrative? getNarrativeById(String id) {
    try {
      return _narratives.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  int _getDraftCount() =>
      _narratives.where((n) => n.status == ContentStatus.draft).length;

  int _getPublishedCount() =>
      _narratives.where((n) => n.status == ContentStatus.published).length;

  // =====================================================================
  // STATS
  // =====================================================================

  Map<String, dynamic> getStats() {
    return {
      'total': _narratives.length,
      'drafts': _getDraftCount(),
      'submitted': _narratives.where((n) => n.status == ContentStatus.submitted).length,
      'underReview': _narratives.where((n) => n.status == ContentStatus.underReview).length,
      'approved': _narratives.where((n) => n.status == ContentStatus.approved).length,
      'rejected': _narratives.where((n) => n.status == ContentStatus.rejected).length,
      'published': _getPublishedCount(),
      'totalViews': _narratives.fold<int>(0, (sum, n) => sum + n.views),
      'totalLikes': _narratives.fold<int>(0, (sum, n) => sum + n.likes),
    };
  }
}
