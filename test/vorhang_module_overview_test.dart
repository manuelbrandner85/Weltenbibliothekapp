import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/services/vorhang_module_overview.dart';

/// Tests for the Vorhang "Lernmodul-Uebersicht" (A-Z TabBar tab) pure logic:
/// flatten + alphabetical sort + search filter.
void main() {
  Map<String, dynamic> mod(String code, String title, {String subtitle = ''}) =>
      <String, dynamic>{
        'module_code': code,
        'title': title,
        'subtitle': subtitle,
      };

  final branches = <String, List<Map<String, dynamic>>>{
    'Machtpsychologie': [
      mod('V-02', 'Macht & Status'),
      mod('V-01', 'Einfluss verstehen'),
    ],
    'Schattenarbeit': [
      mod('V-30', 'Der innere Schatten', subtitle: 'Carl Jung'),
      mod('V-29', 'Projektionen erkennen'),
    ],
  };

  const order = ['Machtpsychologie', 'Schattenarbeit'];

  group('flatten', () {
    test('keeps every module across branches', () {
      final flat = VorhangModuleOverview.flatten(branches, order: order);
      expect(flat.length, 4);
    });

    test('appends branches missing from order (no module dropped)', () {
      final flat = VorhangModuleOverview.flatten(branches, order: const []);
      expect(flat.length, 4);
    });
  });

  group('sortedAndFiltered', () {
    test('sorts all modules alphabetically by title (case-insensitive)', () {
      final result =
          VorhangModuleOverview.sortedAndFiltered(branches, order: order);
      final titles = result.map((m) => m['title'] as String).toList();
      expect(titles, [
        'Der innere Schatten',
        'Einfluss verstehen',
        'Macht & Status',
        'Projektionen erkennen',
      ]);
    });

    test('filters by title substring', () {
      final result = VorhangModuleOverview.sortedAndFiltered(
        branches,
        order: order,
        query: 'macht',
      );
      expect(result.length, 1);
      expect(result.first['module_code'], 'V-02');
    });

    test('filters by module_code', () {
      final result = VorhangModuleOverview.sortedAndFiltered(
        branches,
        order: order,
        query: 'V-29',
      );
      expect(result.single['title'], 'Projektionen erkennen');
    });

    test('filters by subtitle', () {
      final result = VorhangModuleOverview.sortedAndFiltered(
        branches,
        order: order,
        query: 'jung',
      );
      expect(result.single['module_code'], 'V-30');
    });

    test('empty query returns every module (>= 4 for >= 5-module gate)', () {
      final result = VorhangModuleOverview.sortedAndFiltered(
        branches,
        order: order,
        query: '   ',
      );
      expect(result.length, 4);
    });

    test('no match returns empty list', () {
      final result = VorhangModuleOverview.sortedAndFiltered(
        branches,
        order: order,
        query: 'zzz-nichts',
      );
      expect(result, isEmpty);
    });
  });

  group('matches', () {
    test('whitespace query matches anything', () {
      expect(VorhangModuleOverview.matches(mod('V-01', 'X'), '  '), isTrue);
    });

    test('tolerates missing fields', () {
      expect(
        VorhangModuleOverview.matches(<String, dynamic>{}, 'abc'),
        isFalse,
      );
    });
  });
}
