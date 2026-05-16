// Web-Stub für flutter_webrtc (kein Web-Support in v1.x).
// Kamera-Enumeration ist auf Web nicht über flutter_webrtc verfügbar.

class _MediaDeviceInfo {
  final String kind;
  final String deviceId;
  const _MediaDeviceInfo({required this.kind, required this.deviceId});
}

class _MediaDevices {
  Future<List<_MediaDeviceInfo>> enumerateDevices() async => [];
}

class _Navigator {
  final mediaDevices = _MediaDevices();
}

final navigator = _Navigator();
