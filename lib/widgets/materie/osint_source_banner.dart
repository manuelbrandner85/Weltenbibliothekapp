import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// M1: Einheitliches Quellen-/Disclaimer-Banner fuer OSINT-Tools.
///
/// Zeigt transparent an, woher die Daten kommen und mit welchem
/// Vertrauensgrad sie zu behandeln sind. Optional klickbare Quellen-Links.
///
/// Verwendung:
/// ```dart
/// OsintSourceBanner(
///   source: 'Live-Abfrage ueber Weltenbibliothek-Worker (WHOIS/DNS).',
///   sources: [OsintSource('ICANN WHOIS', 'https://lookup.icann.org')],
/// )
/// ```
class OsintSourceBanner extends StatelessWidget {
  const OsintSourceBanner({
    super.key,
    required this.source,
    this.sources = const [],
    this.accent = const Color(0xFFE53935),
    this.isDemo = false,
  });

  /// Kurzbeschreibung der Datenherkunft (deutsche UI-Sprache).
  final String source;

  /// Optionale klickbare Originalquellen.
  final List<OsintSource> sources;

  /// Akzentfarbe der jeweiligen Welt/des Tools.
  final Color accent;

  /// true = Demo-/Beispieldaten statt echter Abfrage (gelber Warnstil).
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final color = isDemo ? const Color(0xFFFFB300) : accent;
    final icon = isDemo ? Icons.science_outlined : Icons.verified_outlined;
    final label = isDemo ? 'Demo-Daten' : 'Datenquelle';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      source,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final s in sources) _SourceChip(source: s, color: color),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Oeffentlich zugaengliche Daten - bitte kritisch pruefen, '
            'ersetzt keine eigene Recherche.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontStyle: FontStyle.italic,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Eine benannte, optional verlinkte Originalquelle.
class OsintSource {
  const OsintSource(this.label, [this.url]);
  final String label;
  final String? url;
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source, required this.color});
  final OsintSource source;
  final Color color;

  Future<void> _open() async {
    final url = source.url;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clickable = source.url != null;
    return GestureDetector(
      onTap: clickable ? _open : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (clickable) ...[
              Icon(Icons.open_in_new, size: 11, color: color),
              const SizedBox(width: 5),
            ],
            Text(
              source.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
