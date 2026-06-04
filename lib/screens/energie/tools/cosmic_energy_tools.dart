import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/intel/intel_list_screen.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Energie tools (key-free). Moon phases (FarmSense), Schumann/geomagnetics
// (NOAA), daily mantra (ZenQuotes) and a local biorhythm calculator.
// ─────────────────────────────────────────────────────────────────────────────

const Color _kEnergie = Color(0xFF7C4DFF);
const Color _kEnSurface = Color(0xFF14101F);
const Color _kEnBg = Color(0xFF0A0814);

/// Mondphasen & Mondenergie (FarmSense).
class MoonPhaseScreen extends StatelessWidget {
  const MoonPhaseScreen({super.key});

  IconData _phaseIcon(String p) {
    if (p.contains('Neumond')) return Icons.brightness_3_rounded;
    if (p.contains('Voll')) return Icons.brightness_1_rounded;
    if (p.contains('Viertel')) return Icons.brightness_2_rounded;
    return Icons.nightlight_round;
  }

  @override
  Widget build(BuildContext context) {
    return IntelListScreen(
      title: 'Mondphasen',
      icon: Icons.nightlight_round,
      accent: _kEnergie,
      world: WBWorld.energie,
      surface: _kEnSurface,
      background: _kEnBg,
      endpoint: '/api/intel/moon',
      sourceText:
          'Aktuelle Mondphase und 7-Tage-Vorschau. Neumond steht fuer '
          'Neuanfaenge und Intention, Vollmond fuer Fuelle, Loslassen und '
          'Enthuellung. Viele Rituale richten sich nach dem Mondkalender.',
      sources: const [OsintSource('FarmSense', 'https://www.farmsense.net')],
      headerNote: 'Beleuchtung = sichtbarer Anteil. Alter = Tage seit Neumond.',
      mapper: (e) {
        final phase = (e['phase'] ?? '').toString();
        final illum = (e['illumination'] as num?)?.toInt() ?? 0;
        final age = (e['age'] as num?)?.toInt() ?? 0;
        return IntelRow(
          title: phase.isEmpty ? 'Mond' : phase,
          subtitle: '${e['date'] ?? ''}  -  Alter $age Tage',
          badge: '$illum%',
          badgeColor: _kEnergie,
          icon: _phaseIcon(phase),
        );
      },
    );
  }
}

/// Schumann-Resonanz / Geomagnetik (NOAA Kp-Index, Bewusstseins-Framing).
class SchumannResonanceScreen extends StatelessWidget {
  const SchumannResonanceScreen({super.key});

  Color _kpColor(double kp) {
    if (kp >= 7) return const Color(0xFFE040FB);
    if (kp >= 5) return const Color(0xFFFF6F00);
    if (kp >= 4) return const Color(0xFFFFC107);
    return const Color(0xFF66BB6A);
  }

  @override
  Widget build(BuildContext context) {
    return IntelListScreen(
      title: 'Erd-Resonanz',
      icon: Icons.graphic_eq_rounded,
      accent: _kEnergie,
      world: WBWorld.energie,
      surface: _kEnSurface,
      background: _kEnBg,
      endpoint: '/api/intel/spaceweather',
      sourceText:
          'Geomagnetische Aktivitaet der Erde (NOAA Kp-Index) als Mass fuer '
          'die elektromagnetische Umgebung. Hohe Werte (geomagnetische '
          'Stuerme) gelten in der Bewusstseinsforschung als Phasen erhoehter '
          'Sensitivitaet und veraenderten Wohlbefindens.',
      sources: const [OsintSource('NOAA SWPC', 'https://www.swpc.noaa.gov')],
      headerNote: 'Kp-Index 0-9. Hoehere Werte = staerkere geomagnetische Aktivitaet.',
      mapper: (e) {
        final kp = (e['kp'] as num?)?.toDouble() ?? 0;
        final time = (e['time'] ?? '').toString();
        return IntelRow(
          title: (e['level'] ?? 'Ruhig').toString(),
          subtitle: time.length >= 16 ? time.substring(0, 16) : time,
          badge: 'Kp ${kp.toStringAsFixed(0)}',
          badgeColor: _kpColor(kp),
          icon: Icons.graphic_eq_rounded,
        );
      },
    );
  }
}

