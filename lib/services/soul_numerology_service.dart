// Numerologie-Service für Seelenvertrag (Tool 5).
//
// Pythagoräisches Schema (1=A/J/S, 2=B/K/T, ...), mit deutschen
// Sonderzeichen (Ä→A, Ö→O, Ü→U, ß→SS).
//
// Master-Zahlen 11/22/33 werden NICHT reduziert.
// Karmische-Schuld-Zahlen 13/14/16/19 werden erkannt, bevor sie reduziert
// werden.

import 'dart:collection';

/// Ergebnis einer vollständigen Seelenvertrags-Berechnung.
class SoulNumerologyResult {
  final int lifePath;
  final int destiny; // Expression
  final int soulUrge;
  final int personality;
  final int birthDay;
  final List<int> karmicDebts;
  final Map<String, dynamic> computation;

  const SoulNumerologyResult({
    required this.lifePath,
    required this.destiny,
    required this.soulUrge,
    required this.personality,
    required this.birthDay,
    required this.karmicDebts,
    required this.computation,
  });

  Map<String, dynamic> toJson() => {
        'life_path': lifePath,
        'destiny': destiny,
        'soul_urge': soulUrge,
        'personality': personality,
        'birth_day': birthDay,
        'karmic_debts': karmicDebts,
        'computation': computation,
      };
}

class SoulNumerology {
  static const Map<String, int> _letterValues = {
    'A': 1, 'J': 1, 'S': 1,
    'B': 2, 'K': 2, 'T': 2,
    'C': 3, 'L': 3, 'U': 3,
    'D': 4, 'M': 4, 'V': 4,
    'E': 5, 'N': 5, 'W': 5,
    'F': 6, 'O': 6, 'X': 6,
    'G': 7, 'P': 7, 'Y': 7,
    'H': 8, 'Q': 8, 'Z': 8,
    'I': 9, 'R': 9,
  };

  static const Set<String> _vowels = {'A', 'E', 'I', 'O', 'U'};

  static String normalize(String input) {
    var s = input.toUpperCase();
    s = s
        .replaceAll('Ä', 'A')
        .replaceAll('Ö', 'O')
        .replaceAll('Ü', 'U')
        .replaceAll('ß', 'SS')
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('À', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('Ê', 'E')
        .replaceAll('Î', 'I')
        .replaceAll('Ô', 'O')
        .replaceAll('Û', 'U')
        .replaceAll('Ñ', 'N')
        .replaceAll('Ç', 'C');
    return s.replaceAll(RegExp('[^A-Z]'), '');
  }

  static _ReduceResult _reduce(int n) {
    final path = <int>[n];
    int cur = n;
    while (cur > 9 && cur != 11 && cur != 22 && cur != 33) {
      final next = cur
          .toString()
          .split('')
          .map(int.parse)
          .fold<int>(0, (a, b) => a + b);
      path.add(next);
      cur = next;
    }
    return _ReduceResult(cur, path);
  }

  static int? _karmicDebtIn(List<int> path) {
    for (final v in path) {
      if (v == 13 || v == 14 || v == 16 || v == 19) return v;
    }
    return null;
  }

  static _SumResult _sumLetters(String normalized,
      {bool vowelsOnly = false, bool consonantsOnly = false}) {
    int sum = 0;
    final used = <String>[];
    for (final ch in normalized.split('')) {
      final isVowel = _vowels.contains(ch);
      if (vowelsOnly && !isVowel) continue;
      if (consonantsOnly && isVowel) continue;
      final v = _letterValues[ch];
      if (v == null) continue;
      sum += v;
      used.add('$ch=$v');
    }
    return _SumResult(sum, used);
  }

  static SoulNumerologyResult compute({
    required String fullName,
    required DateTime birthDate,
  }) {
    final name = normalize(fullName);
    if (name.isEmpty) {
      throw ArgumentError('Name enthält keine Buchstaben A–Z');
    }

    // Life Path: Tag + Monat + Jahr (jeweils reduziert, dann summiert)
    final dayR = _reduce(birthDate.day);
    final monR = _reduce(birthDate.month);
    final yearR = _reduce(birthDate.year);
    final lifePathRaw = dayR.value + monR.value + yearR.value;
    final lifePathR = _reduce(lifePathRaw);

    // Destiny / Expression
    final destSum = _sumLetters(name);
    final destR = _reduce(destSum.total);

    // Soul Urge (Vokale)
    final soulSum = _sumLetters(name, vowelsOnly: true);
    final soulR = _reduce(soulSum.total == 0 ? 1 : soulSum.total);

    // Personality (Konsonanten)
    final persSum = _sumLetters(name, consonantsOnly: true);
    final persR = _reduce(persSum.total == 0 ? 1 : persSum.total);

    // Birth Day
    final birthDayR = _reduce(birthDate.day);

    // Karmic Debts
    final karmicSet = SplayTreeSet<int>();
    for (final path in [
      dayR.path,
      monR.path,
      yearR.path,
      lifePathR.path,
      destR.path,
      soulR.path,
      persR.path,
      birthDayR.path,
    ]) {
      final k = _karmicDebtIn(path);
      if (k != null) karmicSet.add(k);
    }

    return SoulNumerologyResult(
      lifePath: lifePathR.value,
      destiny: destR.value,
      soulUrge: soulR.value,
      personality: persR.value,
      birthDay: birthDayR.value,
      karmicDebts: karmicSet.toList(),
      computation: {
        'name_normalized': name,
        'day_path': dayR.path,
        'month_path': monR.path,
        'year_path': yearR.path,
        'life_path_raw': lifePathRaw,
        'life_path_path': lifePathR.path,
        'destiny_sum': destSum.total,
        'destiny_path': destR.path,
        'destiny_letters': destSum.used,
        'soul_urge_sum': soulSum.total,
        'soul_urge_path': soulR.path,
        'soul_urge_letters': soulSum.used,
        'personality_sum': persSum.total,
        'personality_path': persR.path,
        'personality_letters': persSum.used,
        'birth_day_path': birthDayR.path,
      },
    );
  }
}

class _ReduceResult {
  final int value;
  final List<int> path;
  _ReduceResult(this.value, this.path);
}

class _SumResult {
  final int total;
  final List<String> used;
  _SumResult(this.total, this.used);
}
