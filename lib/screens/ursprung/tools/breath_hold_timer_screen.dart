import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// U-X6 -- CO2-Toleranz / Atemhalte-Timer
///
/// Freitauch-/Wim-Hof-Stil Atemhalte-Training. Tap startet/stoppt den
/// Halte-Timer, jede Session wird lokal gespeichert (persoenliche Bestzeit,
/// Durchschnitt, Verlauf). Keine Server-Anbindung -- reines On-Device-Tool.
class BreathHoldTimerScreen extends StatefulWidget {
  const BreathHoldTimerScreen({super.key});

  @override
  State<BreathHoldTimerScreen> createState() => _BreathHoldTimerScreenState();
}

class _BreathHoldTimerScreenState extends State<BreathHoldTimerScreen> {
  static const _cyan = Color(0xFF00D4AA);
  static const _bgDeep = Color(0xFF050510);
  static const _surface = Color(0xFF0E0E1C);
  static const _prefsKey = 'breath_hold_records_v1';

  Timer? _ticker;
  Stopwatch? _watch;
  bool _running = false;
  int _elapsedMs = 0;

  List<_HoldRecord> _records = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final list = <_HoldRecord>[];
    if (raw != null) {
      try {
        for (final e in (jsonDecode(raw) as List)) {
          final m = e as Map<String, dynamic>;
          list.add(_HoldRecord(
            seconds: (m['sec'] as num).toInt(),
            timestamp:
                DateTime.fromMillisecondsSinceEpoch((m['ts'] as num).toInt()),
          ));
        }
      } catch (_) {
        // corrupt -> ignore
      }
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (mounted) {
      setState(() {
        _records = list;
        _loaded = true;
      });
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _records
        .map((r) => {'sec': r.seconds, 'ts': r.timestamp.millisecondsSinceEpoch})
        .toList();
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  void _toggle() {
    if (_running) {
      _stop();
    } else {
      _start();
    }
  }

  void _start() {
    _watch = Stopwatch()..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() => _elapsedMs = _watch?.elapsedMilliseconds ?? 0);
    });
    setState(() {
      _running = true;
      _elapsedMs = 0;
    });
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    _watch?.stop();
    final secs = ((_watch?.elapsedMilliseconds ?? 0) / 1000).round();
    setState(() {
      _running = false;
      _elapsedMs = _watch?.elapsedMilliseconds ?? 0;
    });
    if (secs >= 3) {
      final prev = _bestSeconds;
      final updated = [
        _HoldRecord(seconds: secs, timestamp: DateTime.now()),
        ..._records,
      ];
      // Cap auf 50 Eintraege.
      setState(() => _records = updated.take(50).toList());
      await _persist();
      if (mounted && secs > prev && prev > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Neue Bestzeit!'),
            backgroundColor: _cyan,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _clear() async {
    setState(() => _records = const []);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  int get _bestSeconds =>
      _records.isEmpty ? 0 : _records.map((r) => r.seconds).reduce((a, b) => a > b ? a : b);

  int get _avgSeconds => _records.isEmpty
      ? 0
      : (_records.map((r) => r.seconds).reduce((a, b) => a + b) / _records.length)
          .round();

  String _fmt(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return m > 0 ? '$m:${s.toString().padLeft(2, '0')}' : '${s}s';
  }

  String _fmtLive(int ms) {
    final totalS = ms ~/ 1000;
    final m = totalS ~/ 60;
    final s = totalS % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cyan),
        title: const Text('CO2-Toleranz · Atemhalte',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: _cyan),
              tooltip: 'Verlauf leeren',
              onPressed: _clear,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tief einatmen, dann tippen zum Starten. Erneut tippen, '
                'sobald du Luft holen musst.',
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _toggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _cyan.withValues(alpha: _running ? 0.35 : 0.18),
                        _surface,
                      ],
                    ),
                    border: Border.all(
                      color: _cyan.withValues(alpha: _running ? 0.9 : 0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fmtLive(_elapsedMs),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w200,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _running ? 'TIPPEN ZUM STOPPEN' : 'TIPPEN ZUM STARTEN',
                          style: TextStyle(
                            color: _cyan.withValues(alpha: 0.9),
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'Bestzeit',
                      _bestSeconds > 0 ? _fmt(_bestSeconds) : '--',
                      Icons.emoji_events_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'Durchschnitt',
                      _avgSeconds > 0 ? _fmt(_avgSeconds) : '--',
                      Icons.timeline_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      'Sessions',
                      '${_records.length}',
                      Icons.repeat_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_loaded && _records.isNotEmpty) ...[
                const Text('VERLAUF',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                for (final r in _records.take(20))
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _cyan.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          r.seconds == _bestSeconds
                              ? Icons.emoji_events
                              : Icons.air_rounded,
                          size: 16,
                          color: r.seconds == _bestSeconds
                              ? const Color(0xFFFFD700)
                              : _cyan,
                        ),
                        const SizedBox(width: 10),
                        Text(_fmt(r.seconds),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(_relTime(r.timestamp),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Sicherheit: niemals im oder am Wasser ueben. Bei '
                  'Schwindel sofort normal weiteratmen. Kein Hyperventilieren.',
                  style: TextStyle(
                      color: Color(0xFFFFD08A), fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: _cyan, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  String _relTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'jetzt';
    if (d.inMinutes < 60) return 'vor ${d.inMinutes}m';
    if (d.inHours < 24) return 'vor ${d.inHours}h';
    return 'vor ${d.inDays}d';
  }
}

class _HoldRecord {
  final int seconds;
  final DateTime timestamp;
  const _HoldRecord({required this.seconds, required this.timestamp});
}
