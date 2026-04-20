class ConsciousnessEntry {
  final DateTime timestamp;
  final String activityType; // meditation, mantra, tarot, etc.
  final int duration; // minutes
  final int moodBefore; // 1-10
  final int moodAfter; // 1-10
  final String? notes;
  final List<String>? tags;

  ConsciousnessEntry({
    required this.timestamp,
    required this.activityType,
    required this.duration,
    required this.moodBefore,
    required this.moodAfter,
    this.notes,
    this.tags,
  });

  int get moodImprovement => moodAfter - moodBefore;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'activityType': activityType,
        'duration': duration,
        'moodBefore': moodBefore,
        'moodAfter': moodAfter,
        'notes': notes,
        'tags': tags,
      };

  factory ConsciousnessEntry.fromJson(Map<String, dynamic> json) => ConsciousnessEntry(
        timestamp: DateTime.parse(json['timestamp'] as String),
        activityType: json['activityType'] as String,
        duration: json['duration'] as int,
        moodBefore: json['moodBefore'] as int,
        moodAfter: json['moodAfter'] as int,
        notes: json['notes'] as String?,
        tags: (json['tags'] as List?)?.cast<String>(),
      );
}
