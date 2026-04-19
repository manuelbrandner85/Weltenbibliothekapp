import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Markdown-Light Renderer für Chat-Nachrichten.
///
/// Unterstützt:
///  - **fett** / *fett*
///  - __kursiv__ / _kursiv_
///  - `code`
///  - ~~durchgestrichen~~
///  - http(s)://-Links (klickbar, öffnet extern)
///
/// Absichtlich minimalistisch: keine Header/Listen/Bilder — Chat-Input
/// bleibt kurz und eindeutig lesbar.
class ChatMarkdownText extends StatelessWidget {
  const ChatMarkdownText(
    this.text, {
    super.key,
    this.style,
    this.linkColor,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final Color? linkColor;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final base = style ??
        const TextStyle(color: Colors.white, fontSize: 14, height: 1.35);
    final link = linkColor ?? const Color(0xFF80D8FF);
    final spans = _parse(text, base, link);
    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  // ─── Parser ─────────────────────────────────────────────────────
  // Reihenfolge: URL > Code > Fett > Kursiv > Strike.
  // Einfacher Tokenizer, kein echter AST — reicht für Chat-Länge.

  static final _urlRe = RegExp(r'https?://[^\s)]+');
  static final _codeRe = RegExp(r'`([^`]+)`');
  static final _boldRe = RegExp(r'\*\*([^\*]+)\*\*|\*([^\*\s][^\*]*?)\*');
  static final _italicRe = RegExp(r'__([^_]+)__|(?<![\w_])_([^_\s][^_]*?)_(?![\w_])');
  static final _strikeRe = RegExp(r'~~([^~]+)~~');

  List<InlineSpan> _parse(String input, TextStyle base, Color linkColor) {
    // 1) URLs rausziehen, Placeholder einsetzen.
    final urlHits = <_Hit>[];
    input.replaceAllMapped(_urlRe, (m) {
      urlHits.add(_Hit(m.start, m.end, m.group(0)!, _HitType.url));
      return m.group(0)!;
    });
    return _splitAndStyle(input, base, linkColor, urlHits);
  }

  List<InlineSpan> _splitAndStyle(
    String input,
    TextStyle base,
    Color linkColor,
    List<_Hit> urlHits,
  ) {
    // Alle Hits (URL + Code + Bold + Italic + Strike) sammeln, dann mergen.
    final hits = <_Hit>[...urlHits];
    for (final m in _codeRe.allMatches(input)) {
      hits.add(_Hit(m.start, m.end, m.group(1)!, _HitType.code));
    }
    for (final m in _boldRe.allMatches(input)) {
      hits.add(_Hit(m.start, m.end, m.group(1) ?? m.group(2) ?? '', _HitType.bold));
    }
    for (final m in _italicRe.allMatches(input)) {
      hits.add(_Hit(m.start, m.end, m.group(1) ?? m.group(2) ?? '', _HitType.italic));
    }
    for (final m in _strikeRe.allMatches(input)) {
      hits.add(_Hit(m.start, m.end, m.group(1)!, _HitType.strike));
    }

    // Nach Start sortieren; Overlaps: der früheste gewinnt, Rest verworfen.
    hits.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_Hit>[];
    int cursor = 0;
    for (final h in hits) {
      if (h.start < cursor) continue;
      merged.add(h);
      cursor = h.end;
    }

    final spans = <InlineSpan>[];
    int idx = 0;
    for (final h in merged) {
      if (h.start > idx) {
        spans.add(TextSpan(text: input.substring(idx, h.start), style: base));
      }
      spans.add(_buildSpan(h, base, linkColor));
      idx = h.end;
    }
    if (idx < input.length) {
      spans.add(TextSpan(text: input.substring(idx), style: base));
    }
    return spans;
  }

  InlineSpan _buildSpan(_Hit h, TextStyle base, Color linkColor) {
    switch (h.type) {
      case _HitType.url:
        return TextSpan(
          text: h.content,
          style: base.copyWith(
            color: linkColor,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _openUrl(h.content),
        );
      case _HitType.code:
        return TextSpan(
          text: h.content,
          style: base.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            letterSpacing: 0.2,
          ),
        );
      case _HitType.bold:
        return TextSpan(
          text: h.content,
          style: base.copyWith(fontWeight: FontWeight.w700),
        );
      case _HitType.italic:
        return TextSpan(
          text: h.content,
          style: base.copyWith(fontStyle: FontStyle.italic),
        );
      case _HitType.strike:
        return TextSpan(
          text: h.content,
          style: base.copyWith(decoration: TextDecoration.lineThrough),
        );
    }
  }

  static Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

enum _HitType { url, code, bold, italic, strike }

class _Hit {
  final int start;
  final int end;
  final String content;
  final _HitType type;
  const _Hit(this.start, this.end, this.content, this.type);
}
