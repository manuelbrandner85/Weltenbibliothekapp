import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/services/tabbar_service.dart';

void main() {
  group('TabBarService.energieTabs', () {
    test('defines the six ENERGIE world tabs in order', () {
      final labels = TabBarService.energieTabs.map((t) => t.label).toList();
      expect(labels, [
        'Home',
        'Spirit',
        'Community',
        'Karte',
        'Wissen',
        'Videos',
      ]);
    });

    test('Spirit index points at the Spirit tab', () {
      expect(
        TabBarService.energieTabs[TabBarService.energieSpiritIndex].label,
        'Spirit',
      );
    });

    test('every tab has a non-empty label and an icon', () {
      for (final t in TabBarService.energieTabs) {
        expect(t.label, isNotEmpty);
        expect(t.icon, isA<IconData>());
      }
    });
  });

  group('TabBarService.isValidIndex', () {
    const tabs = TabBarService.energieTabs;

    test('accepts every in-range index', () {
      for (var i = 0; i < tabs.length; i++) {
        expect(TabBarService.isValidIndex(i, tabs), isTrue);
      }
    });

    test('rejects out-of-range and negative indices', () {
      expect(TabBarService.isValidIndex(-1, tabs), isFalse);
      expect(TabBarService.isValidIndex(tabs.length, tabs), isFalse);
      expect(TabBarService.isValidIndex(999, tabs), isFalse);
    });
  });

  group('TabBarService.clampIndex', () {
    const tabs = TabBarService.energieTabs;

    test('returns the index unchanged when in range', () {
      expect(TabBarService.clampIndex(0, tabs), 0);
      expect(TabBarService.clampIndex(3, tabs), 3);
      expect(TabBarService.clampIndex(tabs.length - 1, tabs), tabs.length - 1);
    });

    test('clamps a too-large index to the last tab (no RangeError)', () {
      expect(TabBarService.clampIndex(99, tabs), tabs.length - 1);
    });

    test('clamps a negative index to the first tab', () {
      expect(TabBarService.clampIndex(-5, tabs), 0);
    });

    test('falls back to 0 for an empty tab list', () {
      expect(TabBarService.clampIndex(2, const <WorldTab>[]), 0);
    });

    test('clamped index is always safe to use on a matching page list', () {
      final pages = List<String>.generate(tabs.length, (i) => 'page$i');
      for (final raw in [-10, -1, 0, 2, tabs.length, 100]) {
        final safe = TabBarService.clampIndex(raw, tabs);
        // Indexing must never throw for any input.
        expect(() => pages[safe], returnsNormally);
      }
    });
  });
}
