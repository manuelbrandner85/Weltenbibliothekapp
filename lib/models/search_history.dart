/// Search History Entry v8.0
///
/// Stores search queries with metadata for quick access
class SearchHistoryEntry {
  String id;
  String query;
  DateTime timestamp;
  int resultCount;
  String? summary;
  List<String>? tags;
  Map<String, dynamic>? metadata;

  SearchHistoryEntry({
    required this.id,
    required this.query,
    required this.timestamp,
    this.resultCount = 0,
    this.summary,
    this.tags,
    this.metadata,
  });

  // JSON Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'timestamp': timestamp.toIso8601String(),
      'resultCount': resultCount,
      'summary': summary,
      'tags': tags,
      'metadata': metadata,
    };
  }

  factory SearchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SearchHistoryEntry(
      id: json['id'] as String,
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      resultCount: json['resultCount'] as int? ?? 0,
      summary: json['summary'] as String?,
      tags: (json['tags'] as List?)?.cast<String>(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Display formatted date
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Gerade eben';
    } else if (diff.inMinutes < 60) {
      return 'Vor ${diff.inMinutes} Min';
    } else if (diff.inHours < 24) {
      return 'Vor ${diff.inHours} Std';
    } else if (diff.inDays < 7) {
      return 'Vor ${diff.inDays} Tagen';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }
}
