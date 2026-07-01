import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weltenbibliothek/services/search_history_service.dart';

/// Tests for the v10.0 index-optimized SearchHistoryService.
///
/// Focus: the read/query operations must keep behaving exactly like before
/// (newest-first ordering, dedup, filtering, stats) while relying on the
/// sorted invariant + lowercased-query index instead of per-read sorting.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Fresh, empty backing store for every test; init() rebuilds the index.
    SharedPreferences.setMockInitialValues({});
    await SearchHistoryService.init();
    await SearchHistoryService.clearAllHistory();
  });

  test(
    'addSearch stores entry and hasQuery uses the index (case-insensitive)',
    () async {
      await SearchHistoryService.addSearch(query: 'Sonnensystem');
      expect(SearchHistoryService.getHistoryCount(), 1);
      expect(SearchHistoryService.hasQuery('sonnensystem'), isTrue);
      expect(SearchHistoryService.hasQuery('unbekannt'), isFalse);
    },
  );

  test('blank queries are ignored', () async {
    await SearchHistoryService.addSearch(query: '   ');
    expect(SearchHistoryService.getHistoryCount(), 0);
  });

  test('duplicate query is de-duplicated and moved to front', () async {
    await SearchHistoryService.addSearch(query: 'alpha');
    await SearchHistoryService.addSearch(query: 'beta');
    await SearchHistoryService.addSearch(query: 'ALPHA');

    expect(SearchHistoryService.getHistoryCount(), 2);
    final all = SearchHistoryService.getAllHistory();
    // Re-added query becomes newest -> front of the ordered list.
    expect(all.first.query, 'ALPHA');
  });

  test(
    'getAllHistory / getRecentHistory return newest-first without sorting',
    () async {
      await SearchHistoryService.addSearch(query: 'first');
      await SearchHistoryService.addSearch(query: 'second');
      await SearchHistoryService.addSearch(query: 'third');

      final all = SearchHistoryService.getAllHistory();
      expect(all.map((e) => e.query).toList(), ['third', 'second', 'first']);

      final recent = SearchHistoryService.getRecentHistory(limit: 2);
      expect(recent.map((e) => e.query).toList(), ['third', 'second']);
    },
  );

  test(
    'searchHistory filters over query, summary and tags, keeps order',
    () async {
      await SearchHistoryService.addSearch(
        query: 'mond',
        summary: 'erdtrabant',
      );
      await SearchHistoryService.addSearch(
        query: 'stern',
        tags: ['astronomie'],
      );
      await SearchHistoryService.addSearch(query: 'planet');

      expect(
        SearchHistoryService.searchHistory('erdtrabant').single.query,
        'mond',
      );
      expect(
        SearchHistoryService.searchHistory('astronomie').single.query,
        'stern',
      );
      // Empty filter returns everything, still newest-first.
      expect(SearchHistoryService.searchHistory('').first.query, 'planet');
    },
  );

  test(
    'cleanup keeps only the newest _maxHistoryEntries and prunes index',
    () async {
      for (var i = 0; i < 60; i++) {
        await SearchHistoryService.addSearch(query: 'q$i');
      }
      expect(SearchHistoryService.getHistoryCount(), 50);
      // Oldest ones dropped both from list and from the index.
      expect(SearchHistoryService.hasQuery('q0'), isFalse);
      expect(SearchHistoryService.hasQuery('q59'), isTrue);
      expect(SearchHistoryService.getAllHistory().first.query, 'q59');
    },
  );

  test('deleteEntry removes from list and index', () async {
    await SearchHistoryService.addSearch(query: 'löschbar');
    final id = SearchHistoryService.getAllHistory().first.id;
    await SearchHistoryService.deleteEntry(id);
    expect(SearchHistoryService.getHistoryCount(), 0);
    expect(SearchHistoryService.hasQuery('löschbar'), isFalse);
  });

  test('getStatistics reports correct oldest/newest via single pass', () async {
    await SearchHistoryService.addSearch(query: 'a', resultCount: 4);
    await SearchHistoryService.addSearch(query: 'b', resultCount: 6);

    final stats = SearchHistoryService.getStatistics();
    expect(stats['totalSearches'], 2);
    expect(stats['uniqueQueries'], 2);
    expect(stats['averageResultCount'], 5);
    final oldest = stats['oldestSearch'] as DateTime;
    final newest = stats['newestSearch'] as DateTime;
    expect(newest.isBefore(oldest), isFalse);
  });
}
