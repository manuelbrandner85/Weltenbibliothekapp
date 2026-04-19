import 'package:hive/hive.dart';

part 'consciousness_entry.g.dart';

@HiveType(typeId: 10)
class ConsciousnessEntry {
  @HiveField(0)
  final DateTime timestamp;
  
  @HiveField(1)
  final String activityType; // meditation, mantra, tarot, etc.
  
  @HiveField(2)
  final int duration; // minutes
  
  @HiveField(3)
  final int moodBefore; // 1-10
  
  @HiveField(4)
  final int moodAfter; // 1-10
  
  @HiveField(5)
  final String? notes;
  
  @HiveField(6)
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
  
  static Future<void> registerAdapter() async {
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(ConsciousnessEntryAdapter());
    }
  }
}
