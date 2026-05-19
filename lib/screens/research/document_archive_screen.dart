// Document-Archive (R5): drei Tabs - ARCHIV (Volltextsuche ueber
// research_documents), NEU LADEN (PDF via file_picker + syncfusion
// Text-Extraktion + Google-Translator), QUELLEN (kuratierte PDF-Quellen).

import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:translator/translator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/invisible_auth_service.dart';
import '../../services/supabase_service.dart';

const _accent = Color(0xFFE53935);
const _bg = Color(0xFF0A0A0A);
const _surface = Color(0xFF1A0000);

class DocumentArchiveScreen extends StatefulWidget {
  const DocumentArchiveScreen({super.key});

  @override
  State<DocumentArchiveScreen> createState() => _DocumentArchiveScreenState();
}

class _DocumentArchiveScreenState extends State<DocumentArchiveScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text('DOKUMENTEN-ARCHIV',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        iconTheme: const IconThemeData(color: _accent),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: _accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          tabs: const [
            Tab(text: 'ARCHIV'),
            Tab(text: 'NEU LADEN'),
            Tab(text: 'QUELLEN'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _ArchiveTab(),
          _UploadTab(),
          _SourcesTab(),
        ],
      ),
    );
  }
}

// ─── ARCHIV-TAB ──────────────────────────────────────────────────────────────

class _ArchiveTab extends StatefulWidget {
  const _ArchiveTab();

  @override
  State<_ArchiveTab> createState() => _ArchiveTabState();
}

