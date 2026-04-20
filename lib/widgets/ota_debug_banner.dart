import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

// Kleiner Diagnose-Overlay oben rechts – zeigt ob Shorebird läuft und
// welche Patch-Nummer aktuell auf dem Gerät liegt. Hilft um Probleme
// wie "Patch kommt an, aber Änderungen fehlen" ohne Device-Logs zu
// analysieren: User liest die Zahlen ab und sagt sie uns.
class OtaDebugBanner extends StatefulWidget {
  const OtaDebugBanner({super.key});

  @override
  State<OtaDebugBanner> createState() => _OtaDebugBannerState();
}

class _OtaDebugBannerState extends State<OtaDebugBanner> {
  final _shorebird = ShorebirdUpdater();

  bool? _available;
  int? _currentPatch;
  int? _nextPatch;
  String? _checkResult;
  String? _error;

  static const String _appVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '—');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final avail = _shorebird.isAvailable;
      int? cur;
      int? nxt;
      String? status;
      if (avail) {
        final c = await _shorebird.readCurrentPatch();
        final n = await _shorebird.readNextPatch();
        cur = c?.number;
        nxt = n?.number;
        try {
          final s = await _shorebird.checkForUpdate();
          status = s.toString().split('.').last;
        } catch (e) {
          status = 'err:$e';
        }
      }
      if (!mounted) return;
      setState(() {
        _available = avail;
        _currentPatch = cur;
        _nextPatch = nxt;
        _checkResult = status;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      'v=$_appVersion',
      'sb=${_available == null ? '…' : (_available! ? 'ON' : 'OFF')}',
      'cur=${_currentPatch ?? '—'}',
      'nxt=${_nextPatch ?? '—'}',
      'chk=${_checkResult ?? '…'}',
      if (_error != null) 'ERR=$_error',
    ];
    return Positioned(
      top: 40,
      right: 8,
      child: GestureDetector(
        onTap: _load,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: lines
                .map((l) => Text(
                      l,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
