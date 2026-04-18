// ignore_for_file: avoid_print
import 'package:weltenbibliothek/services/moon_calculator.dart';

void testPhase(String label, DateTime utc, String expectedPhase,
    {int? expectSignIdx, double? expectIllum}) {
  final s = calculateMoonSnapshot(utc);
  final ok = s.phaseKey == expectedPhase;
  print('${ok ? "✓" : "✗"} $label');
  print('   utc=$utc jd=${s.jd.toStringAsFixed(5)}');
  print('   sun=${s.sunLongitude.toStringAsFixed(3)}°  '
      'moon=${s.moonLongitude.toStringAsFixed(3)}°  '
      'phase=${s.phaseAngle.toStringAsFixed(3)}°');
  print('   -> ${s.phaseLabel} (${s.phaseKey}) ${s.phaseEmoji}  '
      'illum=${s.illuminationPercent}  sign=${s.moonSignName} ${s.moonSignSymbol} '
      '(${s.moonSignDegree.toStringAsFixed(2)}°)  element=${s.moonElement}');
  if (expectSignIdx != null) {
    final sigOk = s.moonSignIndex == expectSignIdx;
    print('   ${sigOk ? "✓" : "✗"} sign idx=${s.moonSignIndex} expected=$expectSignIdx (${zodiacNames[expectSignIdx]})');
  }
  if (expectIllum != null) {
    final err = (s.illumination - expectIllum).abs();
    print('   illum err=${(err * 100).toStringAsFixed(2)}%');
  }
  print('');
}

void testPhaseTiming(String label, DateTime from, double phase, DateTime expected) {
  final got = nextMoonPhase(from, phase);
  final diffMin = (got.difference(expected).inSeconds / 60.0).abs();
  final ok = diffMin < 5;
  print('${ok ? "✓" : "✗"} $label');
  print('   expected: $expected');
  print('   got:      $got');
  print('   diff:     ${diffMin.toStringAsFixed(2)} min');
  print('');
}

void main() {
  print('=== Mondphase-Tests ===\n');

  // Bekannte Ereignisse aus astronomischen Kalendern (alle UTC):
  //  2024-01-11 11:57  Neumond
  //  2024-01-25 17:54  Vollmond
  //  2024-03-10 09:00  Neumond
  //  2024-03-25 07:00  Vollmond (penumbrale Finsternis)
  //  2024-04-08 18:21  Neumond (totale Sonnenfinsternis)
  //  2024-04-23 23:49  Vollmond

  testPhase('2024-01-11 12:00 UTC sollte Neumond sein',
      DateTime.utc(2024, 1, 11, 12, 0), 'new_moon', expectIllum: 0);
  testPhase('2024-01-25 18:00 UTC sollte Vollmond sein',
      DateTime.utc(2024, 1, 25, 18, 0), 'full_moon', expectIllum: 1);
  testPhase('2024-03-10 09:00 UTC sollte Neumond sein',
      DateTime.utc(2024, 3, 10, 9, 0), 'new_moon', expectIllum: 0);
  testPhase('2024-04-08 18:21 UTC sollte Neumond sein (totale SoFi)',
      DateTime.utc(2024, 4, 8, 18, 21), 'new_moon', expectIllum: 0);

  // Heute (2026-04-18): laut in-the-sky ist der Mond ca. 01:00 UTC im Stier
  // (Datum aus dem Environment-Kontext der Session)
  testPhase('Heute 2026-04-18 12:00 UTC (Referenz: Mond im Stier laut in-the-sky.org)',
      DateTime.utc(2026, 4, 18, 12, 0), '',
      expectSignIdx: null);

  print('=== Phasen-Timing-Tests ===\n');

  testPhaseTiming(
      'Nächster Neumond ab 2024-01-01 → 2024-01-11 11:57',
      DateTime.utc(2024, 1, 1),
      0,
      DateTime.utc(2024, 1, 11, 11, 57));
  testPhaseTiming(
      'Nächster Vollmond ab 2024-01-15 → 2024-01-25 17:54',
      DateTime.utc(2024, 1, 15),
      180,
      DateTime.utc(2024, 1, 25, 17, 54));
  testPhaseTiming(
      'Nächster Neumond ab 2024-04-01 → 2024-04-08 18:21',
      DateTime.utc(2024, 4, 1),
      0,
      DateTime.utc(2024, 4, 8, 18, 21));
  testPhaseTiming(
      'Nächstes Erstes Viertel ab 2024-01-12 → 2024-01-18 03:52',
      DateTime.utc(2024, 1, 12),
      90,
      DateTime.utc(2024, 1, 18, 3, 52));

  print('=== Zeichenwechsel-Test ===\n');

  final change = nextMoonSignChange(DateTime.utc(2026, 4, 18, 12, 0));
  print('Nächster Zeichenwechsel ab 2026-04-18 12:00 UTC: $change');
  final beforeSign = calculateMoonSnapshot(change.subtract(const Duration(minutes: 1)));
  final afterSign = calculateMoonSnapshot(change.add(const Duration(minutes: 1)));
  print('  1 min davor: ${beforeSign.moonSignName} (long=${beforeSign.moonLongitude.toStringAsFixed(3)}°)');
  print('  1 min danach: ${afterSign.moonSignName} (long=${afterSign.moonLongitude.toStringAsFixed(3)}°)');
  final transitionClean = beforeSign.moonSignIndex != afterSign.moonSignIndex;
  print('  ${transitionClean ? "✓" : "✗"} Zeichen wechselt tatsächlich am Übergang');
}
