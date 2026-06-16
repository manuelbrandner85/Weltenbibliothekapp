import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/screens/vorhang_modul_screen.dart';

void main() {
  group('VorhangModulScreen TabBar structure', () {
    // Acceptance criterion #1: at least 3 tabs are defined.
    test('exposes at least 3 tabs', () {
      expect(kVorhangModulTabs.length, greaterThanOrEqualTo(3));
    });

    testWidgets('renders a TabBar with one Tab per definition', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: VorhangModulScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(kVorhangModulTabs.length));
      for (final tab in kVorhangModulTabs) {
        expect(find.text(tab.label), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    });

    // Acceptance criterion #2: navigating between tabs swaps the content.
    testWidgets('switching tabs shows the selected tab content', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: VorhangModulScreen()));
      await tester.pumpAndSettle();

      // First tab content is visible initially.
      final firstBranch = kVorhangModulTabs.first.branches.first.title;
      expect(find.text(firstBranch), findsOneWidget);

      // Tap the last tab and verify its content appears.
      await tester.tap(find.byIcon(kVorhangModulTabs.last.icon));
      await tester.pumpAndSettle();

      final lastBranch = kVorhangModulTabs.last.branches.first.title;
      expect(find.text(lastBranch), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // Acceptance criterion #3: renders without overflow on a small phone.
    testWidgets('renders without exceptions on a small screen', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: VorhangModulScreen()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
