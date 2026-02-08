/// Check-In Model für besuchte Orte
class CheckIn {
  final String id;
  final String locationId; // Marker ID
  final String locationName;
  final String category; // z.B. 'kraftort', 'ley_line'
  final DateTime timestamp;
  final String? notes;
  final String worldType; // 'materie' oder 'energie'

  CheckIn({
    required this.id,
    required this.locationId,
    required this.locationName,
    required this.category,
    required this.timestamp,
    this.notes,
    required this.worldType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'locationId': locationId,
      'locationName': locationName,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'worldType': worldType,
    };
  }

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'] as String,
      locationId: json['locationId'] as String,
      locationName: json['locationName'] as String,
      category: json['category'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
      worldType: json['worldType'] as String,
    );
  }
}
