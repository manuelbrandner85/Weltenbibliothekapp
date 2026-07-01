import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/widgets/ursprung/ursprung_quick_nav.dart';

void main() {
  Widget host(List<UrsprungQuickNavItem> items) {
    return MaterialApp(
      home: Scaffold(body: UrsprungQuickNav(items: items)),
    );
  }

  group('UrsprungQuickNav', () {
    testWidgets('renders a chip for every item', (tester) async {
      await tester.pumpWidget(
        host([
          UrsprungQuickNavItem(
            icon: Icons.psychology,
            label: 'Mentor',
            onTap: () {},
          ),
          UrsprungQuickNavItem(
            icon: Icons.build_outlined,
            label: 'Werkzeuge',
            onTap: () {},
          ),
          UrsprungQuickNavItem(
            icon: Icons.menu_book,
            label: 'Module',
            onTap: () {},
          ),
        ]),
      );

      expect(find.text('Mentor'), findsOneWidget);
      expect(find.text('Werkzeuge'), findsOneWidget);
      expect(find.text('Module'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a chip fires its onTap callback', (tester) async {
      var tapped = '';
      await tester.pumpWidget(
        host([
          UrsprungQuickNavItem(
            icon: Icons.psychology,
            label: 'Mentor',
            onTap: () => tapped = 'Mentor',
          ),
          UrsprungQuickNavItem(
            icon: Icons.menu_book,
            label: 'Module',
            onTap: () => tapped = 'Module',
          ),
        ]),
      );

      await tester.tap(find.text('Module'));
      await tester.pumpAndSettle();

      expect(tapped, 'Module');
    });

    testWidgets('renders nothing when the item list is empty', (tester) async {
      await tester.pumpWidget(host(const []));

      expect(find.byType(ListView), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
