// BLE Heart Rate Service - Direct Bluetooth Low Energy connection to
// devices exposing the standard GATT Heart Rate Service (UUID 0x180D).
//
// Bypasses Health Connect entirely and reads HR live from devices like
// Polar H10, Wahoo TICKR, Garmin HRM-Pro, and any Smart-Watch in
// "standard BLE HR mode" (e.g. some Galaxy Watches when not paired via
// the Samsung Wearable App).
//
// Public API:
//   BleHeartRateService.instance.init()         -- auto-reconnect on boot
//   BleHeartRateService.instance.getStatus()    -- BT/permission check
//   BleHeartRateService.instance.scan()         -- discover HR devices
//   BleHeartRateService.instance.connect(dev)   -- subscribe + persist
//   BleHeartRateService.instance.disconnect()   -- close + forget
//   BleHeartRateService.instance.heartRateStream -- live BPM stream
//
// iOS note: Apple Watch never broadcasts a standard BLE HR service,
// so iOS users need a chest strap (Polar / Wahoo) or a 3rd-party device.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Public DTOs
// ---------------------------------------------------------------------------

/// One device discovered during scan.
@immutable
class BleHrDevice {
  final BluetoothDevice device;
  final String name;
  final int rssi; // negative dBm, e.g. -55 (strong) to -90 (weak)

  const BleHrDevice({
    required this.device,
    required this.name,
    required this.rssi,
  });

  /// Coarse signal bucket for UI bars (0..3).
  int get signalBars {
    if (rssi >= -60) return 3;
    if (rssi >= -75) return 2;
    if (rssi >= -90) return 1;
    return 0;
  }
}

/// Snapshot of the BLE-adapter + permission state used to gate UI actions.
@immutable
class BleStatus {
  final bool bluetoothOn;
  final bool permissionsGranted;
  final bool supported;
  final String? errorReason;

  const BleStatus({
    required this.bluetoothOn,
    required this.permissionsGranted,
    required this.supported,
    this.errorReason,
  });

  bool get isReady => bluetoothOn && permissionsGranted && supported;

