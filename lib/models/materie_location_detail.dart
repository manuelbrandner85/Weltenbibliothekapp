import 'package:latlong2/latlong.dart';
import 'location_category.dart';

/// Detaillierte Location-Information für Materie-Weltkarte
/// 
/// Enthält alle Informationen zu einem Location-Marker:
/// - Basis-Infos (Name, Beschreibung, Position)
/// - Kategorisierung (category, keywords, date)
/// - Medien (Bilder, Videos, Quellen)
/// - Alternative Sichtweisen (official/alternative/evidence)
class MaterieLocationDetail {
  final String name;
  final String description;
  final String detailedInfo;
  final LatLng position;
  final LocationCategory category;
  final List<String> keywords;
  final DateTime? date;
  final List<String> imageUrls;
  final List<String> videoUrls; // YouTube Video IDs
  final List<String> sources;
  
  // 🔥 NEUE FELDER: Alternative Sichtweisen
  final String? officialNarrative;    // Offizielle Version/Mainstream-Narrative
  final String? alternativeView;      // Alternative/Verschwörungstheoretische Sichtweise
  final String? evidence;             // Beweise/Indizien für alternative Sichtweise

  const MaterieLocationDetail({
    required this.name,
    required this.description,
    required this.detailedInfo,
    required this.position,
    required this.category,
    this.keywords = const [],
    this.date,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.sources = const [],
    this.officialNarrative,
    this.alternativeView,
    this.evidence,
  });
}
