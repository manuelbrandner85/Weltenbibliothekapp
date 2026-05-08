import 'package:flutter/material.dart';
import 'image_analysis_tool.dart';
import 'data_leak_tool.dart';
import 'crypto_tracker_tool.dart';
import 'domain_osint_tool.dart';
import 'phone_osint_tool.dart';
import 'ai_detector_tool.dart';
import 'geo_analysis_tool.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OSINT Tools Hub — Einstiegspunkt für alle 7 Standalone-Tools
// ─────────────────────────────────────────────────────────────────────────────

const _kBg      = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent  = Color(0xFFE53935);
const _kText    = Colors.white;
const _kMuted   = Color(0xFFB0A0A0);
const _kBorder  = Color(0x33E53935);

class OsintToolsHub extends StatelessWidget {
  const OsintToolsHub({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      _ToolDef(
        icon: Icons.image_search_rounded,
        label: 'Bildanalyse',
        sub: 'EXIF, Rückwärtssuche',
        color: const Color(0xFFE53935),
        screen: const ImageAnalysisTool(),
      ),
      _ToolDef(
        icon: Icons.security_rounded,
        label: 'Datenleck-Prüfer',
        sub: 'E-Mail in Leaks suchen',
        color: const Color(0xFFFF5722),
        screen: const DataLeakTool(),
      ),
      _ToolDef(
        icon: Icons.currency_bitcoin_rounded,
        label: 'Krypto-Verfolger',
        sub: 'BTC & ETH Adressen',
        color: const Color(0xFFF7931A),
        screen: const CryptoTrackerTool(),
      ),
      _ToolDef(
        icon: Icons.language_rounded,
        label: 'Domain-OSINT',
        sub: 'WHOIS, DNS, Registrar',
        color: const Color(0xFF29B6F6),
        screen: const DomainOsintTool(),
      ),
      _ToolDef(
        icon: Icons.phone_in_talk_rounded,
        label: 'Telefon-OSINT',
        sub: 'Vorwahl & Länderinfo',
        color: const Color(0xFF66BB6A),
        screen: const PhoneOsintTool(),
      ),
      _ToolDef(
        icon: Icons.smart_toy_rounded,
        label: 'KI-Detektor',
        sub: 'Menschlich oder KI?',
        color: const Color(0xFFAB47BC),
        screen: const AiDetectorTool(),
      ),
      _ToolDef(
        icon: Icons.map_rounded,
        label: 'Geo-Analyse',
        sub: 'Orte, Wetter, Wikipedia',
        color: const Color(0xFF26A69A),
        screen: const GeoAnalysisTool(),
      ),
    ];

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kText,
        title: Row(children: [
          Icon(Icons.manage_search_rounded, color: _kAccent, size: 22),
          const SizedBox(width: 8),
          const Text('OSINT Tools', style: TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '7 Open-Source-Intelligence-Tools für Recherche und Verifikation.',
            style: const TextStyle(color: _kMuted, fontSize: 13),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemCount: tools.length,
            itemBuilder: (context, i) => _ToolCard(tool: tools[i]),
          ),
        ),
      ]),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final _ToolDef tool;
  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => tool.screen)),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tool.color.withValues(alpha: 0.25), width: 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tool.color.withValues(alpha: 0.08),
              _kSurface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tool.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tool.color.withValues(alpha: 0.3)),
              ),
              child: Icon(tool.icon, color: tool.color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(tool.label, style: const TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 3),
            Text(tool.sub, style: const TextStyle(color: _kMuted, fontSize: 11), overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Icon(Icons.arrow_forward_ios_rounded, color: tool.color.withValues(alpha: 0.6), size: 12),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _ToolDef {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final Widget screen;
  const _ToolDef({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.screen,
  });
}