/// Tages-Mantra / inspirierende Zitate (ZenQuotes).
class DailyMantraScreen extends StatelessWidget {
  const DailyMantraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntelListScreen(
      title: 'Tages-Mantra',
      icon: Icons.self_improvement_rounded,
      accent: _kEnergie,
      world: WBWorld.energie,
      surface: _kEnSurface,
      background: _kEnBg,
      endpoint: '/api/intel/mantra',
      sourceText:
          'Inspirierende Weisheiten und Zitate als taeglicher Impuls fuer '
          'Meditation und Reflexion. Zum Aktualisieren nach unten ziehen.',
      sources: const [OsintSource('ZenQuotes', 'https://zenquotes.io')],
      mapper: (e) {
        return IntelRow(
          title: (e['quote'] ?? '').toString(),
          subtitle: '— ${e['author'] ?? 'Unbekannt'}',
          icon: Icons.format_quote_rounded,
          badgeColor: _kEnergie,
        );
      },
    );
  }
}

/// Bio-Rhythmus — lokale Berechnung (Koerper/Seele/Geist-Zyklen).
class BiorhythmScreen extends StatefulWidget {
  const BiorhythmScreen({super.key});

  @override
  State<BiorhythmScreen> createState() => _BiorhythmScreenState();
}

class _BiorhythmScreenState extends State<BiorhythmScreen> {
  DateTime? _birth;

  int get _daysAlive =>
      _birth == null ? 0 : DateTime.now().difference(_birth!).inDays;

  double _cycle(int period) =>
      math.sin(2 * math.pi * (_daysAlive % period) / period);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kEnergie,
            surface: _kEnSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birth = picked);
  }

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.55);
    return Scaffold(
      backgroundColor: _kEnBg,
      appBar: WBGlassAppBar(
        world: WBWorld.energie,
        titleWidget: Row(children: const [
          Icon(Icons.favorite_rounded, color: _kEnergie, size: 22),
          SizedBox(width: 8),
          Text('Bio-Rhythmus',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const OsintSourceBanner(
            source:
                'Bio-Rhythmus nach der klassischen Drei-Zyklen-Lehre: Koerper '
                '(23 Tage), Seele (28 Tage), Geist (33 Tage). Berechnet aus '
                'deinem Geburtsdatum - rein lokal, keine Datenuebertragung.',
            accent: _kEnergie,
          ),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: _kEnSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kEnergie.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.cake_rounded, color: _kEnergie, size: 22),
                const SizedBox(width: 12),
                Text(
                  _birth == null
                      ? 'Geburtsdatum waehlen'
                      : '${_birth!.day.toString().padLeft(2, '0')}.${_birth!.month.toString().padLeft(2, '0')}.${_birth!.year}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(Icons.edit_calendar_rounded, color: muted, size: 18),
              ]),
            ),
          ),
          if (_birth != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 2),
              child: Text('$_daysAlive Tage gelebt',
                  style: TextStyle(color: muted, fontSize: 12)),
            ),
            _cycleCard('Koerper', '23-Tage-Zyklus - Kraft, Ausdauer, Vitalitaet',
                _cycle(23), const Color(0xFFE53935), Icons.fitness_center_rounded),
            _cycleCard('Seele', '28-Tage-Zyklus - Gefuehle, Stimmung, Kreativitaet',
                _cycle(28), _kEnergie, Icons.favorite_rounded),
            _cycleCard('Geist', '33-Tage-Zyklus - Denken, Logik, Konzentration',
                _cycle(33), const Color(0xFF00B0FF), Icons.psychology_rounded),
          ],
        ],
      ),
    );
  }

  Widget _cycleCard(
      String title, String sub, double value, Color color, IconData icon) {
    final pct = (value * 100).round();
    final phase = value > 0.3
        ? 'Hochphase'
        : value < -0.3
            ? 'Tiefphase'
            : 'Wechselphase';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kEnSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${pct > 0 ? '+' : ''}$pct%',
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text(sub,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(children: [
            Container(height: 8, color: Colors.white.withValues(alpha: 0.08)),
            Align(
              alignment: Alignment(value, 0),
              child: Container(
                width: 14,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 6),
        Text(phase, style: TextStyle(color: color, fontSize: 12)),
      ]),
    );
  }
}
