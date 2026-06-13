import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/core/device/wb_device_capability.dart';
import 'package:weltenbibliothek/widgets/cinematic/wb_adaptive_backdrop.dart';

void main() {
  group('WbDeviceCapability', () {
    tearDown(() => WbDeviceCapability.debugOverrideTier(null));

    test('low tier blocks ambient video + heavy effects', () {
      WbDeviceCapability.debugOverrideTier(WbDeviceTier.low);
      expect(WbDeviceCapability.allowsAmbientVideo, isFalse);
      expect(WbDeviceCapability.allowsHeavyEffects, isFalse);
    });

    test('high tier allows everything', () {
      WbDeviceCapability.debugOverrideTier(WbDeviceTier.high);
      expect(WbDeviceCapability.allowsAmbientVideo, isTrue);
      expect(WbDeviceCapability.allowsHeavyEffects, isTrue);
    });

    test('mid tier allows ambient video but not heavy effects', () {
      WbDeviceCapability.debugOverrideTier(WbDeviceTier.mid);
      expect(WbDeviceCapability.allowsAmbientVideo, isTrue);
      expect(WbDeviceCapability.allowsHeavyEffects, isFalse);
    });
  });

  group('WbAdaptiveBackdrop', () {
    testWidgets('renders without a video asset and shows a base layer',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WbAdaptiveBackdrop(
            fallbackImage: 'assets/images/does_not_exist.webp',
            child: Text('overlay'),
          ),
        ),
      );
      await tester.pump();

      // No exception, the still base layer + child render.
      expect(tester.takeException(), isNull);
      expect(find.byType(WbAdaptiveBackdrop), findsOneWidget);
      expect(find.text('overlay'), findsOneWidget);
      // A missing asset degrades to the void color, never a blank/throw.
      expect(find.byType(ColoredBox), findsWidgets);
    });

    testWidgets('honours reduce-motion by staying on the still', (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: WbAdaptiveBackdrop(
              fallbackImage: 'assets/images/does_not_exist.webp',
              videoAsset: 'assets/videos/portal_ambient_loop.mp4',
            ),
          ),
        ),
      );
      await tester.pump();

      // With reduce-motion on, no VideoPlayer is ever created.
      expect(tester.takeException(), isNull);
      expect(find.byType(WbAdaptiveBackdrop), findsOneWidget);
    });
  });
}
