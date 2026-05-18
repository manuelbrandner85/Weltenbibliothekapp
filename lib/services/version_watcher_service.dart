// Version-Watcher-Service: Liest Wayback-Snapshots einer URL via CDX-API
// und berechnet Text-Diffs zwischen Versionen.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

class WaybackSnapshot {
  final String urlKey;
  final String timestamp; // YYYYMMDDhhmmss
  final String originalUrl;
  final String mimeType;
  final int statusCode;
  final String digest; // SHA1 hash — gleich = identischer Inhalt
  final int length;

  const WaybackSnapshot({
    required this.urlKey,
    required this.timestamp,
    required this.originalUrl,
    required this.mimeType,
    required this.statusCode,
    required this.digest,
    required this.length,
  });

  DateTime get date {
    try {
      return DateTime.utc(
        int.parse(timestamp.substring(0, 4)),
        int.parse(timestamp.substring(4, 6)),
        int.parse(timestamp.substring(6, 8)),
        int.parse(timestamp.substring(8, 10)),
        int.parse(timestamp.substring(10, 12)),
        int.parse(timestamp.substring(12, 14)),
      );
    } catch (_) {
      return DateTime.utc(1970);
    }
  }

  String get fmtDate {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String get viewUrl => 'https://web.archive.org/web/$timestamp/$originalUrl';
  String get rawUrl => 'https://web.archive.org/web/${timestamp}id_/$originalUrl';
}

class DiffLine {
  final String text;
  final int kind; // -1 = removed, 0 = unchanged, +1 = added
  const DiffLine(this.text, this.kind);
}

class VersionWatcherService {
  static const Duration _timeout = Duration(seconds: 20);

  Future<List<WaybackSnapshot>> getSnapshots(String url, {int limit = 100}) async {
    try {
      final uri = Uri.parse('https://web.archive.org/cdx/search/cdx')
          .replace(queryParameters: {
        'url': url,
        'output': 'json',
        'limit': '$limit',
        'fl': 'urlkey,timestamp,original,mimetype,statuscode,digest,length',
        'collapse': 'digest', // gleiche Inhalte einklappen
      });
      final res = await http.get(uri,
          headers: const {'Accept': 'application/json'}).timeout(_timeout);
      if (res.statusCode != 200) {
        if (kDebugMode) debugPrint('Wayback CDX ${res.statusCode}');
        return const [];
      }
      final data = jsonDecode(res.body) as List;
      if (data.isEmpty) return const [];
      // First row = headers
      final rows = data.skip(1).toList();
      return rows.map((r) {
        final list = r as List;
        if (list.length < 7) return null;
        return WaybackSnapshot(
          urlKey: list[0].toString(),
          timestamp: list[1].toString(),
          originalUrl: list[2].toString(),
          mimeType: list[3].toString(),
          statusCode: int.tryParse(list[4].toString()) ?? 0,
          digest: list[5].toString(),
          length: int.tryParse(list[6].toString()) ?? 0,
        );
      }).whereType<WaybackSnapshot>().toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      if (kDebugMode) debugPrint('CDX error: $e');
      return const [];
    }
  }

  Future<String?> getSnapshotText(WaybackSnapshot snap) async {
    try {
      final res = await http.get(Uri.parse(snap.rawUrl),
          headers: const {'Accept': 'text/html,text/plain'}).timeout(_timeout);
      if (res.statusCode != 200) return null;
      return _htmlToText(res.body);
    } catch (e) {
      if (kDebugMode) debugPrint('Snapshot fetch: $e');
      return null;
    }
  }

  String _htmlToText(String html) {
    // Sehr einfach: Tags raus, Whitespace normalisieren
    var t = html;
    // Script/Style/Comments entfernen
    t = t.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
    // <br> und block-Tags zu Newlines
    t = t.replaceAll(RegExp(r'<br[^>]*>', caseSensitive: false), '\n');
    t = t.replaceAll(RegExp(r'</?(p|div|h[1-6]|li|tr|td|th)[^>]*>', caseSensitive: false), '\n');
    // Restliche Tags weg
    t = t.replaceAll(RegExp(r'<[^>]+>'), ' ');
    // HTML-Entities
    t = t
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    // Whitespace
    t = t.replaceAll(RegExp(r'[ \t]+'), ' ');
    t = t.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
    return t.trim();
  }

  // Simple line-based diff (LCS-Algorithmus light)
  List<DiffLine> diff(String oldText, String newText) {
    final oldLines = oldText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final newLines = newText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final out = <DiffLine>[];
    final oldSet = oldLines.toSet();
    final newSet = newLines.toSet();
    // Pass 1: removed (in old but not new)
    for (final l in oldLines) {
      if (!newSet.contains(l)) {
        out.add(DiffLine(l, -1));
      }
    }
    // Pass 2: added (in new but not old)
    for (final l in newLines) {
      if (!oldSet.contains(l)) {
        out.add(DiffLine(l, 1));
      }
    }
    // Pass 3: unchanged (in both, max 5 stichproben damit nicht zu lang)
    int sample = 0;
    for (final l in newLines) {
      if (oldSet.contains(l) && sample < 5) {
        out.add(DiffLine(l, 0));
        sample++;
      }
    }
    return out;
  }
}
