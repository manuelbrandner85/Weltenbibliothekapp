import 'dart:math';

/// Service für Chat-Hintergrund-Bilder und Energy-Symbole
class ImageAssetService {
  // Chat-Hintergrund-Bilder (3 pro Typ) - 24K Gold Design
  static const Map<String, List<String>> chatBackgrounds = {
    'weltenbibliothek': [
      'assets/images/chat_backgrounds/weltenbibliothek_1.png',
      'assets/images/chat_backgrounds/weltenbibliothek_2.png',
      'assets/images/chat_backgrounds/weltenbibliothek_3.png',
    ],
    'musik': [
      'assets/images/chat_backgrounds/musik_1.png',
      'assets/images/chat_backgrounds/musik_2.png',
      'assets/images/chat_backgrounds/musik_3.png',
    ],
    'verschwoerung': [
      'assets/images/chat_backgrounds/verschwoerung_1.png',
      'assets/images/chat_backgrounds/verschwoerung_2.png',
      'assets/images/chat_backgrounds/verschwoerung_3.png',
    ],
  };

  // Energy-Symbole (10 Stück) - 24K Gold Design
  static const List<String> energySymbols = [
    'assets/images/energy_symbols/blume_des_lebens.png',
    'assets/images/energy_symbols/metatrons_wuerfel.png',
    'assets/images/energy_symbols/sri_yantra.png',
    'assets/images/energy_symbols/merkaba.png',
    'assets/images/energy_symbols/samen_des_lebens.png',
    'assets/images/energy_symbols/torus_feld.png',
    'assets/images/energy_symbols/lebensbaum.png',
    'assets/images/energy_symbols/vesica_piscis.png',
    'assets/images/energy_symbols/platonische_koerper.png',
    'assets/images/energy_symbols/ankh.png',
  ];

  /// Holt alle Hintergrund-Bilder für einen Chat-Typ
  static List<String> getChatBackgrounds(String chatType) {
    final type = chatType.toLowerCase();

    // Verschwörungstheorien-Chats verwenden "verschwoerung" Bilder
    if (type.contains('verschwör') || type.contains('verschwoer')) {
      return chatBackgrounds['verschwoerung'] ?? [];
    }

    // Musik-Chats
    if (type.contains('musik')) {
      return chatBackgrounds['musik'] ?? [];
    }

    // Weltenbibliothek & Allgemeine Chats
    return chatBackgrounds['weltenbibliothek'] ?? [];
  }

  /// Holt ein zufälliges Energy-Symbol für Avatar (wenn Kamera aus)
  static String getRandomEnergySymbol({int? seed}) {
    final random = seed != null ? Random(seed) : Random();
    return energySymbols[random.nextInt(energySymbols.length)];
  }

  /// Holt ein konsistentes Energy-Symbol basierend auf User-ID
  static String getEnergySymbolForUser(String userId) {
    // Verwende userId als Seed für konsistentes Symbol pro User
    final seed = userId.hashCode;
    return getRandomEnergySymbol(seed: seed);
  }
}
