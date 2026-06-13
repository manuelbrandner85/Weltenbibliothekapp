import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weltenbibliothek/core/device/wb_device_capability.dart';
import 'package:weltenbibliothek/core/device/wb_quality.dart';
import 'package:weltenbibliothek/widgets/cinematic/cinematic_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    KbCinemaSettings.instance.quality.value = CinematicQuality.auto;
  });
  tearDown(() {
    WbDeviceCapability.debugOverrideTier(null);
    KbCinemaSettings.instance.quality.value = CinematicQuality.auto;
  });

  test('user off -> minimal, nothing animates', () {
    WbDeviceCapability.debugOverrideTier(WbDeviceTier.high);
    KbCinemaSettings.instance.quality.value = CinematicQuality.off;
    expect(WbQuality.level, WbQualityLevel.minimal);
    expect(WbQuality.ambientVideo, isFalse);
    expect(WbQuality.entranceAnimations, isFalse);
    expect(WbQuality.heavyEffects, isFalse);
    expect(WbQuality.shaderIntensity, 0.0);
  });

  test('low device -> minimal even if user wants cinema', () {
    WbDeviceCapability.debugOverrideTier(WbDeviceTier.low);
    KbCinemaSettings.instance.quality.value = CinematicQuality.cinema;
    expect(WbQuality.level, WbQualityLevel.minimal);
    expect(WbQuality.ambientVideo, isFalse);
  });

  test('high device + cinema -> full', () {
    WbDeviceCapability.debugOverrideTier(WbDeviceTier.high);
    KbCinemaSettings.instance.quality.value = CinematicQuality.cinema;
    expect(WbQuality.level, WbQualityLevel.full);
    expect(WbQuality.ambientVideo, isTrue);
    expect(WbQuality.heavyEffects, isTrue);
    expect(WbQuality.entranceAnimations, isTrue);
  });

  test('mid device + subtle -> balanced (ambient yes, heavy no)', () {
    WbDeviceCapability.debugOverrideTier(WbDeviceTier.mid);
    KbCinemaSettings.instance.quality.value = CinematicQuality.subtle;
    expect(WbQuality.level, WbQualityLevel.balanced);
    expect(WbQuality.ambientVideo, isTrue);
    expect(WbQuality.heavyEffects, isFalse);
    expect(WbQuality.entranceAnimations, isTrue);
  });

  test('tapScale is always allowed', () {
    WbDeviceCapability.debugOverrideTier(WbDeviceTier.low);
    KbCinemaSettings.instance.quality.value = CinematicQuality.off;
    expect(WbQuality.tapScale, isTrue);
  });
}