  const BleStatus.unsupported({String? reason})
      : bluetoothOn = false,
        permissionsGranted = false,
        supported = false,
        errorReason = reason;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class BleHeartRateService {
  BleHeartRateService._();
  static final BleHeartRateService instance = BleHeartRateService._();

  // GATT-Spec UUIDs (standard BLE Heart Rate profile).
  static final Guid heartRateServiceUuid =
      Guid('0000180D-0000-1000-8000-00805F9B34FB');
  static final Guid heartRateMeasurementCharUuid =
      Guid('00002A37-0000-1000-8000-00805F9B34FB');

  // SharedPreferences keys.
  static const String _kPrefDeviceId = 'ble_hr_saved_device_id';
  static const String _kPrefDeviceName = 'ble_hr_saved_device_name';

  // Internal state.
  final StreamController<int> _hrController = StreamController<int>.broadcast();
  BluetoothDevice? _connectedDevice;
  String? _connectedDeviceName;
  StreamSubscription<List<int>>? _charSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  int? _lastBpm;
  DateTime? _lastBpmAt;
  bool _initDone = false;

  // -------------------------------------------------------------------------
  // Public state getters
  // -------------------------------------------------------------------------

  BluetoothDevice? get connectedDevice => _connectedDevice;
  String? get connectedDeviceName => _connectedDeviceName;
  bool get isConnected => _connectedDevice != null;

  Stream<int> get heartRateStream => _hrController.stream;

  int? get lastBpm => _lastBpm;
  DateTime? get lastBpmAt => _lastBpmAt;

  // -------------------------------------------------------------------------
  // Init / auto-reconnect
  // -------------------------------------------------------------------------

  /// Call once at app start. Silently tries to reconnect to the last paired
  /// device if it is in range. Never throws.
  Future<void> init() async {
    if (_initDone) return;
    _initDone = true;

    try {
      final supported = await FlutterBluePlus.isSupported;
      if (!supported) return;
    } catch (e) {
      debugPrint('BleHeartRateService.init isSupported failed: $e');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_kPrefDeviceId);
    final savedName = prefs.getString(_kPrefDeviceName);
    if (savedId == null || savedId.isEmpty) return;

    // Wait for adapter to be on (best-effort, short timeout).
    try {
      final state = await FlutterBluePlus.adapterState.first
          .timeout(const Duration(seconds: 2));
      if (state != BluetoothAdapterState.on) return;
    } catch (_) {
      return;
    }

    // Short scan for the saved device id.
    try {
      await FlutterBluePlus.startScan(
        withServices: [heartRateServiceUuid],
        timeout: const Duration(seconds: 5),
      );
      final found = await FlutterBluePlus.scanResults
          .map((results) {
            for (final r in results) {
              if (r.device.remoteId.str == savedId) return r;
            }
            return null;
          })
          .where((r) => r != null)
          .cast<ScanResult>()
          .first
          .timeout(const Duration(seconds: 6));
      await FlutterBluePlus.stopScan();
      await connect(found.device);
      _connectedDeviceName ??= savedName;
    } catch (e) {
      // Silent fail - device just not in range right now.
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
      debugPrint('BleHeartRateService.init auto-reconnect skipped: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Status / permissions
  // -------------------------------------------------------------------------

  Future<BleStatus> getStatus() async {
    bool supported;
    try {
      supported = await FlutterBluePlus.isSupported;
    } catch (e) {
      return BleStatus.unsupported(reason: 'BLE nicht verfuegbar: $e');
    }
    if (!supported) {
      return const BleStatus.unsupported(
        reason: 'Plattform unterstuetzt kein BLE',
      );
    }

    bool bluetoothOn = false;
    try {
      final state = await FlutterBluePlus.adapterState.first
          .timeout(const Duration(seconds: 2));
      bluetoothOn = state == BluetoothAdapterState.on;
    } catch (_) {
      bluetoothOn = false;
    }

    final permResult = await _ensurePermissions(request: false);
    return BleStatus(
      bluetoothOn: bluetoothOn,
      permissionsGranted: permResult.granted,
      supported: true,
      errorReason: !bluetoothOn
          ? 'Bitte Bluetooth aktivieren'
          : (permResult.granted ? null : permResult.reason),
    );
  }

  Future<_PermResult> _ensurePermissions({required bool request}) async {
    // Android 12+ requires bluetoothScan + bluetoothConnect.
    // Android < 12 requires locationWhenInUse for BLE scanning.
    // iOS uses the Info.plist NSBluetooth* keys, permission_handler returns
    // granted=true on iOS for bluetoothScan in practice.
    final perms = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];

    final statuses = <Permission, PermissionStatus>{};
    for (final p in perms) {
      try {
        var s = await p.status;
        if (!s.isGranted && request) {
          s = await p.request();
        }
        statuses[p] = s;
      } catch (e) {
        debugPrint('BleHeartRateService permission $p check failed: $e');
        statuses[p] = PermissionStatus.denied;
      }
    }

    // Scan + Connect are hard requirements on Android 12+.
    // Location is needed on Android < 12 - we treat it as soft (warn only)
    // because on iOS / newer Android it is not strictly necessary.
    final scanOk = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final connectOk = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    final locationOk =
        statuses[Permission.locationWhenInUse]?.isGranted ?? false;

    if (!scanOk || !connectOk) {
      return _PermResult(
        granted: false,
        reason: 'Bluetooth-Berechtigung verweigert',
      );
    }
    if (!locationOk) {
      // Not fatal - just a warning.
      return const _PermResult(
        granted: true,
        reason: 'Standort empfohlen fuer aeltere Android-Versionen',
      );
    }
    return const _PermResult(granted: true);
  }

  // -------------------------------------------------------------------------
  // Scan
  // -------------------------------------------------------------------------

  /// Scan for devices exposing the HR Service. Stops automatically after
  /// [timeout]. Each emit is one newly discovered device.
  Stream<BleHrDevice> scan({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    // Permission request happens up-front (user-facing) since scan needs it.
    final perm = await _ensurePermissions(request: true);
    if (!perm.granted) {
      throw StateError(
        perm.reason ?? 'Bluetooth-Berechtigung nicht erteilt',
      );
    }

    // Cancel any previous scan first.
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    final seen = <String>{};
    final controller = StreamController<BleHrDevice>();
    late StreamSubscription<List<ScanResult>> sub;

    sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final id = r.device.remoteId.str;
        if (seen.contains(id)) continue;
        // Filter: only devices exposing the HR service.
        final advUuids = r.advertisementData.serviceUuids
            .map((g) => g.str.toLowerCase())
            .toList(growable: false);
        final hrShort = '180d';
        final hrLong = heartRateServiceUuid.str.toLowerCase();
        final hasHr = advUuids.any(
          (u) => u == hrShort || u == hrLong || u.contains('180d'),
        );
        if (!hasHr) continue;

        seen.add(id);
        final name = r.advertisementData.advName.isNotEmpty
            ? r.advertisementData.advName
            : (r.device.platformName.isNotEmpty
                ? r.device.platformName
                : 'Unbekanntes Geraet');
        controller.add(BleHrDevice(
          device: r.device,
          name: name,
          rssi: r.rssi,
        ));
      }
    });

    try {
      await FlutterBluePlus.startScan(
        withServices: [heartRateServiceUuid],
        timeout: timeout,
      );
    } catch (e) {
      await sub.cancel();
      await controller.close();
      throw StateError('Scan-Start fehlgeschlagen: $e');
    }

    // Auto-stop after timeout window.
    final timer = Timer(timeout + const Duration(milliseconds: 250), () {
      controller.close();
    });

    try {
      yield* controller.stream;
    } finally {
      timer.cancel();
      await sub.cancel();
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
      if (!controller.isClosed) {
        await controller.close();
      }
    }
  }

  // -------------------------------------------------------------------------
  // Connect / disconnect
  // -------------------------------------------------------------------------

  /// Connect to a device, subscribe to HR notifications, persist id for
  /// auto-reconnect. Returns true on success.
  Future<bool> connect(BluetoothDevice device) async {
    try {
      // Drop any previous connection cleanly.
      if (_connectedDevice != null) {
        await _internalCleanup(forget: false);
      }

      await device.connect(
        timeout: const Duration(seconds: 12),
        autoConnect: false,
      );

      // Listen for unsolicited disconnects.
      await _connSub?.cancel();
      _connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _onDisconnected();
        }
      });

