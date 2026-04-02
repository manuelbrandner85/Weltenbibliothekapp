class ContentItem {
  final String contentId;
  final String world;
  final String authorUsername;
  final String authorUserId;
  final String title;
  final String body;
  final String contentType;
  final String? category;
  final bool isFeatured;
  final bool isVerified;
  final String? verifiedBy;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentItem({
    required this.contentId,
    required this.world,
    required this.authorUsername,
    required this.authorUserId,
    required this.title,
    required this.body,
    this.contentType = 'story',
    this.category,
    this.isFeatured = false,
    this.isVerified = false,
    this.verifiedBy,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      contentId: json['content_id'] ?? '',
      world: json['world'] ?? '',
      authorUsername: json['author_username'] ?? '',
      authorUserId: json['author_user_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      contentType: json['content_type'] ?? 'story',
      category: json['category'],
      isFeatured: (json['is_featured'] ?? 0) == 1,
      isVerified: (json['is_verified'] ?? 0) == 1,
      verifiedBy: json['verified_by'],
      viewCount: json['view_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content_id': contentId,
      'world': world,
      'author_username': authorUsername,
      'author_user_id': authorUserId,
      'title': title,
      'body': body,
      'content_type': contentType,
      'category': category,
      'is_featured': isFeatured ? 1 : 0,
      'is_verified': isVerified ? 1 : 0,
      'verified_by': verifiedBy,
      'view_count': viewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
