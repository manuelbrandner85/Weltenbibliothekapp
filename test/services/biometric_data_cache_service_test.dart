import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/services/biometric_data_cache_service.dart';

BiometricReading _reading({
  required String id,
  required DateTime createdAt,
  double? hrBefore,
  double? hrAfter,
  double? hrvBefore,
  double? hrvAfter,
  double? effectiveness,
}) {
  return BiometricReading(
    id: id,
    sessionType: 'meditation',
    sessionWorld: 'ursprung',
    hrvBefore: hrvBefore,
    hrvAfter: hrvAfter,
    hrBefore: hrBefore,
    hrAfter: hrAfter,
    effectivenessScore: effectiveness,
    durationMinutes: 10,
    notes: null,
    createdAt: createdAt,
  );
}

void main() {
  group('BiometricReading.fromJson', () {
    test('parses numeric + string values, keeps nulls', () {
      final r = BiometricReading.fromJson({
        'id': 'abc',
        'session_type': 'gateway',
        'session_world': 'vorhang',
        'hr_before': 72,
        'hr_after': '65.5',
        'hrv_after': 48,
        'effectiveness_score': 80,
        'duration_minutes': 12,
        'created_at': '2026-01-01T10:00:00Z',
      });
      expect(r.id, 'abc');
      expect(r.hrBefore, 72);
      expect(r.hrAfter, 65.5);
      expect(r.hrvBefore, isNull);
      expect(r.hrvAfter, 48);
      expect(r.durationMinutes, 12);
    });

    test('hrEffective/hrvEffective prefer after then before', () {
      final onlyBefore = _reading(
        id: '1',
        createdAt: DateTime(2026),
        hrBefore: 70,
        hrvBefore: 40,
      );
      expect(onlyBefore.hrEffective, 70);
      expect(onlyBefore.hrvEffective, 40);

      final both = _reading(
        id: '2',
        createdAt: DateTime(2026),
        hrBefore: 70,
        hrAfter: 60,
        hrvBefore: 40,
        hrvAfter: 55,
      );
      expect(both.hrEffective, 60);
      expect(both.hrvEffective, 55);
    });

    test('deltas computed only when both endpoints present', () {
      final full = _reading(
        id: '3',
        createdAt: DateTime(2026),
        hrBefore: 80,
        hrAfter: 65,
        hrvBefore: 30,
        hrvAfter: 50,
      );
      expect(full.hrDelta, -15);
      expect(full.hrvDelta, 20);

      final partial = _reading(id: '4', createdAt: DateTime(2026), hrAfter: 65);
      expect(partial.hrDelta, isNull);
      expect(partial.hrvDelta, isNull);
    });
  });

  group('BiometricSummary.fromReadings', () {
    test('empty list yields empty summary', () {
      final s = BiometricSummary.fromReadings(const []);
      expect(s.hasData, isFalse);
      expect(s.count, 0);
      expect(s.avgHr, isNull);
    });

    test('aggregates averages, min/max and effectiveness', () {
      final readings = [
        _reading(
          id: '1',
          createdAt: DateTime(2026, 1, 1),
          hrAfter: 60,
          hrvAfter: 40,
          effectiveness: 70,
        ),
        _reading(
          id: '2',
          createdAt: DateTime(2026, 1, 2),
          hrAfter: 80,
          hrvAfter: 60,
          effectiveness: 90,
        ),
      ];
      final s = BiometricSummary.fromReadings(readings);
      expect(s.count, 2);
      expect(s.avgHr, 70);
      expect(s.avgHrv, 50);
      expect(s.minHr, 60);
      expect(s.maxHr, 80);
      expect(s.avgEffectiveness, 80);
    });

    test('trend is newest minus oldest regardless of input order', () {
      // Provided out of chronological order on purpose.
      final readings = [
        _reading(id: 'newest', createdAt: DateTime(2026, 1, 3), hrAfter: 55),
        _reading(id: 'oldest', createdAt: DateTime(2026, 1, 1), hrAfter: 75),
        _reading(id: 'mid', createdAt: DateTime(2026, 1, 2), hrAfter: 65),
      ];
      final s = BiometricSummary.fromReadings(readings);
      // newest(55) - oldest(75) = -20
      expect(s.hrTrend, -20);
    });

    test('trend null when fewer than two HR values', () {
      final s = BiometricSummary.fromReadings([
        _reading(id: '1', createdAt: DateTime(2026), hrAfter: 60),
      ]);
      expect(s.hrTrend, isNull);
      expect(s.avgHr, 60);
    });

    test('ignores readings without the measured metric', () {
      final readings = [
        _reading(id: '1', createdAt: DateTime(2026, 1, 1), hrAfter: 60),
        _reading(id: '2', createdAt: DateTime(2026, 1, 2)), // no HR/HRV
      ];
      final s = BiometricSummary.fromReadings(readings);
      expect(s.count, 2);
      expect(s.avgHr, 60); // only the one with a value counts
      expect(s.avgHrv, isNull);
    });
  });
}
