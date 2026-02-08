/// Frequency Preset Model for Healing Frequencies
class FrequencyPreset {
  final String id;
  final String name;
  final String description;
  final double frequency; // in Hz
  final String category; // 'solfeggio', 'chakra', 'planetary', 'binaural'
  final String benefit;
  final String icon;
  final List<String> keywords;

  FrequencyPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.frequency,
    required this.category,
    required this.benefit,
    required this.icon,
    required this.keywords,
  });

  static List<FrequencyPreset> getAllPresets() {
    return [
      // SOLFEGGIO FREQUENCIES
      FrequencyPreset(
        id: 'solfeggio_174',
        name: '174 Hz',
        description: 'Fundament & Sicherheit',
        frequency: 174.0,
        category: 'solfeggio',
        benefit: 'Schmerzlinderung, Sicherheitsgefühl, Erdung',
        icon: '🔵',
        keywords: ['schmerz', 'sicherheit', 'erdung', 'fundament'],
      ),
      FrequencyPreset(
        id: 'solfeggio_285',
        name: '285 Hz',
        description: 'Energetische Heilung',
        frequency: 285.0,
        category: 'solfeggio',
        benefit: 'Geweberegeneration, energetische Felder heilen',
        icon: '🟢',
        keywords: ['heilung', 'regeneration', 'energie'],
      ),
      FrequencyPreset(
        id: 'solfeggio_396',
        name: '396 Hz',
        description: 'Befreiung von Angst',
        frequency: 396.0,
        category: 'solfeggio',
        benefit: 'Löst Angst, Schuld und negative Blockaden',
        icon: '🔴',
        keywords: ['angst', 'schuld', 'blockaden', 'befreiung'],
      ),
      FrequencyPreset(
        id: 'solfeggio_417',
        name: '417 Hz',
        description: 'Veränderung & Transformation',
        frequency: 417.0,
        category: 'solfeggio',
        benefit: 'Negative Energien auflösen, Neuanfang',
        icon: '🟠',
        keywords: ['veränderung', 'transformation', 'neuanfang'],
      ),
      FrequencyPreset(
        id: 'solfeggio_528',
        name: '528 Hz - DNA-Frequenz',
        description: 'Liebe & Heilung',
        frequency: 528.0,
        category: 'solfeggio',
        benefit: 'DNA-Reparatur, Herzöffnung, tiefe Heilung',
        icon: '💚',
        keywords: ['liebe', 'dna', 'heilung', 'herz', 'wunder'],
      ),
      FrequencyPreset(
        id: 'solfeggio_639',
        name: '639 Hz',
        description: 'Beziehungen & Kommunikation',
        frequency: 639.0,
        category: 'solfeggio',
        benefit: 'Harmonische Beziehungen, Verständnis',
        icon: '💙',
        keywords: ['beziehung', 'kommunikation', 'harmonie'],
      ),
      FrequencyPreset(
        id: 'solfeggio_741',
        name: '741 Hz',
        description: 'Ausdruck & Lösungen',
        frequency: 741.0,
        category: 'solfeggio',
        benefit: 'Intuition, Problemlösung, Entgiftung',
        icon: '💜',
        keywords: ['intuition', 'lösungen', 'entgiftung'],
      ),
      FrequencyPreset(
        id: 'solfeggio_852',
        name: '852 Hz',
        description: 'Spirituelle Ordnung',
        frequency: 852.0,
        category: 'solfeggio',
        benefit: 'Drittes Auge aktivieren, spirituelles Erwachen',
        icon: '🔮',
        keywords: ['spirituell', 'drittes auge', 'erwachen'],
      ),
      FrequencyPreset(
        id: 'solfeggio_963',
        name: '963 Hz - Kronenchakra',
        description: 'Göttliche Verbindung',
        frequency: 963.0,
        category: 'solfeggio',
        benefit: 'Kronenchakra, Einheitsbewusstsein',
        icon: '👑',
        keywords: ['krone', 'göttlich', 'einheit', 'erleuchtung'],
      ),

      // CHAKRA FREQUENCIES
      FrequencyPreset(
        id: 'chakra_root',
        name: 'Wurzelchakra',
        description: '396 Hz - Muladhara',
        frequency: 396.0,
        category: 'chakra',
        benefit: 'Erdung, Überleben, Sicherheit',
        icon: '🔴',
        keywords: ['wurzel', 'erdung', 'sicherheit', 'rot'],
      ),
      FrequencyPreset(
        id: 'chakra_sacral',
        name: 'Sakralchakra',
        description: '417 Hz - Svadhisthana',
        frequency: 417.0,
        category: 'chakra',
        benefit: 'Kreativität, Sexualität, Emotionen',
        icon: '🟠',
        keywords: ['sakral', 'kreativität', 'sexualität', 'orange'],
      ),
      FrequencyPreset(
        id: 'chakra_solar',
        name: 'Solarplexus',
        description: '528 Hz - Manipura',
        frequency: 528.0,
        category: 'chakra',
        benefit: 'Persönliche Kraft, Selbstbewusstsein',
        icon: '🟡',
        keywords: ['solar', 'kraft', 'selbstbewusstsein', 'gelb'],
      ),
      FrequencyPreset(
        id: 'chakra_heart',
        name: 'Herzchakra',
        description: '639 Hz - Anahata',
        frequency: 639.0,
        category: 'chakra',
        benefit: 'Liebe, Mitgefühl, Heilung',
        icon: '💚',
        keywords: ['herz', 'liebe', 'mitgefühl', 'grün'],
      ),
      FrequencyPreset(
        id: 'chakra_throat',
        name: 'Halschakra',
        description: '741 Hz - Vishuddha',
        frequency: 741.0,
        category: 'chakra',
        benefit: 'Ausdruck, Kommunikation, Wahrheit',
        icon: '💙',
        keywords: ['hals', 'ausdruck', 'kommunikation', 'blau'],
      ),
      FrequencyPreset(
        id: 'chakra_third_eye',
        name: 'Stirnchakra',
        description: '852 Hz - Ajna',
        frequency: 852.0,
        category: 'chakra',
        benefit: 'Intuition, Weisheit, Hellsichtigkeit',
        icon: '🔮',
        keywords: ['stirn', 'drittes auge', 'intuition', 'indigo'],
      ),
      FrequencyPreset(
        id: 'chakra_crown',
        name: 'Kronenchakra',
        description: '963 Hz - Sahasrara',
        frequency: 963.0,
        category: 'chakra',
        benefit: 'Spiritualität, Erleuchtung, Einheit',
        icon: '👑',
        keywords: ['krone', 'erleuchtung', 'spiritualität', 'violett'],
      ),

      // PLANETARY FREQUENCIES (nach Hans Cousto)
      FrequencyPreset(
        id: 'planet_sun',
        name: 'Sonne',
        description: '126.22 Hz - OM-Frequenz',
        frequency: 126.22,
        category: 'planetary',
        benefit: 'Lebenskraft, Vitalität, Selbstausdruck',
        icon: '☀️',
        keywords: ['sonne', 'om', 'lebenskraft', 'vitalität'],
      ),
      FrequencyPreset(
        id: 'planet_moon',
        name: 'Mond',
        description: '210.42 Hz',
        frequency: 210.42,
        category: 'planetary',
        benefit: 'Emotionen, Intuition, Weiblichkeit',
        icon: '🌙',
        keywords: ['mond', 'emotionen', 'intuition', 'weiblich'],
      ),
      FrequencyPreset(
        id: 'planet_earth',
        name: 'Erde (Jahr)',
        description: '136.10 Hz - OM der Erde',
        frequency: 136.10,
        category: 'planetary',
        benefit: 'Erdung, Stabilität, Herzchakra',
        icon: '🌍',
        keywords: ['erde', 'erdung', 'stabilität', 'jahr'],
      ),
      FrequencyPreset(
        id: 'planet_mercury',
        name: 'Merkur',
        description: '141.27 Hz',
        frequency: 141.27,
        category: 'planetary',
        benefit: 'Kommunikation, Intellekt, Beweglichkeit',
        icon: '☿️',
        keywords: ['merkur', 'kommunikation', 'intellekt'],
      ),
      FrequencyPreset(
        id: 'planet_venus',
        name: 'Venus',
        description: '221.23 Hz',
        frequency: 221.23,
        category: 'planetary',
        benefit: 'Liebe, Schönheit, Harmonie',
        icon: '♀️',
        keywords: ['venus', 'liebe', 'schönheit', 'harmonie'],
      ),
      FrequencyPreset(
        id: 'planet_mars',
        name: 'Mars',
        description: '144.72 Hz',
        frequency: 144.72,
        category: 'planetary',
        benefit: 'Energie, Willenskraft, Durchsetzung',
        icon: '♂️',
        keywords: ['mars', 'energie', 'willenskraft', 'kraft'],
      ),
      FrequencyPreset(
        id: 'planet_jupiter',
        name: 'Jupiter',
        description: '183.58 Hz',
        frequency: 183.58,
        category: 'planetary',
        benefit: 'Wachstum, Expansion, Fülle',
        icon: '♃',
        keywords: ['jupiter', 'wachstum', 'fülle', 'expansion'],
      ),
      FrequencyPreset(
        id: 'planet_saturn',
        name: 'Saturn',
        description: '147.85 Hz',
        frequency: 147.85,
        category: 'planetary',
        benefit: 'Struktur, Disziplin, Grenzen',
        icon: '♄',
        keywords: ['saturn', 'struktur', 'disziplin', 'grenzen'],
      ),

      // BINAURAL BEATS (Brainwave States)
      FrequencyPreset(
        id: 'binaural_delta',
        name: 'Delta Wellen',
        description: '0.5-4 Hz - Tiefschlaf',
        frequency: 2.0,
        category: 'binaural',
        benefit: 'Tiefschlaf, Regeneration, Heilung',
        icon: '😴',
        keywords: ['schlaf', 'tiefschlaf', 'regeneration', 'delta'],
      ),
      FrequencyPreset(
        id: 'binaural_theta',
        name: 'Theta Wellen',
        description: '4-8 Hz - Meditation',
        frequency: 6.0,
        category: 'binaural',
        benefit: 'Tiefe Meditation, Kreativität, Unterbewusstsein',
        icon: '🧘',
        keywords: ['meditation', 'kreativität', 'unterbewusstsein', 'theta'],
      ),
      FrequencyPreset(
        id: 'binaural_alpha',
        name: 'Alpha Wellen',
        description: '8-14 Hz - Entspannung',
        frequency: 10.0,
        category: 'binaural',
        benefit: 'Entspannte Wachheit, Lernen, Stressabbau',
        icon: '😌',
        keywords: ['entspannung', 'lernen', 'stress', 'alpha'],
      ),
      FrequencyPreset(
        id: 'binaural_beta',
        name: 'Beta Wellen',
        description: '14-30 Hz - Fokus',
        frequency: 20.0,
        category: 'binaural',
        benefit: 'Konzentration, Wachheit, Produktivität',
        icon: '🎯',
        keywords: ['fokus', 'konzentration', 'produktivität', 'beta'],
      ),
      FrequencyPreset(
        id: 'binaural_gamma',
        name: 'Gamma Wellen',
        description: '30-100 Hz - Höheres Bewusstsein',
        frequency: 40.0,
        category: 'binaural',
        benefit: 'Spitzenbewusstsein, Erleuchtung, Klarheit',
        icon: '⚡',
        keywords: ['bewusstsein', 'erleuchtung', 'klarheit', 'gamma'],
      ),
    ];
  }

  static List<FrequencyPreset> getByCategory(String category) {
    return getAllPresets().where((p) => p.category == category).toList();
  }

  static List<FrequencyPreset> searchByKeyword(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllPresets().where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
          p.description.toLowerCase().contains(lowerQuery) ||
          p.keywords.any((k) => k.contains(lowerQuery));
    }).toList();
  }

  static FrequencyPreset? getById(String id) {
    try {
      return getAllPresets().firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
