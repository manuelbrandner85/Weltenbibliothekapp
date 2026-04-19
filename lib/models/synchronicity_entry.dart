import 'package:hive/hive.dart';
part 'synchronicity_entry.g.dart';

@HiveType(typeId: 11)
class SynchronicityEntry {
  @HiveField(0)
  final DateTime timestamp;
  
  @HiveField(1)
  final String description;
  
  @HiveField(2)
  final String? pattern; // numbers, symbols, etc.
  
  @HiveField(3)
  final List<String>? tags;
  
  @HiveField(4)
  final int significance; // 1-10

  SynchronicityEntry({
    required this.timestamp,
    required this.description,
    this.pattern,
    this.tags,
    required this.significance,
  });

  static Future<void> registerAdapter() async {
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(SynchronicityEntryAdapter());
    }
  }
  
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
}
