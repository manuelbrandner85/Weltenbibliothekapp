import 'package:flutter/material.dart';

import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/intel/intel_list_screen.dart';
import '../../../widgets/materie/osint_source_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Materie cosmos/geo tools (all key-free, open data sources).
// Earthquakes (USGS), Asteroids (JPL SSD), Volcanoes (EONET), Space weather (NOAA).
// ─────────────────────────────────────────────────────────────────────────────

const Color _kMaterie = Color(0xFFE53935);

/// Erdbeben-Radar — Live-Beben weltweit (USGS).
class EarthquakeRadarScreen extends StatelessWidget {
  const EarthquakeRadarScreen({super.key});

  Color _magColor(double m) {
    if (m >= 6) return const Color(0xFFD32F2F);
    if (m >= 5) return const Color(0xFFFF6F00);
    if (m >= 4) return const Color(0xFFFFC107);
    return const Color(0xFF66BB6A);
  }

  @override
  Widget build(BuildContext context) {
    return IntelListScreen(
      title: 'Erdbeben-Radar',
      icon: Icons.vibration_rounded,
      accent: _kMaterie,
      world: WBWorld.materie,
      endpoint: '/api/intel/earthquakes?min=2.5',
      sourceText:
          'Live-Seismik des US Geological Survey (USGS). Zeigt alle Beben '
          'ab Magnitude 2.5 der letzten 24 Stunden weltweit.',
      sources: const [OsintSource('USGS', 'https://earthquake.usgs.gov')],
      headerNote: 'Magnitude (M) auf der Richterskala. Tiefe in Kilometern.',
      mapper: (e) {
        final mag = (e['mag'] as num?)?.toDouble() ?? 0;
        final depth = (e['depth'] as num?)?.toDouble();
        final time = (e['time'] ?? '').toString();
        final tsunami = e['tsunami'] == true;
        final date = time.length >= 16 ? time.substring(0, 16).replaceFirst('T', ' ') : time;
        return IntelRow(
          title: (e['title'] ?? 'Beben').toString(),
          subtitle: [
            if (date.isNotEmpty) date,
            if (depth != null) 'Tiefe ${depth.round()} km',
            if (tsunami) 'TSUNAMI-WARNUNG',
          ].join('  -  '),
          badge: 'M${mag.toStringAsFixed(1)}',
          badgeColor: _magColor(mag),
          icon: Icons.vibration_rounded,
          url: (e['url'] ?? '').toString(),
        );
      },
    );
  }
}

/// Asteroiden-Anflug — erdnahe Objekte (NASA/JPL SSD).
class AsteroidApproachScreen extends StatelessWidget {
  const AsteroidApproachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntelListScreen(
      title: 'Asteroiden-Anflug',
      icon: Icons.blur_circular_rounded,
      accent: _kMaterie,
      world: WBWorld.materie,
      endpoint: '/api/intel/asteroids',
      sourceText:
          'Erdnahe Objekte (NEOs) der NASA/JPL Close-Approach-Datenbank. '
          'Zeigt Asteroiden, die in den naechsten 60 Tagen nahe an der Erde '
          'vorbeiziehen (unter 0.05 AU).',
      sources: const [OsintSource('NASA/JPL SSD', 'https://ssd.jpl.nasa.gov')],
      headerNote: 'LD = Mond-Distanzen (1 LD = 384.400 km). '
          'Kleinerer Wert = naeherer Vorbeiflug.',
      mapper: (e) {
        final ld = (e['distLd'] as num?)?.toDouble() ?? 0;
        final v = (e['vRel'] as num?)?.toDouble() ?? 0;
        final close = ld < 5;
        return IntelRow(
          title: (e['name'] ?? '?').toString(),
          subtitle: [
            (e['date'] ?? '').toString(),
            '${v.toStringAsFixed(1)} km/s',
          ].where((s) => s.isNotEmpty).join('  -  '),
          badge: '${ld.toStringAsFixed(1)} LD',
          badgeColor: close ? const Color(0xFFFF6F00) : _kMaterie,
          icon: Icons.blur_circular_rounded,
        );
      },
    );
  }
}

/// Vulkan-Aktivitaet — aktive Vulkane weltweit (NASA EONET).
class VolcanoActivityScreen extends StatelessWidget {
  const VolcanoActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntelListScreen(
      title: 'Vulkan-Aktivitaet',
      icon: Icons.volcano_rounded,
      accent: _kMaterie,
      world: WBWorld.materie,
      endpoint: '/api/intel/volcanoes',
      sourceText:
          'Aktive Vulkan-Ereignisse der NASA Earth Observatory (EONET). '
          'Offene, laufende Eruptionen und Aktivitaeten weltweit.',
      sources: const [OsintSource('NASA EONET', 'https://eonet.gsfc.nasa.gov')],
      mapper: (e) {
        final lat = (e['lat'] as num?)?.toDouble();
        final lon = (e['lon'] as num?)?.toDouble();
        return IntelRow(
          title: (e['title'] ?? 'Vulkan').toString(),
          subtitle: [
            (e['date'] ?? '').toString(),
            if (lat != null && lon != null)
              '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}',
          ].where((s) => s.isNotEmpty).join('  -  '),
          icon: Icons.volcano_rounded,
          badgeColor: const Color(0xFFFF6F00),
          url: (e['link'] ?? '').toString(),
        );
      },
    );
  }
}

/// Weltraumwetter — Sonnenstuerme & Polarlicht-Chance (NOAA SWPC).
class SpaceWeatherScreen extends StatelessWidget {
  const SpaceWeatherScreen({super.key});

  Color _kpColor(double kp) {
    if (kp >= 7) return const Color(0xFFD32F2F);
    if (kp >= 5) return const Color(0xFFFF6F00);
    if (kp >= 4) return const Color(0xFFFFC107);
    return const Color(0xFF66BB6A);
  }

  @override
  Widget build(BuildContext context) {
    return IntelListScreen(
      title: 'Weltraumwetter',
      icon: Icons.flare_rounded,
      accent: _kMaterie,
      world: WBWorld.materie,
      endpoint: '/api/intel/spaceweather',
      sourceText:
          'Geomagnetischer Kp-Index der NOAA Space Weather Prediction Center. '
          'Ab Kp 5 geomagnetischer Sturm - hohe Polarlicht-Chance, moegliche '
          'Stoerungen von Funk, GPS und Stromnetzen.',
      sources: const [OsintSource('NOAA SWPC', 'https://www.swpc.noaa.gov')],
      headerNote: 'Kp-Index 0-9. Neueste Messungen zuerst (3-Stunden-Intervalle).',
      mapper: (e) {
        final kp = (e['kp'] as num?)?.toDouble() ?? 0;
        final time = (e['time'] ?? '').toString();
        return IntelRow(
          title: (e['level'] ?? 'Ruhig').toString(),
          subtitle: time.length >= 16 ? time.substring(0, 16) : time,
          badge: 'Kp ${kp.toStringAsFixed(0)}',
          badgeColor: _kpColor(kp),
          icon: Icons.flare_rounded,
        );
      },
    );
  }
}
