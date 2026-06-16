import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/widgets/wb_segmented_tabs.dart';

void main() {
  const items = [
    WbTabItem(label: 'Info', icon: Icons.info_outline),
    WbTabItem(label: 'Bilder', icon: Icons.image_outlined),
    WbTabItem(label: 'Videos', icon: Icons.play_circle_outline),
  ];

  Widget host({
    required int selected,
    required ValueChanged<int> onChanged,
    WbTabsStyle style = WbTabsStyle.pills,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: WbSegmentedTabs(
          items: items,
          selectedIndex: selected,
          onChanged: onChanged,
          style: style,
        ),
      ),
    );
  }

  group('WbSegmentedTabs', () {
    testWidgets('renders all segment labels (pills)', (tester) async {
      await tester.pumpWidget(host(selected: 0, onChanged: (_) {}));
      expect(find.text('Info'), findsOneWidget);
      expect(find.text('Bilder'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap reports the tapped index', (tester) async {
      var tapped = -1;
      await tester.pumpWidget(host(selected: 0, onChanged: (i) => tapped = i));
      await tester.tap(find.text('Videos'));
      await tester.pumpAndSettle();
      expect(tapped, 2);
    });

    testWidgets('marks the selected segment via Semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(selected: 1, onChanged: (_) {}));
      expect(
        tester.getSemantics(find.text('Bilder')),
        matchesSemantics(
          hasSelectedState: true,
          isSelected: true,
          isButton: true,
          label: 'Bilder',
        ),
      );
      expect(
        tester.getSemantics(find.text('Info')),
        matchesSemantics(
          hasSelectedState: true,
          isSelected: false,
          isButton: true,
          label: 'Info',
        ),
      );
      handle.dispose();
    });

    testWidgets('underline style renders and is tappable', (tester) async {
      var tapped = -1;
      await tester.pumpWidget(
        host(
          selected: 0,
          onChanged: (i) => tapped = i,
          style: WbTabsStyle.underline,
        ),
      );
      expect(find.text('Bilder'), findsOneWidget);
      await tester.tap(find.text('Bilder'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
      expect(tester.takeException(), isNull);
    });
  });
}
