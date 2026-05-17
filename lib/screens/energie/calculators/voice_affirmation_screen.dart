// 💫 VOICE-AFFIRMATIONS-RECORDER
//
// User nimmt eigene Affirmationen mit eigener Stimme auf, speichert sie
// dauerhaft lokal und kann sie loopable abspielen. Selbstsuggestion-Praxis
// nach Emile Coué. Nutzt flutter_sound (bereits installiert), nicht record.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceAffirmationScreen extends StatefulWidget {
  const VoiceAffirmationScreen({super.key});

  @override
  State<VoiceAffirmationScreen> createState() => _VoiceAffirmationScreenState();
}

class _VoiceAffirmationScreenState extends State<VoiceAffirmationScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF1A0820);
  static const _accent = Color(0xFFE91E63);
  static const _kvKey = 'voice_affirmations_v1';

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _recorderReady = false;
  bool _recording = false;
  String? _currentRecordingPath;
  String? _playingId;
  Timer? _recordTimer;
  Duration _recordDuration = Duration.zero;

  List<_Affirmation> _affirmations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recorder.closeRecorder();
    _player.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (!kIsWeb) {
      try {
        await _recorder.openRecorder();
        _recorderReady = true;
      } catch (_) {}
    }
    await _loadAffirmations();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadAffirmations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kvKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _affirmations = list
            .map((e) => _Affirmation.fromJson(e as Map<String, dynamic>))
            .toList();
        _affirmations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kvKey,
        jsonEncode(_affirmations.map((a) => a.toJson()).toList()));
  }

  Future<void> _startRecording() async {
    if (kIsWeb || !_recorderReady) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aufnahme auf Web nicht verfügbar — bitte Mobile-App nutzen.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    // Mikrofon-Berechtigung
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mikrofon-Berechtigung nötig.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    _currentRecordingPath = '${dir.path}/affirmation_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
      toFile: _currentRecordingPath,
      codec: Codec.aacADTS,
    );
    setState(() {
      _recording = true;
      _recordDuration = Duration.zero;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _recordDuration = Duration(seconds: t.tick);
          if (_recordDuration.inSeconds >= 60) {
            _stopRecording();
          }
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    _recordTimer?.cancel();
    if (!_recording) return;
    await _recorder.stopRecorder();
    setState(() => _recording = false);
    if (_currentRecordingPath == null) return;
    final title = await _askTitle();
    if (title == null || title.trim().isEmpty) {
      // verworfen → File löschen
      try {
        final f = File(_currentRecordingPath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      _currentRecordingPath = null;
      return;
    }
    setState(() {
      _affirmations.insert(0, _Affirmation(
        id: 'aff_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        path: _currentRecordingPath!,
        durationSec: _recordDuration.inSeconds,
        createdAt: DateTime.now(),
      ));
    });
    _currentRecordingPath = null;
    await _save();
  }

  Future<String?> _askTitle() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Affirmation benennen', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'z.B. "Ich bin genug"',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Verwerfen', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _play(_Affirmation a, {bool loop = false}) async {
    if (_playingId == a.id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }
    await _player.stop();
    await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
    await _player.play(DeviceFileSource(a.path));
    setState(() => _playingId = a.id);
    if (!loop) {
      _player.onPlayerComplete.first.then((_) {
        if (mounted) setState(() => _playingId = null);
      });
    }
  }

  Future<void> _delete(_Affirmation a) async {
    try {
      final f = File(a.path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    setState(() => _affirmations.removeWhere((e) => e.id == a.id));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Row(children: [
          Text('💫', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Voice-Affirmationen',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : Column(
                children: [
                  Expanded(
                    child: _affirmations.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            itemCount: _affirmations.length,
                            itemBuilder: (_, i) => _buildAffCard(_affirmations[i]),
                          ),
                  ),
                  _buildRecordPanel(),
                ],
              ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('💫', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('Noch keine Affirmationen',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            'Selbstsuggestion-Technik nach Émile Coué: deine eigene Stimme hat die '
            'tiefste Wirkung. Tippe unten den roten Knopf zum Aufnehmen.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ]),
      ),
    );
  }

  Widget _buildAffCard(_Affirmation a) {
    final playing = _playingId == a.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        IconButton(
          onPressed: () => _play(a, loop: false),
          icon: Icon(
            playing ? Icons.stop_circle : Icons.play_circle_fill,
            color: _accent,
            size: 40,
          ),
        ),
        IconButton(
          onPressed: () => _play(a, loop: true),
          icon: Icon(
            Icons.loop,
            color: playing ? _accent : _accent.withValues(alpha: 0.5),
            size: 24,
          ),
          tooltip: 'Loop',
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('${a.durationSec}s · ${a.createdAt.day}.${a.createdAt.month}.${a.createdAt.year}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white38),
          onPressed: () => _delete(a),
        ),
      ]),
    );
  }

  Widget _buildRecordPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _accent.withValues(alpha: 0.3))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_recording)
            Text('🔴 Aufnahme · ${_recordDuration.inSeconds}s / 60s',
                style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
          if (_recording) const SizedBox(height: 8),
          GestureDetector(
            onTap: _recording ? _stopRecording : _startRecording,
            child: Container(
              width: 78, height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _recording ? Colors.redAccent : _accent,
                  (_recording ? Colors.redAccent : _accent).withValues(alpha: 0.4),
                ]),
                boxShadow: [
                  BoxShadow(
                    color: (_recording ? Colors.redAccent : _accent).withValues(alpha: 0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(
                _recording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(_recording ? 'Tippe um zu stoppen' : 'Tippe um aufzunehmen',
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}

class _Affirmation {
  final String id;
  final String title;
  final String path;
  final int durationSec;
  final DateTime createdAt;
  const _Affirmation({
    required this.id,
    required this.title,
    required this.path,
    required this.durationSec,
    required this.createdAt,
  });
  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'path': path,
        'durationSec': durationSec, 'createdAt': createdAt.toIso8601String(),
      };
  factory _Affirmation.fromJson(Map<String, dynamic> j) => _Affirmation(
        id: j['id'] as String,
        title: j['title'] as String,
        path: j['path'] as String,
        durationSec: (j['durationSec'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
