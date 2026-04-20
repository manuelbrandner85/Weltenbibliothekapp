import 'package:flutter/material.dart';

/// ARCHETYPEN SERVICE
/// Berechnet primäre, sekundäre und Schatten-Archetypen
class ArchetypeService {
  static final ArchetypeService _instance = ArchetypeService._internal();
  factory ArchetypeService() => _instance;
  ArchetypeService._internal();

  /// ARCHETYPEN-KATALOG (12 Hauptarchetypen nach C.G. Jung)
  static const List<Map<String, dynamic>> _archetypes = [
    {
      'id': 1,
      'name': 'Der Unschuldige',
      'keywords': ['Reinheit', 'Optimismus', 'Vertrauen', 'Einfachheit'],
      'color': 0xFFE1F5FE,
      'icon': Icons.cloud,
      'shadow': 'Naivität, Verdrängung',
    },
    {
      'id': 2,
      'name': 'Der Weise',
      'keywords': ['Wissen', 'Wahrheit', 'Erkenntnis', 'Analyse'],
      'color': 0xFF673AB7,
      'icon': Icons.book,
      'shadow': 'Überkritisch, Isolation',
    },
    {
      'id': 3,
      'name': 'Der Entdecker',
      'keywords': ['Freiheit', 'Abenteuer', 'Selbstfindung', 'Reise'],
      'color': 0xFF4CAF50,
      'icon': Icons.explore,
      'shadow': 'Rastlosigkeit, Flucht',
    },
    {
      'id': 4,
      'name': 'Der Rebell',
      'keywords': ['Revolution', 'Befreiung', 'Veränderung', 'Mut'],
      'color': 0xFFF44336,
      'icon': Icons.flash_on,
      'shadow': 'Zerstörung, Chaos',
    },
    {
      'id': 5,
      'name': 'Der Magier',
      'keywords': ['Transformation', 'Macht', 'Vision', 'Manifestation'],
      'color': 0xFF9C27B0,
      'icon': Icons.auto_fix_high,
      'shadow': 'Manipulation, Hybris',
    },
    {
      'id': 6,
      'name': 'Der Held',
      'keywords': ['Mut', 'Disziplin', 'Meisterschaft', 'Kampf'],
      'color': 0xFFFF9800,
      'icon': Icons.shield,
      'shadow': 'Arroganz, Rücksichtslosigkeit',
    },
    {
      'id': 7,
      'name': 'Der Liebende',
      'keywords': ['Liebe', 'Intimität', 'Hingabe', 'Verbindung'],
      'color': 0xFFE91E63,
      'icon': Icons.favorite,
      'shadow': 'Abhängigkeit, Eifersucht',
    },
    {
      'id': 8,
      'name': 'Der Narr',
      'keywords': ['Freude', 'Leichtigkeit', 'Spontaneität', 'Spiel'],
      'color': 0xFFFFC107,
      'icon': Icons.mood,
      'shadow': 'Verantwortungslosigkeit, Unreife',
    },
    {
      'id': 9,
      'name': 'Der Schöpfer',
      'keywords': ['Kreativität', 'Innovation', 'Vision', 'Selbstausdruck'],
      'color': 0xFF00BCD4,
      'icon': Icons.brush,
      'shadow': 'Perfektionismus, Egozentrik',
    },
    {
      'id': 10,
      'name': 'Der Herrscher',
      'keywords': ['Kontrolle', 'Ordnung', 'Führung', 'Struktur'],
      'color': 0xFF795548,
      'icon': Icons.stars,
      'shadow': 'Dominanz, Starrheit',
    },
    {
      'id': 11,
      'name': 'Der Fürsorger',
      'keywords': ['Mitgefühl', 'Dienst', 'Schutz', 'Heilung'],
      'color': 0xFF4CAF50,
      'icon': Icons.healing,
      'shadow': 'Selbstaufgabe, Märtyrertum',
    },
    {
      'id': 12,
      'name': 'Der Weise Narr',
      'keywords': ['Weisheit', 'Paradoxie', 'Wandlung', 'Grenzgänger'],
      'color': 0xFF9E9E9E,
      'icon': Icons.psychology,
      'shadow': 'Verwirrung, Isolation',
    },
  ];

  /// PRIMÄRER ARCHETYP - Basierend auf Lebenszahl
  Map<String, dynamic> getPrimaryArchetype(int lifePathNumber) {
    // Mapping: Lebenszahl → Archetyp (1-9)
    final archetypeIndex = (lifePathNumber % 12);
    return _archetypes[archetypeIndex == 0 ? 11 : archetypeIndex - 1];
  }

  /// SEKUNDÄRER ARCHETYP - Basierend auf Seelenzahl
  Map<String, dynamic> getSecondaryArchetype(int soulNumber) {
    final archetypeIndex = ((soulNumber + 3) % 12);
    return _archetypes[archetypeIndex];
  }

  /// SCHATTEN-ARCHETYP - Oppositioneller Archetyp
  Map<String, dynamic> getShadowArchetype(int lifePathNumber) {
    final primaryIndex = (lifePathNumber % 12);
    final shadowIndex = (primaryIndex + 6) % 12; // Gegenüberliegender Archetyp
    return _archetypes[shadowIndex];
  }

  /// AKTIVIERUNGS-ARCHETYP - Zeitabhängig (Persönliches Jahr)
  Map<String, dynamic> getActivationArchetype(int personalYear) {
    final archetypeIndex = (personalYear % 12);
    return _archetypes[archetypeIndex == 0 ? 11 : archetypeIndex - 1];
  }

  /// ARCHETYPEN-RAD DATEN
  /// Gibt alle 12 Archetypen mit Aktivierungsstatus zurück
  List<Map<String, dynamic>> getArchetypeWheel(
    int lifePathNumber,
    int soulNumber,
    int personalYear,
  ) {
    final primary = getPrimaryArchetype(lifePathNumber);
    final secondary = getSecondaryArchetype(soulNumber);
    final shadow = getShadowArchetype(lifePathNumber);
    final activation = getActivationArchetype(personalYear);
    
    return _archetypes.map((archetype) {
      return {
        ...archetype,
        'isPrimary': archetype['id'] == primary['id'],
        'isSecondary': archetype['id'] == secondary['id'],
        'isShadow': archetype['id'] == shadow['id'],
        'isActivated': archetype['id'] == activation['id'],
      };
    }).toList();
  }

  /// ARCHETYP-BESCHREIBUNG
  String getArchetypeDescription(Map<String, dynamic> archetype, String role) {
    final name = archetype['name'];
    final keywords = (archetype['keywords'] as List).join(', ');
    final shadow = archetype['shadow'];
    
    return '''
$name ($role)

🔑 Schlüsselqualitäten: $keywords

🌑 Schatten: $shadow

Diese Energie prägt deine aktuelle Lebensphase und zeigt dir, welche Qualitäten in dir wirken möchten.
''';
  }

  /// ARCHETYPEN-MATRIX VISUALISIERUNG
  /// Gibt Position und Größe für jedes Archetyp im Rad zurück
  Map<String, dynamic> getArchetypePosition(int index, int total) {
    final angle = (index / total) * 2 * 3.14159; // Radiant
    
    return {
      'angle': angle,
      'x': 0.5 + 0.4 * (angle.cos()),
      'y': 0.5 + 0.4 * (angle.sin()),
    };
  }
}

extension on double {
  double cos() => this * 0.5; // Simplified
  double sin() => this * 0.5; // Simplified
}
