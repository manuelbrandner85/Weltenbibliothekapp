// 📸 VOR/NACH-FOTO TRANSFORMATION
//
// Datierte Foto-Einträge mit Body/Mind/Soul-Tags. Side-by-Side-Vergleich
// auf Zeitachse. image_picker für Aufnahme. Pfade in SharedPreferences,
// Bilder im App-Document-Directory.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoProgressScreen extends StatefulWidget {
  const PhotoProgressScreen({super.key});

  @override
  State<PhotoProgressScreen> createState() => _PhotoProgressScreenState();
}

class _PhotoProgressScreenState extends State<PhotoProgressScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF1A0F0A);
  static const _accent = Color(0xFFF57C00);
  static const _kvKey = 'photo_progress_v1';

  List<_Snap> _snaps = [];
  bool _loading = true;
  int _compareIdxA = -1;
  int _compareIdxB = -1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kvKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _snaps = list.map((e) => _Snap.fromJson(e as Map<String, dynamic>)).toList();
        _snaps.sort((a, b) => b.date.compareTo(a.date));
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kvKey,
        jsonEncode(_snaps.map((s) => s.toJson()).toList()));
  }

  Future<void> _addPhoto() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Foto-Aufnahme ist auf Web nicht verfügbar — bitte Mobile-App nutzen.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final filename = 'progress_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = '${dir.path}/$filename';
    await File(picked.path).copy(newPath);

    final tags = await _askTags();
    if (tags == null) return;

    setState(() {
      _snaps.insert(0, _Snap(
        path: newPath,
        date: DateTime.now(),
        bodyNote: tags.body,
        mindNote: tags.mind,
        soulNote: tags.soul,
      ));
    });
    await _save();
  }

  Future<({String body, String mind, String soul})?> _askTags() async {
    final body = TextEditingController();
    final mind = TextEditingController();
    final soul = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Wie geht es dir heute?',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('💪 Körper', body),
              const SizedBox(height: 10),
              _field('🧠 Geist', mind),
              const SizedBox(height: 10),
              _field('✨ Seele', soul),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (result == true) {
      return (body: body.text, mind: mind.text, soul: soul.text);
    }
    return null;
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _accent.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _delete(int idx) async {
    final s = _snaps[idx];
    try {
      final f = File(s.path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    setState(() => _snaps.removeAt(idx));
    await _save();
  }

  void _toggleCompare(int idx) {
    setState(() {
      if (_compareIdxA == idx) {
        _compareIdxA = -1;
      } else if (_compareIdxB == idx) {
        _compareIdxB = -1;
      } else if (_compareIdxA < 0) {
        _compareIdxA = idx;
      } else if (_compareIdxB < 0) {
        _compareIdxB = idx;
      } else {
        _compareIdxA = idx;
        _compareIdxB = -1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Row(children: [
          Text('📸', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Vor/Nach-Foto',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Neues Foto'),
        onPressed: _addPhoto,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _snaps.isEmpty
              ? _buildEmpty()
              : _compareIdxA >= 0 && _compareIdxB >= 0
                  ? _buildCompare()
                  : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('📸', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('Noch keine Fotos',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(
            'Tippe unten auf "Neues Foto" — Fotos bleiben rein lokal auf deinem Gerät.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ]),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: _snaps.length,
      itemBuilder: (_, i) {
        final s = _snaps[i];
        final isCompA = _compareIdxA == i;
        final isCompB = _compareIdxB == i;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isCompA || isCompB) ? _accent : _accent.withValues(alpha: 0.2),
              width: (isCompA || isCompB) ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: kIsWeb
                      ? Container(color: Colors.grey.shade800, child: const Center(child: Icon(Icons.image, size: 64, color: Colors.white24)))
                      : Image.file(File(s.path), fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey.shade800, child: const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.white24)))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('${s.date.day}.${s.date.month}.${s.date.year}',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            isCompA || isCompB ? Icons.compare_arrows : Icons.add_box_outlined,
                            color: _accent,
                            size: 20,
                          ),
                          tooltip: 'Für Vergleich auswählen',
                          onPressed: () => _toggleCompare(i),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white54, size: 20),
                          onPressed: () => _delete(i),
                        ),
                      ],
                    ),
                    if (s.bodyNote.isNotEmpty)
                      Text('💪 ${s.bodyNote}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (s.mindNote.isNotEmpty)
                      Text('🧠 ${s.mindNote}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (s.soulNote.isNotEmpty)
                      Text('✨ ${s.soulNote}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompare() {
    final a = _snaps[_compareIdxA];
    final b = _snaps[_compareIdxB];
    final daysDiff = a.date.difference(b.date).inDays.abs();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.4)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Vergleich · $daysDiff Tage Abstand',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _compareSide(a, 'VORHER')),
                const SizedBox(width: 8),
                Expanded(child: _compareSide(b, 'NACHHER')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _compareIdxA = -1;
              _compareIdxB = -1;
            }),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text('Zurück zur Galerie', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white24)),
          ),
        ],
      ),
    );
  }

  Widget _compareSide(_Snap s, String label) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: _accent,
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ClipRRect(
              child: kIsWeb
                  ? Container(color: Colors.grey.shade800, child: const Icon(Icons.image, color: Colors.white24, size: 64))
                  : Image.file(File(s.path), fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
                      Container(color: Colors.grey.shade800, child: const Icon(Icons.broken_image, size: 64, color: Colors.white24))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text('${s.date.day}.${s.date.month}.${s.date.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _Snap {
  final String path;
  final DateTime date;
  final String bodyNote;
  final String mindNote;
  final String soulNote;
  const _Snap({
    required this.path,
    required this.date,
    required this.bodyNote,
    required this.mindNote,
    required this.soulNote,
  });
  Map<String, dynamic> toJson() => {
        'path': path,
        'date': date.toIso8601String(),
        'body': bodyNote,
        'mind': mindNote,
        'soul': soulNote,
      };
  factory _Snap.fromJson(Map<String, dynamic> j) => _Snap(
        path: j['path'] as String,
        date: DateTime.parse(j['date'] as String),
        bodyNote: j['body'] as String? ?? '',
        mindNote: j['mind'] as String? ?? '',
        soulNote: j['soul'] as String? ?? '',
      );
}
