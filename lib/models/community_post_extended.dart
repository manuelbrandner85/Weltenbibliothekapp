import 'community_post.dart';

/// 🆕 ERWEITERTE Community Post Features (v44.2.2)
/// Alle 10 neuen Features für Post-Erstellung

/// Post Visibility (Feature 4)
enum PostVisibility {
  public,    // 🌍 Alle sehen
  friends,   // 👥 Nur Follower
  private,   // 🔒 Nur ich (Entwurf)
}

/// Poll Option (Feature 2)
class PollOption {
  final String id;
  final String text;
  final int votes;
  final List<String> voters; // User IDs
  
  PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
    this.voters = const [],
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'votes': votes,
    'voters': voters,
  };
  
  factory PollOption.fromJson(Map<String, dynamic> json) => PollOption(
    id: json['id'] as String,
    text: json['text'] as String,
    votes: json['votes'] as int? ?? 0,
    voters: List<String>.from(json['voters'] ?? []),
  );
}

/// Poll Data (Feature 2)
class PollData {
  final String id;
  final List<PollOption> options;
  final DateTime? expiresAt;
  final bool allowMultipleVotes;
  final int totalVotes;
  
  PollData({
    required this.id,
    required this.options,
    this.expiresAt,
    this.allowMultipleVotes = false,
    this.totalVotes = 0,
  });
  
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'options': options.map((o) => o.toJson()).toList(),
    'expiresAt': expiresAt?.toIso8601String(),
    'allowMultipleVotes': allowMultipleVotes,
    'totalVotes': totalVotes,
  };
  
  factory PollData.fromJson(Map<String, dynamic> json) => PollData(
    id: json['id'] as String,
    options: (json['options'] as List).map((o) => PollOption.fromJson(o)).toList(),
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    allowMultipleVotes: json['allowMultipleVotes'] as bool? ?? false,
    totalVotes: json['totalVotes'] as int? ?? 0,
  );
}

/// Link Preview Data (Feature 10)
class LinkPreview {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? domain;
  
  LinkPreview({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.domain,
  });
  
  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'domain': domain,
  };
  
  factory LinkPreview.fromJson(Map<String, dynamic> json) => LinkPreview(
    url: json['url'] as String,
    title: json['title'] as String?,
    description: json['description'] as String?,
    imageUrl: json['imageUrl'] as String?,
    domain: json['domain'] as String?,
  );
}

/// 🚀 ERWEITERTE Community Post (mit allen neuen Features)
class CommunityPostExtended {
  final String id;
  final String authorUsername;
  final String? authorAvatar;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final int shares;
  final String? mediaUrl;
  final String? mediaType;
  final WorldType worldType;
  
  // 🆕 NEUE FEATURES
  final PostVisibility visibility;        // Feature 4: Reichweite
  final PollData? poll;                   // Feature 2: Umfragen
  final LinkPreview? linkPreview;         // Feature 10: Link Preview
  final List<String> mentions;            // Feature 9: @mentions
  final bool isDraft;                     // Feature 6: Entwürfe
  final DateTime? scheduledFor;           // Feature 8: Scheduled Posts
  final Map<String, dynamic>? metadata;   // Zusätzliche Daten
  
  CommunityPostExtended({
    required this.id,
    required this.authorUsername,
    this.authorAvatar,
    required this.content,
    required this.tags,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.mediaUrl,
    this.mediaType,
    required this.worldType,
    this.visibility = PostVisibility.public,
    this.poll,
    this.linkPreview,
    this.mentions = const [],
    this.isDraft = false,
    this.scheduledFor,
    this.metadata,
  });
  
  // Getter
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
  bool get hasPoll => poll != null;
  bool get hasLinkPreview => linkPreview != null;
  bool get hasMentions => mentions.isNotEmpty;
  bool get isScheduled => scheduledFor != null && DateTime.now().isBefore(scheduledFor!);
  bool get isPublished => !isDraft && !isScheduled;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'authorUsername': authorUsername,
    'authorAvatar': authorAvatar,
    'content': content,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'likes': likes,
    'comments': comments,
    'shares': shares,
    'mediaUrl': mediaUrl,
    'mediaType': mediaType,
    'worldType': worldType.name,
    'visibility': visibility.name,
    'poll': poll?.toJson(),
    'linkPreview': linkPreview?.toJson(),
    'mentions': mentions,
    'isDraft': isDraft,
    'scheduledFor': scheduledFor?.toIso8601String(),
    'metadata': metadata,
  };
  
  factory CommunityPostExtended.fromJson(Map<String, dynamic> json) {
    return CommunityPostExtended(
      id: json['id'] as String,
      authorUsername: json['authorUsername'] as String,
      authorAvatar: json['authorAvatar'] as String?,
      content: json['content'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
      shares: json['shares'] as int? ?? 0,
      mediaUrl: json['mediaUrl'] as String?,
      mediaType: json['mediaType'] as String?,
      worldType: WorldType.values.firstWhere(
        (e) => e.name == json['worldType'],
        orElse: () => WorldType.materie,
      ),
      visibility: PostVisibility.values.firstWhere(
        (e) => e.name == (json['visibility'] ?? 'public'),
        orElse: () => PostVisibility.public,
      ),
      poll: json['poll'] != null ? PollData.fromJson(json['poll']) : null,
      linkPreview: json['linkPreview'] != null ? LinkPreview.fromJson(json['linkPreview']) : null,
      mentions: List<String>.from(json['mentions'] ?? []),
      isDraft: json['isDraft'] as bool? ?? false,
      scheduledFor: json['scheduledFor'] != null ? DateTime.parse(json['scheduledFor']) : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
  
  /// Convert to basic CommunityPost (backward compatibility)
  CommunityPost toBasicPost() {
    return CommunityPost(
      id: id,
      authorUsername: authorUsername,
      authorAvatar: authorAvatar,
      content: content,
      tags: tags,
      createdAt: createdAt,
      likes: likes,
      comments: comments,
      shares: shares,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      worldType: worldType,
    );
  }
}

/// Draft Post (Feature 6: Entwürfe speichern)
class DraftPost {
  final String id;
  final String content;
  final List<String> tags;
  final String? mediaUrl;
  final String? mediaType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final WorldType worldType;
  final PostVisibility visibility;
  final PollData? poll;
  
  DraftPost({
    required this.id,
    required this.content,
    required this.tags,
    this.mediaUrl,
    this.mediaType,
    required this.createdAt,
    required this.updatedAt,
    required this.worldType,
    this.visibility = PostVisibility.public,
    this.poll,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'tags': tags,
    'mediaUrl': mediaUrl,
    'mediaType': mediaType,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'worldType': worldType.name,
    'visibility': visibility.name,
    'poll': poll?.toJson(),
  };
  
  factory DraftPost.fromJson(Map<String, dynamic> json) => DraftPost(
    id: json['id'] as String,
    content: json['content'] as String,
    tags: List<String>.from(json['tags'] ?? []),
    mediaUrl: json['mediaUrl'] as String?,
    mediaType: json['mediaType'] as String?,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    worldType: WorldType.values.firstWhere((e) => e.name == json['worldType']),
    visibility: PostVisibility.values.firstWhere(
      (e) => e.name == (json['visibility'] ?? 'public'),
      orElse: () => PostVisibility.public,
    ),
    poll: json['poll'] != null ? PollData.fromJson(json['poll']) : null,
  );
}
