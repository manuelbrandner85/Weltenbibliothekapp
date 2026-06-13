import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/widgets/animations/wb_tap_scale.dart';
import 'package:weltenbibliothek/widgets/animations/wb_animated_entrance.dart';

void main() {
  group('WbTapScale', () {
    testWidgets('fires onTap and renders child', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WbTapScale(
              onTap: () => taps++,
              child: const Text('press me'),
            ),
          ),
        ),
      );

      expect(find.text('press me'), findsOneWidget);
      await tester.tap(find.text('press me'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disabled blocks onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WbTapScale(
              enabled: false,
              onTap: () => taps++,
              child: const Text('x'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('x'));
      await tester.pumpAndSettle();
      expect(taps, 0);
    });

    testWidgets('reduce-motion still allows tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: WbTapScale(
                onTap: () => taps++,
                child: const Text('y'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('y'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  group('WbAnimatedEntrance', () {
    testWidgets('renders child (animated path)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WbAnimatedEntrance(index: 2, child: Text('hello')),
          ),
        ),
      );
      await tester.pump(); // start
      await tester.pump(const Duration(seconds: 1)); // settle entrance
      expect(find.text('hello'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduce-motion returns child instantly', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: WbAnimatedEntrance(child: Text('instant')),
            ),
          ),
        ),
      );
      // No pumpAndSettle needed -- no animation scheduled.
      expect(find.text('instant'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
