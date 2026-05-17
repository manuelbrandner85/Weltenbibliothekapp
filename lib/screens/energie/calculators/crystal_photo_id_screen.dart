// 💎 KRISTALL-FOTO-ERKENNUNG
//
// User fotografiert Kristall, App sendet Bild an Cloudflare Worker
// /api/vision/identify-crystal (Workers AI Vision @cf/llava-1.5-7b-hf).
// Fallback bei 404/Fehler: zeigt manuelle Stein-Datenbank zur Suche.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/api_config.dart';

class CrystalPhotoIdScreen extends StatefulWidget {
  const CrystalPhotoIdScreen({super.key});

  @override
  State<CrystalPhotoIdScreen> createState() => _CrystalPhotoIdScreenState();
}

class _CrystalPhotoIdScreenState extends State<CrystalPhotoIdScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF0D1B3E);
  static const _accent = Color(0xFF1976D2);

  XFile? _picked;
  bool _analyzing = false;
  String? _result;
  String? _error;

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final p = await picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    if (p == null) return;
    setState(() {
      _picked = p;
      _result = null;
      _error = null;
    });
  }

  Future<void> _analyze() async {
    if (_picked == null) return;
    setState(() {
      _analyzing = true;
      _result = null;
      _error = null;
    });
    try {
      final bytes = await _picked!.readAsBytes();
      final base64 = base64Encode(bytes);
      final token = Supabase.instance.client.auth.currentSession?.accessToken ?? '';
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/vision/identify-crystal'),
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'image_base64': base64,
              'prompt':
                  'Welcher Heilstein oder Mineral ist auf diesem Foto zu sehen? '
                  'Antworte präzise mit Name (deutsch), kurzer Begründung (Farbe, Glanz, Form, Bruch). '
                  'Falls unklar: nenne die 2-3 wahrscheinlichsten Kandidaten.',
            }),
          )
          .timeout(const Duration(seconds: 45));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final reply = (data['response'] as String?) ??
            (data['identification'] as String?) ??
            (data['result'] as String?);
        if (reply != null && reply.isNotEmpty) {
          setState(() => _result = reply);
        } else {
          setState(() => _error = 'KI hat kein Ergebnis geliefert.');
        }
      } else if (res.statusCode == 404) {
        setState(() => _error =
            'Vision-Endpoint noch nicht aktiviert auf dem Worker. '
            'Bitte das CF-Worker-Update abwarten oder Stein manuell in der '
            'Kristall-Datenbank nachschlagen.');
      } else {
        setState(() => _error = 'Worker-Fehler ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Netzwerk-Fehler: $e');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: const Row(children: [
          Text('💎', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Text('Foto-Stein-Erkennung',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_accent.withValues(alpha: 0.4), _surface]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Fotografiere einen Kristall — KI-Vision identifiziert ihn anhand '
                  'von Farbe, Glanz, Form und Bruch. Bei Unsicherheit: 2-3 Kandidaten.',
                  style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              // Photo preview
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _accent.withValues(alpha: 0.4)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _picked == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: _accent.withValues(alpha: 0.6), size: 64),
                              const SizedBox(height: 12),
                              const Text('Tippe unten zum Aufnehmen',
                                  style: TextStyle(color: Colors.white60)),
                            ],
                          ),
                        )
                      : kIsWeb
                          ? Image.network(_picked!.path, fit: BoxFit.cover)
                          : Image.file(File(_picked!.path), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (!kIsWeb)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Kamera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (!kIsWeb) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.image, color: _accent),
                      label: const Text('Galerie', style: TextStyle(color: _accent)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _accent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_picked != null)
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _analyzing ? null : _analyze,
                    icon: _analyzing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome),
                    label: Text(_analyzing ? 'KI analysiert…' : 'STEIN IDENTIFIZIEREN',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              if (_result != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [const Color(0xFF7C4DFF).withValues(alpha: 0.3), _surface]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF7C4DFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF7C4DFF)),
                        SizedBox(width: 8),
                        Text('KI-IDENTIFIKATION',
                            style: TextStyle(color: Color(0xFF7C4DFF), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 10),
                      SelectableText(_result!,
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6)),
                    ],
                  ),
                ),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
