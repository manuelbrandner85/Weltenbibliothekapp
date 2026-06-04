import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../theme/wb_cinematic_tokens.dart';
import '../cinematic/wb_glass_app_bar.dart';
import '../materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Generic worker-backed intel list screen.
// Fetches `${workerUrl}{endpoint}`, reads the array under `listKey` (default
// "items"), maps each entry to an [IntelRow] via [mapper] and renders cards.
// Shared by all key-free world tools (earthquakes, asteroids, moon, etc.).
// ─────────────────────────────────────────────────────────────────────────────

/// One rendered row in the result list, produced by a per-tool mapper.
class IntelRow {
  final String title;
  final String subtitle;
  final String badge;
  final Color? badgeColor;
  final IconData icon;
  final String url;

  const IntelRow({
    required this.title,
    this.subtitle = '',
    this.badge = '',
    this.badgeColor,
    this.icon = Icons.chevron_right_rounded,
    this.url = '',
  });
}

class IntelListScreen extends StatefulWidget {
  const IntelListScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.world,
    required this.endpoint,
    required this.mapper,
    required this.sourceText,
    this.sources = const [],
    this.listKey = 'items',
    this.surface = const Color(0xFF12121A),
    this.background = const Color(0xFF05060C),
    this.emptyText = 'Keine aktuellen Eintraege gefunden.',
    this.headerNote,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final WBWorld world;

  /// Path incl. query string, relative to the worker URL (e.g. `/api/intel/moon`).
  final String endpoint;

  /// JSON field holding the result array.
  final String listKey;

  /// Maps one raw entry to a displayable [IntelRow].
  final IntelRow Function(Map<String, dynamic>) mapper;

  final String sourceText;
  final List<OsintSource> sources;
  final Color surface;
  final Color background;
  final String emptyText;

  /// Optional note shown above the list (e.g. an explanation of the values).
  final String? headerNote;

  @override
  State<IntelListScreen> createState() => _IntelListScreenState();
}

class _IntelListScreenState extends State<IntelListScreen> {
  bool _loading = false;
  String? _error;
  List<IntelRow> _rows = const [];
  String _source = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('${ApiConfig.workerUrl}${widget.endpoint}');
      final resp = await http.get(uri).timeout(const Duration(seconds: 25));
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = (data[widget.listKey] as List?) ?? const [];
      final rows = list
          .whereType<Map>()
          .map((e) => widget.mapper(Map<String, dynamic>.from(e)))
          .toList();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _source = (data['source'] ?? '').toString();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Abruf fehlgeschlagen. Bitte erneut versuchen.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.55);
    final border = widget.accent.withValues(alpha: 0.22);
    return Scaffold(
      backgroundColor: widget.background,
      appBar: WBGlassAppBar(
        world: widget.world,
        titleWidget: Row(children: [
          Icon(widget.icon, color: widget.accent, size: 22),
          const SizedBox(width: 8),
          Flexible(
            child: Text(widget.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: widget.accent),
            tooltip: 'Aktualisieren',
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: widget.accent,
        backgroundColor: widget.surface,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OsintSourceBanner(
              source: widget.sourceText,
              accent: widget.accent,
              sources: widget.sources,
            ),
            if (widget.headerNote != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 2),
                child: Text(widget.headerNote!,
                    style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
              ),
            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                    child: CircularProgressIndicator(color: widget.accent)),
              )
            else if (_error != null)
              _box(
                  border,
                  Row(children: [
                    Icon(Icons.error_outline, color: widget.accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: TextStyle(
                                color: widget.accent, fontSize: 13))),
                  ]))
            else if (_rows.isEmpty)
              _box(
                  border,
                  Text(widget.emptyText,
                      style: TextStyle(color: muted, fontSize: 13)))
            else ...[
              if (_source.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 2),
                  child: Text('${_rows.length} Eintraege - Quelle: $_source',
                      style: TextStyle(color: muted, fontSize: 11)),
                ),
              ..._rows.map((r) => _rowCard(r, border, muted)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _box(Color border, Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: child,
      );

  Widget _rowCard(IntelRow r, Color border, Color muted) {
    final badgeColor = r.badgeColor ?? widget.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(r.icon, color: badgeColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600)),
            if (r.subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(r.subtitle,
                  style: TextStyle(color: muted, fontSize: 11.5, height: 1.3)),
            ],
          ]),
        ),
        if (r.badge.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
            ),
            child: Text(r.badge,
                style: TextStyle(
                    color: badgeColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ]),
    );
  }
}
