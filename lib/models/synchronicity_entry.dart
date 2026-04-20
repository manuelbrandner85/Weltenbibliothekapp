class SynchronicityEntry {
  final DateTime timestamp;
  final String description;
  final String? pattern; // numbers, symbols, etc.
  final List<String>? tags;
  final int significance; // 1-10

  SynchronicityEntry({
    required this.timestamp,
    required this.description,
    this.pattern,
    this.tags,
    required this.significance,
  });

  static List<String> detectPatterns(String text) {
    final patterns = <String>[];
    if (RegExp(r'11:11|22:22|333|444|555|666|777|888|999').hasMatch(text)) {
      patterns.add('Engelszahlen');
    }
    if (RegExp(r'13|7|3').hasMatch(text)) {
      patterns.add('Magische Zahlen');
    }
    return patterns;
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'description': description,
        'pattern': pattern,
        'tags': tags,
        'significance': significance,
      };

  factory SynchronicityEntry.fromJson(Map<String, dynamic> json) => SynchronicityEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        description: json['description'] as String,
        pattern: json['pattern'] as String?,
        tags: (json['tags'] as List?)?.cast<String>(),
        significance: json['significance'] as int,
      );
}
