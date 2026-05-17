// 📄 PDF-READER — In-App-PDF-Viewer mit Bookmark-Liste
//
// Auf Mobile: lädt PDF via http in Temp-File → rendert mit flutter_pdfview.
// Auf Web: zeigt PDF in <iframe> (Browser-eigener PDF.js).
// Bookmarks persistiert in SharedPreferences.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../widgets/_pdf_web_iframe_stub.dart'
    if (dart.library.html) '../../../widgets/_pdf_web_iframe_web.dart';

class PdfReaderScreen extends StatefulWidget {
  final String? initialUrl;
  final String? initialTitle;
  const PdfReaderScreen({super.key, this.initialUrl, this.initialTitle});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF1A0F2E);
  static const _accent = Color(0xFF7C4DFF);
  static const _kvKey = 'pdf_bookmarks_v1';

  final _urlCtrl = TextEditingController();
  List<_Bookmark> _bookmarks = [];
  String? _viewingUrl;
  String? _viewingTitle;
  String? _localPath;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    if (widget.initialUrl != null) {
      _viewingUrl = widget.initialUrl;
      _viewingTitle = widget.initialTitle ?? 'PDF';
      _urlCtrl.text = widget.initialUrl!;
      _downloadIfNeeded();
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kvKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        if (mounted) {
          setState(() => _bookmarks = list
              .map((e) => _Bookmark.fromJson(e as Map<String, dynamic>))
              .toList());
        }
      } catch (_) {}
    }
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kvKey,
        jsonEncode(_bookmarks.map((b) => b.toJson()).toList()));
  }

  Future<void> _addBookmark() async {
    if (_viewingUrl == null) return;
    final title = _viewingTitle ?? _viewingUrl!.split('/').last;
    if (_bookmarks.any((b) => b.url == _viewingUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bereits gespeichert'),
        backgroundColor: _accent,
      ));
      return;
    }
    setState(() {
      _bookmarks.insert(0, _Bookmark(
        url: _viewingUrl!,
        title: title,
        addedAt: DateTime.now(),
      ));
    });
    await _saveBookmarks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🔖 Lesezeichen gespeichert'),
        backgroundColor: _accent,
      ));
    }
  }

  Future<void> _openUrl(String url, [String? title]) async {
    setState(() {
      _viewingUrl = url;
      _viewingTitle = title ?? url.split('/').last;
      _urlCtrl.text = url;
    });
    await _downloadIfNeeded();
  }

  Future<void> _downloadIfNeeded() async {
    if (kIsWeb) return; // Web nutzt iframe direkt, kein Download nötig
    if (_viewingUrl == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(Uri.parse(_viewingUrl!))
          .timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) {
        setState(() {
          _loading = false;
          _error = 'PDF-Download fehlgeschlagen (${res.statusCode})';
        });
        return;
      }
      final dir = await getTemporaryDirectory();
      final fname = 'pdf_${_viewingUrl!.hashCode.abs()}.pdf';
      final f = File('${dir.path}/$fname');
      await f.writeAsBytes(res.bodyBytes);
      if (mounted) {
        setState(() {
          _localPath = f.path;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Fehler: $e';
        });
      }
    }
  }

  void _close() {
    setState(() {
      _viewingUrl = null;
      _viewingTitle = null;
      _localPath = null;
      _urlCtrl.clear();
    });
  }

  Future<void> _removeBookmark(_Bookmark b) async {
    setState(() => _bookmarks.removeWhere((x) => x.url == b.url));
    await _saveBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        title: Row(children: [
          const Text('📄', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_viewingTitle ?? 'PDF-Reader',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ]),
        actions: [
          if (_viewingUrl != null)
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: 'Lesezeichen',
              onPressed: _addBookmark,
            ),
          if (_viewingUrl != null)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Schließen',
              onPressed: _close,
            ),
        ],
      ),
      body: _viewingUrl != null ? _buildViewer() : _buildLibrary(),
    );
  }

  Widget _buildLibrary() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _urlCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'PDF-URL eingeben…',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: _surface,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _accent.withValues(alpha: 0.3)),
                  ),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) _openUrl(v.trim());
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final u = _urlCtrl.text.trim();
                if (u.isNotEmpty) _openUrl(u);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Icon(Icons.open_in_new, color: Colors.white),
            ),
          ]),
        ),
        Expanded(
          child: _bookmarks.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🔖', style: TextStyle(fontSize: 64)),
                        SizedBox(height: 16),
                        Text('Keine Lesezeichen',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text(
                          'Öffne eine PDF-URL oben und speichere sie über das Bookmark-Icon.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _bookmarks.length,
                  itemBuilder: (_, i) {
                    final b = _bookmarks[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _accent.withValues(alpha: 0.3)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: _accent),
                        title: Text(b.title,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(b.url,
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white38),
                          onPressed: () => _removeBookmark(b),
                        ),
                        onTap: () => _openUrl(b.url, b.title),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildViewer() {
    if (kIsWeb) {
      return buildPdfIframe(_viewingUrl!);
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _downloadIfNeeded,
                icon: const Icon(Icons.refresh),
                label: const Text('Erneut versuchen'),
                style: ElevatedButton.styleFrom(backgroundColor: _accent),
              ),
            ],
          ),
        ),
      );
    }
    if (_localPath == null) {
      return const Center(child: Text('Lade PDF…', style: TextStyle(color: Colors.white70)));
    }
    return PDFView(
      filePath: _localPath,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      fitPolicy: FitPolicy.WIDTH,
      onError: (e) {
        if (mounted) setState(() => _error = 'PDF-Render-Fehler: $e');
      },
    );
  }
}

class _Bookmark {
  final String url;
  final String title;
  final DateTime addedAt;
  const _Bookmark({required this.url, required this.title, required this.addedAt});

  Map<String, dynamic> toJson() => {
        'url': url,
        'title': title,
        'addedAt': addedAt.toIso8601String(),
      };

  factory _Bookmark.fromJson(Map<String, dynamic> j) => _Bookmark(
        url: j['url'] as String,
        title: j['title'] as String? ?? j['url'] as String,
        addedAt: DateTime.tryParse(j['addedAt'] as String? ?? '') ?? DateTime.now(),
      );
}
