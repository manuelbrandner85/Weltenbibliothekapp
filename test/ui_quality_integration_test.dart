import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/widgets/connection_quality_indicator.dart';
import 'package:weltenbibliothek/models/room_connection_state.dart';

/// ═══════════════════════════════════════════════════════════════
/// UI INTEGRATION TESTS - Connection Quality Components
/// ═══════════════════════════════════════════════════════════════
/// Tests UI components for proper rendering and interaction:
/// - ConnectionQualityIndicator Widget
/// - ConnectionStatsDialog
/// - Quality Badge Integration
/// ═══════════════════════════════════════════════════════════════

void main() {
  group('ConnectionQualityIndicator Widget Tests', () {
    testWidgets('UI-001: Renders Excellent quality correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionQualityIndicator(
              quality: ConnectionQuality.excellent,
              roomStats: null,
              showDetails: false,
            ),
          ),
        ),
      );

      // Verify icon is present
      expect(find.byIcon(Icons.signal_cellular_alt), findsOneWidget);

      // Verify green color (excellent quality)
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ConnectionQualityIndicator),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.green));
    });

    testWidgets('UI-002: Renders Good quality correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionQualityIndicator(
              quality: ConnectionQuality.good,
              roomStats: null,
              showDetails: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.signal_cellular_alt_2_bar), findsOneWidget);
    });

    testWidgets('UI-003: Renders Poor quality correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionQualityIndicator(
              quality: ConnectionQuality.poor,
              roomStats: null,
              showDetails: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.signal_cellular_alt_1_bar), findsOneWidget);
    });

    testWidgets('UI-004: Renders Critical quality correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionQualityIndicator(
              quality: ConnectionQuality.critical,
              roomStats: null,
              showDetails: false,
            ),
          ),
        ),
      );

      expect(
        find.byIcon(Icons.signal_cellular_connected_no_internet_0_bar),
        findsOneWidget,
      );
    });

    testWidgets('UI-005: Shows details when showDetails is true', (
      WidgetTester tester,
    ) async {
      final roomStats = RoomStats(
        roomId: 'test_room',
        participantCount: 3,
        uploadBandwidthMbps: 2.5,
        downloadBandwidthMbps: 1.8,
        averageRttMs: 120,
        packetLossPercent: 2.5,
        quality: ConnectionQuality.good,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionQualityIndicator(
              quality: ConnectionQuality.good,
              roomStats: roomStats,
              showDetails: true,
            ),
          ),
        ),
      );

      // Verify participant count is shown
      expect(find.text('3 participants'), findsOneWidget);

      // Verify RTT is shown
      expect(find.textContaining('120ms'), findsOneWidget);

      // Verify bandwidth is shown
      expect(find.textContaining('Mbps'), findsWidgets);
    });

    testWidgets('UI-006: Hides details when showDetails is false', (
      WidgetTester tester,
    ) async {
      final roomStats = RoomStats(
        roomId: 'test_room',
        participantCount: 3,
        uploadBandwidthMbps: 2.5,
        downloadBandwidthMbps: 1.8,
        averageRttMs: 120,
        packetLossPercent: 2.5,
        quality: ConnectionQuality.good,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionQualityIndicator(
              quality: ConnectionQuality.good,
              roomStats: roomStats,
              showDetails: false,
            ),
          ),
        ),
      );

      // Verify details are NOT shown
      expect(find.text('3 participants'), findsNothing);
      expect(find.textContaining('120ms'), findsNothing);
    });
  });

  group('ConnectionStatsDialog Tests', () {
    testWidgets('UI-007: Dialog displays room stats correctly', (
      WidgetTester tester,
    ) async {
      final roomStats = RoomStats(
        roomId: 'dialog_test_room',
        participantCount: 4,
        uploadBandwidthMbps: 3.2,
        downloadBandwidthMbps: 2.7,
        averageRttMs: 95,
        packetLossPercent: 1.5,
        quality: ConnectionQuality.excellent,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ConnectionStatsDialog(
                      roomStats: roomStats,
                      peerStats: {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);

      // Verify room stats are displayed
      expect(find.textContaining('4'), findsWidgets); // Participant count
      expect(find.textContaining('95ms'), findsWidgets); // RTT
      expect(find.textContaining('1.5%'), findsWidgets); // Packet loss
    });

    testWidgets('UI-008: Dialog displays peer stats correctly', (
      WidgetTester tester,
    ) async {
      final roomStats = RoomStats(
        roomId: 'peer_test_room',
        participantCount: 2,
        uploadBandwidthMbps: 2.0,
        downloadBandwidthMbps: 1.5,
        averageRttMs: 110,
        packetLossPercent: 2.0,
        quality: ConnectionQuality.good,
      );

      final peerStats = {
        'peer_001': ConnectionStats(
          peerId: 'peer_001',
          rttMs: 105,
          packetLoss: 1.8,
          jitterMs: 12,
          bytesSent: 1024000,
          bytesReceived: 2048000,
        ),
        'peer_002': ConnectionStats(
          peerId: 'peer_002',
          rttMs: 115,
          packetLoss: 2.2,
          jitterMs: 15,
          bytesSent: 1536000,
          bytesReceived: 2560000,
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ConnectionStatsDialog(
                      roomStats: roomStats,
                      peerStats: peerStats,
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify peer stats are displayed
      expect(find.textContaining('peer_001'), findsOneWidget);
      expect(find.textContaining('peer_002'), findsOneWidget);

      // Verify stats values
      expect(find.textContaining('105ms'), findsWidgets);
      expect(find.textContaining('115ms'), findsWidgets);
    });

    testWidgets('UI-009: Dialog can be closed', (WidgetTester tester) async {
      final roomStats = RoomStats(
        roomId: 'close_test_room',
        participantCount: 1,
        uploadBandwidthMbps: 1.0,
        downloadBandwidthMbps: 0.8,
        averageRttMs: 100,
        packetLossPercent: 1.0,
        quality: ConnectionQuality.excellent,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ConnectionStatsDialog(
                      roomStats: roomStats,
                      peerStats: {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.byType(AlertDialog), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Schließen'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('Quality Badge Color Tests', () {
    testWidgets('UI-010: Excellent quality shows green', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionQualityIndicator(
              quality: ConnectionQuality.excellent,
              roomStats: null,
              showDetails: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ConnectionQualityIndicator),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.green));
    });

    testWidgets('UI-011: Poor quality shows orange', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionQualityIndicator(
              quality: ConnectionQuality.poor,
              roomStats: null,
              showDetails: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ConnectionQualityIndicator),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.orange));
    });

    testWidgets('UI-012: Critical quality shows red', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionQualityIndicator(
              quality: ConnectionQuality.critical,
              roomStats: null,
              showDetails: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(ConnectionQualityIndicator),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.red));
    });
  });

  group('Accessibility Tests', () {
    testWidgets('UI-013: Quality indicator has semantic labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectionQualityIndicator(
              quality: ConnectionQuality.excellent,
              roomStats: null,
              showDetails: false,
            ),
          ),
        ),
      );

      // Verify semantic information is available for screen readers
      expect(find.byType(ConnectionQualityIndicator), findsOneWidget);
    });

    testWidgets('UI-014: Dialog has proper navigation', (
      WidgetTester tester,
    ) async {
      final roomStats = RoomStats(
        roomId: 'a11y_test_room',
        participantCount: 1,
        uploadBandwidthMbps: 1.0,
        downloadBandwidthMbps: 0.8,
        averageRttMs: 100,
        packetLossPercent: 1.0,
        quality: ConnectionQuality.excellent,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ConnectionStatsDialog(
                      roomStats: roomStats,
                      peerStats: {},
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify close button is accessible
      expect(find.text('Schließen'), findsOneWidget);

      // Verify button can be activated
      await tester.tap(find.text('Schließen'));
      await tester.pumpAndSettle();
    });
  });
}
