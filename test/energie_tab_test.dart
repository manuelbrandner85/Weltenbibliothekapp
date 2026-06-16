import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/screens/energie/energie_tab.dart';

void main() {
  group('EnergieTab — bottom-nav index mapping', () {
    test('declaration order matches the EnergieWorldScreen tab order', () {
      // These indices are the contract between the floating nav bar, the
      // tab-content list and every in-content deep link. If the order ever
      // changes, this test forces the wiring to be revisited.
      expect(EnergieTab.home.index, 0);
      expect(EnergieTab.spirit.index, 1);
      expect(EnergieTab.community.index, 2);
      expect(EnergieTab.karte.index, 3);
      expect(EnergieTab.wissen.index, 4);
      expect(EnergieTab.videos.index, 5);
      expect(EnergieTab.values.length, 6);
    });

    test('fromIndex round-trips for every valid index', () {
      for (final tab in EnergieTab.values) {
        expect(EnergieTab.fromIndex(tab.index), tab);
      }
    });

    test('fromIndex falls back to home for out-of-range indices', () {
      expect(EnergieTab.fromIndex(-1), EnergieTab.home);
      expect(EnergieTab.fromIndex(6), EnergieTab.home);
      expect(EnergieTab.fromIndex(999), EnergieTab.home);
    });

    test('isValidIndex guards the real range only', () {
      expect(EnergieTab.isValidIndex(0), isTrue);
      expect(EnergieTab.isValidIndex(5), isTrue);
      expect(EnergieTab.isValidIndex(-1), isFalse);
      expect(EnergieTab.isValidIndex(6), isFalse);
    });

    test('every tab exposes a non-empty German label and an icon', () {
      for (final tab in EnergieTab.values) {
        expect(tab.label, isNotEmpty);
        expect(tab.icon, isA<IconData>());
      }
      // Spot-check the label that drives the learning-module deep link.
      expect(EnergieTab.wissen.label, 'Wissen');
      expect(EnergieTab.wissen.icon, Icons.menu_book);
    });
  });
}