class _ArchiveTabState extends State<_ArchiveTab> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final client = supabase;
      dynamic q = client.from('research_documents').select();
      final search = _searchCtrl.text.trim();
      if (search.isNotEmpty) {
        q = q.or(
            'title.ilike.%$search%,extracted_text.ilike.%$search%,translated_text.ilike.%$search%');
      }
      final res = await q.order('downloaded_at', ascending: false).limit(100);
      if (!mounted) return;
      setState(() {
        _docs = (res as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Archive load: $e');
      if (!mounted) return;
      setState(() {
        _docs = [];
        _loading = false;
      });
    }
  }

  void _onSearch(String s) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Volltextsuche ueber Dokumente ...',
              hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: _accent, size: 20),
              filled: true,
              fillColor: _surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _accent.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _accent),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: _accent))
              : _docs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Noch keine Dokumente.\nLade ein PDF im Tab NEU LADEN.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: _accent,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _docs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => _docCard(_docs[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _docCard(Map<String, dynamic> d) {
    return InkWell(
      onTap: () => _showDocDetail(d),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: _accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(d['title'] as String? ?? 'Ohne Titel',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (d['language'] as String? ?? 'en').toUpperCase(),
                    style: const TextStyle(
                        color: _accent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              d['source_name'] as String? ?? '',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11),
            ),
            if (d['extracted_text'] != null) ...[
              const SizedBox(height: 6),
              Text(
                (d['extracted_text'] as String)
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .trim(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDocDetail(Map<String, dynamic> d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, sc) => _DocDetailSheet(doc: d, scrollController: sc),
      ),
    );
  }
}

class _DocDetailSheet extends StatefulWidget {
  final Map<String, dynamic> doc;
  final ScrollController scrollController;
  const _DocDetailSheet(
      {required this.doc, required this.scrollController});

  @override
  State<_DocDetailSheet> createState() => _DocDetailSheetState();
}

class _DocDetailSheetState extends State<_DocDetailSheet> {
  bool _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.doc;
    final orig = d['extracted_text'] as String? ?? '';
    final translated = d['translated_text'] as String? ?? '';
    final hasTranslation = translated.isNotEmpty;
    final text = _showTranslation && hasTranslation ? translated : orig;
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(d['title'] as String? ?? 'Ohne Titel',
              style: const TextStyle(
                  color: _accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(d['source_name'] as String? ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          if (d['original_url'] != null) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final uri = Uri.parse(d['original_url'] as String);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                }
              },
              child: Text(d['original_url'] as String,
                  style: TextStyle(
                      color: _accent.withValues(alpha: 0.85),
                      fontSize: 11,
                      decoration: TextDecoration.underline)),
            ),
          ],
          Divider(color: _accent.withValues(alpha: 0.2), height: 28),
          if (hasTranslation)
            Row(
              children: [
                FilterChip(
                  label: const Text('Original'),
                  selected: !_showTranslation,
                  onSelected: (_) =>
                      setState(() => _showTranslation = false),
                  backgroundColor: _surface,
                  selectedColor: _accent,
                  labelStyle: TextStyle(
                      color: !_showTranslation
                          ? Colors.white
                          : Colors.white70,
                      fontSize: 11),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Deutsch'),
                  selected: _showTranslation,
                  onSelected: (_) =>
                      setState(() => _showTranslation = true),
                  backgroundColor: _surface,
                  selectedColor: _accent,
                  labelStyle: TextStyle(
                      color: _showTranslation
                          ? Colors.white
                          : Colors.white70,
                      fontSize: 11),
                ),
              ],
            ),
          const SizedBox(height: 12),
          SelectableText(
            text.isEmpty ? 'Kein Text extrahiert.' : text,
            style: const TextStyle(
                color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── UPLOAD-TAB ──────────────────────────────────────────────────────────────

class _UploadTab extends StatefulWidget {
  const _UploadTab();

  @override
  State<_UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<_UploadTab> {
  final _titleCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController(text: 'Manueller Upload');
  final _urlCtrl = TextEditingController();
  final _languageCtrl = TextEditingController(text: 'en');
  String? _fileName;
  Uint8List? _fileBytes;
  String? _extractedText;
  String? _translatedText;
  bool _processing = false;
  bool _translating = false;
  String _status = '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _sourceCtrl.dispose();
    _urlCtrl.dispose();
    _languageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _status = 'Datei waehlen ...');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _status = '');
        return;
      }
      final f = result.files.first;
      if (f.bytes == null) {
        setState(() => _status = 'Datei konnte nicht gelesen werden.');
        return;
      }
      setState(() {
        _fileName = f.name;
        _fileBytes = f.bytes;
        _status = 'Datei geladen: ${f.name}';
        if (_titleCtrl.text.isEmpty) {
          _titleCtrl.text =
              f.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
        }
      });
      await _extract();
    } catch (e) {
      setState(() => _status = 'Fehler: $e');
    }
  }

  Future<void> _loadFromUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _status = 'PDF wird geladen ...';
      _processing = true;
    });
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        setState(() {
          _processing = false;
          _status = 'HTTP ${res.statusCode}';
        });
        return;
      }
      setState(() {
        _fileBytes = res.bodyBytes;
        _fileName = url.split('/').last;
        if (_titleCtrl.text.isEmpty) _titleCtrl.text = _fileName!;
        _status = 'PDF geladen (${(res.bodyBytes.length / 1024).round()} KB)';
        _processing = false;
      });
      await _extract();
    } catch (e) {
      setState(() {
        _processing = false;
        _status = 'Fehler: $e';
      });
    }
  }

  Future<void> _extract() async {
    final bytes = _fileBytes;
    if (bytes == null) return;
    setState(() {
      _processing = true;
      _status = 'Text wird extrahiert ...';
    });
    try {
      final doc = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(doc);
      final text = extractor.extractText();
      doc.dispose();
      setState(() {
        _extractedText = text;
        _processing = false;
        _status =
            'Extraktion fertig (${text.length} Zeichen, ${text.split(RegExp(r"\s+")).length} Woerter)';
      });
    } catch (e) {
      setState(() {
        _processing = false;
        _status = 'Extraktion fehlgeschlagen: $e';
      });
    }
  }

  Future<void> _translate() async {
    if (_extractedText == null || _extractedText!.isEmpty) return;
    setState(() {
      _translating = true;
      _status = 'Uebersetzung ...';
    });
    try {
      // Chunk because translator API has size limits.
      const chunkSize = 4000;
      final buf = StringBuffer();
      final translator = GoogleTranslator();
      for (int i = 0; i < _extractedText!.length; i += chunkSize) {
        final end = (i + chunkSize).clamp(0, _extractedText!.length);
        final chunk = _extractedText!.substring(i, end);
        final tr = await translator.translate(chunk,
            from: _languageCtrl.text.trim().isEmpty
                ? 'auto'
                : _languageCtrl.text.trim(),
            to: 'de');
        buf.write(tr.text);
        buf.write('\n');
      }
      setState(() {
        _translatedText = buf.toString();
        _translating = false;
        _status = 'Uebersetzung fertig';
      });
    } catch (e) {
      setState(() {
        _translating = false;
        _status = 'Uebersetzung fehlgeschlagen: $e';
      });
    }
  }

  Future<void> _save() async {
    if (_extractedText == null || _extractedText!.isEmpty) {
      setState(() => _status = 'Keine Daten zum Speichern.');
      return;
    }
    setState(() {
      _processing = true;
      _status = 'Speichern ...';
    });
    try {
      final client = supabase;
      final legacy = InvisibleAuthService().userId;
      await client.from('research_documents').insert({
        'title': _titleCtrl.text.trim().isEmpty
            ? (_fileName ?? 'Untitled')
            : _titleCtrl.text.trim(),
        'source_name': _sourceCtrl.text.trim(),
        'original_url': _urlCtrl.text.trim().isEmpty
            ? 'local://${_fileName ?? "upload"}'
            : _urlCtrl.text.trim(),
        'language': _languageCtrl.text.trim().isEmpty
            ? 'en'
            : _languageCtrl.text.trim(),
        'extracted_text': _extractedText,
        'translated_text': _translatedText,
        'file_size_kb':
            _fileBytes == null ? null : (_fileBytes!.length / 1024).round(),
        'user_id': client.auth.currentUser?.id,
        'legacy_user_id': client.auth.currentUser == null ? legacy : null,
      });
      setState(() {
        _processing = false;
        _status = 'Gespeichert.';
        _fileBytes = null;
        _fileName = null;
        _extractedText = null;
        _translatedText = null;
        _titleCtrl.clear();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Dokument gespeichert'),
            backgroundColor: _accent),
      );
    } catch (e) {
      setState(() {
        _processing = false;
        _status = 'Speichern fehlgeschlagen: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field(_titleCtrl, 'Titel'),
        const SizedBox(height: 8),
        _field(_sourceCtrl, 'Quelle (z.B. CIA FOIA, FBI Vault)'),
        const SizedBox(height: 8),
        _field(_urlCtrl, 'Original-URL (optional)'),
        const SizedBox(height: 8),
        _field(_languageCtrl, 'Sprache (Code, z.B. en/de/fr)'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text('PDF aus Datei',
                    style: TextStyle(color: Colors.white)),
                onPressed: _processing ? null : _pickFile,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _accent),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                icon: const Icon(Icons.cloud_download),
                label: const Text('Aus URL'),
                onPressed: _processing ? null : _loadFromUrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_status.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _accent.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (_processing || _translating)
                  const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            color: _accent, strokeWidth: 2)),
                  ),
                Expanded(
                  child: Text(_status,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
          ),
        if (_extractedText != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _accent.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('EXTRAHIERTER TEXT (Vorschau)',
                    style: TextStyle(
                        color: _accent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                  _extractedText!.length > 500
                      ? '${_extractedText!.substring(0, 500)} ...'
                      : _extractedText!,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: const BorderSide(color: _accent),
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: const Icon(Icons.translate),
                  label:
                      Text(_translatedText == null ? 'Uebersetzen' : 'Erneut'),
                  onPressed: _translating ? null : _translate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('Speichern',
                      style: TextStyle(color: Colors.white)),
                  onPressed: _processing ? null : _save,
                ),
              ),
            ],
          ),
        ],
        if (_translatedText != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _accent.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('UEBERSETZUNG (Vorschau)',
                    style: TextStyle(
                        color: _accent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(
                  _translatedText!.length > 500
                      ? '${_translatedText!.substring(0, 500)} ...'
                      : _translatedText!,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _field(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _accent.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent),
        ),
      ),
    );
  }
}