      // Discover services + find HR characteristic.
      final services = await device.discoverServices();
      BluetoothCharacteristic? hrChar;
      for (final s in services) {
        if (s.uuid != heartRateServiceUuid &&
            !s.uuid.str.toLowerCase().contains('180d')) {
          continue;
        }
        for (final c in s.characteristics) {
          if (c.uuid == heartRateMeasurementCharUuid ||
              c.uuid.str.toLowerCase().contains('2a37')) {
            hrChar = c;
            break;
          }
        }
        if (hrChar != null) break;
      }

      if (hrChar == null) {
        await device.disconnect();
        debugPrint('BleHeartRateService: HR characteristic not found');
        return false;
      }

      await hrChar.setNotifyValue(true);
      await _charSub?.cancel();
      _charSub = hrChar.lastValueStream.listen((bytes) {
        final bpm = _parseHeartRate(bytes);
        if (bpm > 0) {
          _lastBpm = bpm;
          _lastBpmAt = DateTime.now();
          if (!_hrController.isClosed) _hrController.add(bpm);
        }
      });

      _connectedDevice = device;
      final name =
          device.platformName.isNotEmpty ? device.platformName : 'BLE-Geraet';
      _connectedDeviceName = name;

      // Persist for auto-reconnect.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefDeviceId, device.remoteId.str);
      await prefs.setString(_kPrefDeviceName, name);

      return true;
    } catch (e, st) {
      debugPrint('BleHeartRateService.connect failed: $e\n$st');
      try {
        await device.disconnect();
      } catch (_) {}
      await _internalCleanup(forget: false);
      return false;
    }
  }

  /// Manual disconnect by the user. Forgets the saved device.
  Future<void> disconnect() async {
    final dev = _connectedDevice;
    await _internalCleanup(forget: true);
    if (dev != null) {
      try {
        await dev.disconnect();
      } catch (e) {
        debugPrint('BleHeartRateService.disconnect failed: $e');
      }
    }
  }

  void _onDisconnected() {
    _connectedDevice = null;
    _connectedDeviceName = null;
    _charSub?.cancel();
    _charSub = null;
    // Keep saved id - auto-reconnect on next init().
  }

  Future<void> _internalCleanup({required bool forget}) async {
    await _charSub?.cancel();
    _charSub = null;
    await _connSub?.cancel();
    _connSub = null;
    _connectedDevice = null;
    _connectedDeviceName = null;
    if (forget) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_kPrefDeviceId);
        await prefs.remove(_kPrefDeviceName);
      } catch (e) {
        debugPrint('BleHeartRateService prefs cleanup failed: $e');
      }
    }
  }

  /// Final cleanup (call from app shutdown if needed).
  Future<void> dispose() async {
    await _internalCleanup(forget: false);
    if (!_hrController.isClosed) {
      await _hrController.close();
    }
  }

  // -------------------------------------------------------------------------
  // HR Measurement parser (GATT Heart Rate Measurement, char 0x2A37)
  //
  // Byte 0 = Flags:
  //   Bit 0 -- Heart Rate Value format: 0 = uint8, 1 = uint16 LE
  //   Bit 1..2 -- Sensor Contact Status (ignored here)
  //   Bit 3 -- Energy Expended Status (ignored)
  //   Bit 4 -- RR-Interval present (ignored - HRV is computed elsewhere)
  // -------------------------------------------------------------------------

  int _parseHeartRate(List<int> bytes) {
    if (bytes.isEmpty) return 0;
    final flags = bytes[0];
    if ((flags & 0x01) == 0) {
      return bytes.length > 1 ? bytes[1] : 0;
    }
    return bytes.length > 2 ? (bytes[1] | (bytes[2] << 8)) : 0;
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

@immutable
class _PermResult {
  final bool granted;
  final String? reason;
  const _PermResult({required this.granted, this.reason});
}
