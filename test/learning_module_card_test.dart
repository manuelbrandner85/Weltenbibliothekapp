import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/services/learning_module_service.dart';
import 'package:weltenbibliothek/widgets/learning_module_card.dart';
import 'package:weltenbibliothek/widgets/lesson_series_screen.dart';

LearningModule _sampleModule({int lessons = 7}) {
  return LearningModule(
    title: '7-Tage-Test-Reihe',
    emoji: '🌈',
    description: 'Test-Tradition — kurze Beschreibung der Reihe',
    storageKey: 'lr_test_7',
    accent: const Color(0xFFE91E63),
    entries: List.generate(
      lessons,
      (i) => LessonSeriesEntry(
        code: 'd$i',
        symbol: 'S',
        title: 'Tag $i',
        subtitle: 'sub',
        meaning: 'meaning',
        reflection: 'reflect',
      ),
    ),
  );
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required LearningModule module,
  required LearningModuleProgress progress,
  required VoidCallback onTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LearningModuleCard(
          module: module,
          progress: progress,
          onTap: onTap,
        ),
      ),
    ),
  );
}

void main() {
  group('LearningModuleCard', () {
    testWidgets('shows title, description, lesson badge and progress', (
      tester,
    ) async {
      final module = _sampleModule();
      await _pumpCard(
        tester,
        module: module,
        progress: const LearningModuleProgress(completed: 3, total: 7),
        onTap: () {},
      );

      expect(find.text('7-Tage-Test-Reihe'), findsOneWidget);
      expect(
        find.text('Test-Tradition — kurze Beschreibung der Reihe'),
        findsOneWidget,
      );
      expect(find.text('7 Tage'), findsOneWidget);
      expect(find.text('3/7'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fires onTap when card is tapped', (tester) async {
      var taps = 0;
      await _pumpCard(
        tester,
        module: _sampleModule(),
        progress: const LearningModuleProgress(completed: 0, total: 7),
        onTap: () => taps++,
      );

      await tester.tap(find.byType(LearningModuleCard));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('shows completion badge only when finished', (tester) async {
      // Not complete -> no verified icon.
      await _pumpCard(
        tester,
        module: _sampleModule(),
        progress: const LearningModuleProgress(completed: 2, total: 7),
        onTap: () {},
      );
      expect(find.byIcon(Icons.verified), findsNothing);

      // Fully complete -> verified icon visible.
      await _pumpCard(
        tester,
        module: _sampleModule(),
        progress: const LearningModuleProgress(completed: 7, total: 7),
        onTap: () {},
      );
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });
  });

  group('LearningModuleProgress', () {
    test('fraction and isComplete behave correctly', () {
      const empty = LearningModuleProgress(completed: 0, total: 0);
      expect(empty.fraction, 0.0);
      expect(empty.isComplete, isFalse);

      const half = LearningModuleProgress(completed: 5, total: 10);
      expect(half.fraction, 0.5);
      expect(half.isComplete, isFalse);

      const full = LearningModuleProgress(completed: 10, total: 10);
      expect(full.fraction, 1.0);
      expect(full.isComplete, isTrue);
    });
  });

  group('LearningModuleService', () {
    test('catalog is non-empty and totals match lesson counts', () {
      final service = LearningModuleService.instance;
      expect(service.modules, isNotEmpty);

      final sumOfLessons = service.modules.fold<int>(
        0,
        (a, m) => a + m.lessonCount,
      );
      expect(service.totalLessons, sumOfLessons);
    });

    test('progressFor maps raw counts onto the module', () {
      final service = LearningModuleService.instance;
      final module = service.modules.first;
      final progress = service.progressFor(module, {module.storageKey: 2});
      expect(progress.completed, 2);
      expect(progress.total, module.lessonCount);
    });
  });
}