// ─── QUELLEN-TAB ─────────────────────────────────────────────────────────────

class _PdfSource {
  final String title;
  final String description;
  final String url;
  final IconData icon;
  const _PdfSource(
      {required this.title,
      required this.description,
      required this.url,
      required this.icon});
}

class _SourcesTab extends StatelessWidget {
  const _SourcesTab();

  static const _sources = <_PdfSource>[
    _PdfSource(
        title: 'CIA FOIA Reading Room',
        description: 'Declassified CIA-Dokumente als PDF',
        url: 'https://www.cia.gov/readingroom/',
        icon: Icons.folder_open),
    _PdfSource(
        title: 'FBI Vault',
        description: 'FBI FOIA Documents',
        url: 'https://vault.fbi.gov',
        icon: Icons.account_balance),
    _PdfSource(
        title: 'National Security Archive',
        description: 'Declassified US Government Records',
        url: 'https://nsarchive.gwu.edu',
        icon: Icons.security),
    _PdfSource(
        title: 'Internet Archive Books',
        description: 'Historische Dokumente und Buecher',
        url: 'https://archive.org/details/texts',
        icon: Icons.library_books),
    _PdfSource(
        title: 'WikiLeaks Document Search',
        description: 'Geleakte Dokumente',
        url: 'https://search.wikileaks.org',
        icon: Icons.shield_outlined),
    _PdfSource(
        title: 'Government Attic',
        description: 'Originale FOIA-Antworten',
        url: 'https://www.governmentattic.org',
        icon: Icons.inventory_2_outlined),
    _PdfSource(
        title: 'Black Vault Document Archive',
        description: 'FOIA & UFO/UAP-Dokumente',
        url: 'https://documents.theblackvault.com',
        icon: Icons.lock_open),
    _PdfSource(
        title: 'UK National Archives',
        description: 'Britische Staatsarchive',
        url: 'https://discovery.nationalarchives.gov.uk',
        icon: Icons.flag_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _sources.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final s = _sources[i];
        return Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            leading: Icon(s.icon, color: _accent),
            title: Text(s.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            subtitle: Text(s.description,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 12)),
            trailing:
                const Icon(Icons.open_in_new, color: _accent, size: 16),
            onTap: () async {
              final uri = Uri.parse(s.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri,
                    mode: LaunchMode.externalApplication);
              }
            },
          ),
        );
      },
    );
  }
}
