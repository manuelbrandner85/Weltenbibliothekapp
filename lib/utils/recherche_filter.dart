/// WELTENBIBLIOTHEK v5.5 – FILTER-MODELL
/// 
/// Filter für Recherche-Ergebnisse nach:
/// - Quellen-Typen (Web, Dokumente, Medien, Timeline)
/// - Tiefe/Detail-Level (1-5)
library;

class RechercheFilter {
  final Set<String> enabledSources;
  final int maxDepth;
  
  const RechercheFilter({
    this.enabledSources = const {'web', 'documents', 'media', 'timeline'},
    this.maxDepth = 5,
  });
  
  /// Kopiert den Filter mit neuen Werten
  RechercheFilter copyWith({
    Set<String>? enabledSources,
    int? maxDepth,
  }) {
    return RechercheFilter(
      enabledSources: enabledSources ?? this.enabledSources,
      maxDepth: maxDepth ?? this.maxDepth,
    );
  }
  
  /// Ist der Filter aktiv? (von Standard abweichend)
  bool get isActive {
    return enabledSources.length < 4 || maxDepth < 5;
  }
  
  /// Anzahl aktiver Filter
  int get activeCount {
    int count = 0;
    if (enabledSources.length < 4) count++;
    if (maxDepth < 5) count++;
    return count;
  }
  
  /// Filtert eine Liste von Daten-Items
  List<Map<String, dynamic>> apply(List<Map<String, dynamic>> items) {
    return items.where((item) {
      // Quellen-Filter
      final type = item['type'] as String?;
      if (type != null && !enabledSources.contains(type.toLowerCase())) {
        return false;
      }
      
      // Tiefe-Filter
      final depth = item['depth'] as int? ?? 1;
      if (depth > maxDepth) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  /// Filtert Timeline-Events
  List<Map<String, dynamic>> applyToTimeline(List<Map<String, dynamic>> events) {
    return events.where((event) {
      final depth = event['importance'] as int? ?? 1;
      return depth <= maxDepth;
    }).toList();
  }
  
  /// Filtert strukturierte Daten (v5.4)
  Map<String, dynamic> applyToStructured(Map<String, dynamic> structured) {
    final filtered = <String, dynamic>{};
    
    // Faktenbasis durchfiltern
    if (structured.containsKey('faktenbasis')) {
      final fb = structured['faktenbasis'] as Map<String, dynamic>;
      filtered['faktenbasis'] = _filterByDepth(fb, maxDepth);
    }
    
    // Sichtweisen durchfiltern
    for (final key in ['sichtweise1_offiziell', 'sichtweise2_alternativ']) {
      if (structured.containsKey(key)) {
        filtered[key] = structured[key]; // Sichtweisen immer behalten
      }
    }
    
    // Vergleich durchfiltern
    if (structured.containsKey('vergleich')) {
      filtered['vergleich'] = structured['vergleich'];
    }
    
    return filtered;
  }
  
  /// Filtert Map nach Tiefe (rekursiv)
  Map<String, dynamic> _filterByDepth(Map<String, dynamic> data, int maxDepth) {
    final filtered = <String, dynamic>{};
    
    data.forEach((key, value) {
      if (value is List) {
        // Listen auf maxDepth begrenzen
        filtered[key] = value.take(maxDepth * 2).toList();
      } else if (value is Map) {
        // Verschachtelte Maps rekursiv filtern
        filtered[key] = _filterByDepth(value as Map<String, dynamic>, maxDepth);
      } else {
        filtered[key] = value;
      }
    });
    
    return filtered;
  }
  
  /// Standard-Filter (alle Quellen, maximale Tiefe)
  factory RechercheFilter.all() {
    return const RechercheFilter(
      enabledSources: {'web', 'documents', 'media', 'timeline'},
      maxDepth: 5,
    );
  }
  
  /// Nur Web-Quellen
  factory RechercheFilter.webOnly() {
    return const RechercheFilter(
      enabledSources: {'web'},
      maxDepth: 5,
    );
  }
  
  /// Nur Dokumente
  factory RechercheFilter.documentsOnly() {
    return const RechercheFilter(
      enabledSources: {'documents'},
      maxDepth: 5,
    );
  }
  
  /// Schneller Überblick (Tiefe 2)
  factory RechercheFilter.overview() {
    return const RechercheFilter(
      enabledSources: {'web', 'documents', 'media', 'timeline'},
      maxDepth: 2,
    );
  }
  
  /// Tiefe Analyse (Tiefe 5)
  factory RechercheFilter.deep() {
    return const RechercheFilter(
      enabledSources: {'web', 'documents', 'media', 'timeline'},
      maxDepth: 5,
    );
  }
}
