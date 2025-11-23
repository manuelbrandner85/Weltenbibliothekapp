import 'dart:math';
import 'package:flutter/material.dart';

/// Service für Energy-Symbol-Verwaltung
/// Weist Benutzern zufällige Energie-Symbole zu wenn Kamera ausgeschaltet ist
class EnergySymbolService {
  static final EnergySymbolService _instance = EnergySymbolService._internal();
  factory EnergySymbolService() => _instance;
  EnergySymbolService._internal();

  final Random _random = Random();
  final Map<String, String> _userSymbols = {};

  /// Alle verfügbaren Energy-Symbole (24K Gold Design)
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

  /// Symbol-Namen (für Tooltips/Beschreibungen)
  static const Map<String, String> symbolNames = {
    'blume_des_lebens.png': 'Blume des Lebens',
    'metatrons_wuerfel.png': 'Metatrons Würfel',
    'sri_yantra.png': 'Sri Yantra',
    'merkaba.png': 'Merkaba',
    'samen_des_lebens.png': 'Samen des Lebens',
    'torus_feld.png': 'Torus Feld',
    'lebensbaum.png': 'Lebensbaum',
    'vesica_piscis.png': 'Vesica Piscis',
    'platonische_koerper.png': 'Platonische Körper',
    'ankh.png': 'Ankh',
  };

  /// Holt oder erstellt ein Energy-Symbol für einen Benutzer
  String getSymbolForUser(String userId) {
    if (_userSymbols.containsKey(userId)) {
      return _userSymbols[userId]!;
    }

    // Zufälliges Symbol zuweisen
    final symbol = energySymbols[_random.nextInt(energySymbols.length)];
    _userSymbols[userId] = symbol;
    return symbol;
  }

  /// Symbol-Namen aus Pfad extrahieren
  String getSymbolName(String symbolPath) {
    final fileName = symbolPath.split('/').last;
    return symbolNames[fileName] ?? 'Energy Symbol';
  }

  /// Setzt Symbol für Benutzer (optional, für Präferenzen)
  void setSymbolForUser(String userId, String symbolPath) {
    if (energySymbols.contains(symbolPath)) {
      _userSymbols[userId] = symbolPath;
    }
  }

  /// Zurücksetzen der Symbol-Zuweisungen
  void clearAllAssignments() {
    _userSymbols.clear();
  }
}

/// Widget für Energy-Symbol-Avatar (wenn Kamera aus)
class EnergySymbolAvatar extends StatelessWidget {
  final String userId;
  final double size;
  final bool showName;

  const EnergySymbolAvatar({
    super.key,
    required this.userId,
    this.size = 100,
    this.showName = false,
  });

  @override
  Widget build(BuildContext context) {
    final service = EnergySymbolService();
    final symbolPath = service.getSymbolForUser(userId);
    final symbolName = service.getSymbolName(symbolPath);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(
              color: const Color(0xFFFFD700), // Gold
              width: 2,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              symbolPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.energy_savings_leaf,
                  color: Color(0xFFFFD700),
                  size: 50,
                );
              },
            ),
          ),
        ),
        if (showName) ...[
          const SizedBox(height: 8),
          Text(
            symbolName,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
