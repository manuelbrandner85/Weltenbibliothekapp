// ❤️ BIOMETRIE-ANALYSE (Issue #442)
//
// Visualisiert die per Session erfassten Biometrie-Daten (Herzfrequenz +
// Herzfrequenzvariabilitaet) als Diagramme. Der Nutzer bekommt eine Uebersicht
// ueber HR/HRV, sieht den Verlauf als Line-Charts und kann per Tipp auf ein
// Diagramm bzw. eine Session Detail-Werte einsehen.
//
// Datenquelle: `biometric_readings` (Supabase, RLS auth.uid()=user_id) ueber
// BiometricDataCacheService. Charts nutzen die dependency-freien Painter aus
// widgets/stats/stats_charts.dart (kein neues Package noetig).

import 'package:flutter/material.dart';

import '../../services/biometric_data_cache_service.dart';
import '../../services/invisible_auth_service.dart';
import '../../widgets/stats/stats_charts.dart';

class BiometrieScreen extends StatefulWidget {
  const BiometrieScreen({super.key});

  @override
  State<BiometrieScreen> createState() => _BiometrieScreenState();
}

class _BiometrieScreenState extends State<BiometrieScreen> {
  static const Color _hrColor = Color(0xFFE53935); // Herzfrequenz (rot)
  static const Color _hrvColor = Color(0xFF26C6DA); // HRV (tuerkis)
  static const Color _effColor = Color(0xFF66BB6A); // Wirkung (gruen)

  final _service = BiometricDataCacheService.instance;

  bool _loading = true;
  String? _error;
  List<BiometricReading> _readings = const [];
  BiometricSummary _summary = BiometricSummary.empty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final userId = InvisibleAuthService().userId ?? '';
      final readings = await _service.loadReadings(
        userId,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _readings = readings;
        _summary = BiometricSummary.fromReadings(readings);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Biometrie-Daten konnten nicht geladen werden.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biometrie-Analyse'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildMessageState(
        icon: Icons.error_outline,
        title: 'Fehler',
        message: _error!,
      );
    }
    if (!_summary.hasData) {
      return _buildMessageState(
        icon: Icons.favorite_border,
        title: 'Noch keine Biometrie-Daten',
        message:
            'Sobald du Sessions mit Herzfrequenz-Messung abschliesst, siehst '
            'du hier deine Herzfrequenz (HR) und Herzfrequenzvariabilitaet '
            '(HRV) als Diagramme.',
      );
    }
    return _buildAnalysis();
  }

  Widget _buildAnalysis() {
    // Chronologisch (alt -> neu) fuer die Verlaufs-Charts.
    final chrono = List<BiometricReading>.from(_readings)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryGrid(),
        const SizedBox(height: 24),
        _buildChartCard(
          title: 'Herzfrequenz (bpm)',
          color: _hrColor,
          readings: chrono,
          valueOf: (r) => r.hrEffective,
          detailTitle: 'Herzfrequenz-Details',
        ),
        const SizedBox(height: 24),
        _buildChartCard(
          title: 'Herzfrequenzvariabilitaet (ms)',
          color: _hrvColor,
          readings: chrono,
          valueOf: (r) => r.hrvEffective,
          detailTitle: 'HRV-Details',
        ),
        const SizedBox(height: 24),
        _buildSessionList(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSummaryGrid() {
    final cards = <Widget>[
      AnimatedCounterCard(
        title: 'O Herzfrequenz',
        value: (_summary.avgHr ?? 0).round(),
        icon: Icons.favorite,
        color: _hrColor,
        suffix: ' bpm',
      ),
      AnimatedCounterCard(
        title: 'O HRV',
        value: (_summary.avgHrv ?? 0).round(),
        icon: Icons.monitor_heart,
        color: _hrvColor,
        suffix: ' ms',
      ),
      AnimatedCounterCard(
        title: 'O Wirkung',
        value: (_summary.avgEffectiveness ?? 0).round(),
        icon: Icons.auto_awesome,
        color: _effColor,
        suffix: '%',
      ),
      AnimatedCounterCard(
        title: 'Sessions',
        value: _summary.count,
        icon: Icons.timeline,
        color: const Color(0xFF7E57C2),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: cards,
    );
  }

  Widget _buildChartCard({
    required String title,
    required Color color,
    required List<BiometricReading> readings,
    required double? Function(BiometricReading) valueOf,
    required String detailTitle,
  }) {
    // Nur Sessions mit vorhandenem Wert in den Verlauf aufnehmen.
    final withValue = readings
        .where((r) => valueOf(r) != null)
        .toList(growable: false);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (withValue.length < 2) {
      return _buildInfoCard(
        title: title,
        color: color,
        child: Text(
          'Mindestens zwei Messungen noetig, um einen Verlauf anzuzeigen.',
          style: TextStyle(
            fontSize: 13,
            color: (isDark ? Colors.white : Colors.black87).withValues(
              alpha: 0.6,
            ),
          ),
        ),
      );
    }

    final dataPoints = withValue
        .map((r) => valueOf(r)!)
        .toList(growable: false);
    final labels = <String>[];
    for (int i = 0; i < withValue.length; i++) {
      if (i % 3 == 0 || i == withValue.length - 1) {
        final d = withValue[i].createdAt;
        labels.add('${d.day}.${d.month}');
      } else {
        labels.add('');
      }
    }

    return _buildInfoCard(
      title: title,
      color: color,
      trailing: const Icon(Icons.touch_app, size: 18),
      child: InkWell(
        onTap: () => _openDetails(detailTitle, withValue, valueOf, color),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SimpleLineChart(
              dataPoints: dataPoints,
              labels: labels,
              lineColor: color,
              height: 200,
            ),
            const SizedBox(height: 8),
            Text(
              'Tippen fuer Detailwerte',
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList() {
    // Neueste zuerst.
    final recent = List<BiometricReading>.from(_readings)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _buildInfoCard(
      title: 'Letzte Sessions',
      color: const Color(0xFF7E57C2),
      child: Column(
        children: [
          for (final r in recent.take(10))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: _effColor.withValues(alpha: 0.15),
                child: Text(
                  '${(r.effectivenessScore ?? 0).round()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _effColor,
                  ),
                ),
              ),
              title: Text(_sessionLabel(r)),
              subtitle: Text(_readingSubtitle(r)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openReadingDetail(r),
            ),
        ],
      ),
    );
  }

  // ── Detail-Ansichten ────────────────────────────────────────────────

  void _openDetails(
    String title,
    List<BiometricReading> readings,
    double? Function(BiometricReading) valueOf,
    Color color,
  ) {
    // Neueste zuerst in der Detail-Liste.
    final sorted = List<BiometricReading>.from(readings)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (ctx, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 16),
                for (final r in sorted)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(_formatDate(r.createdAt)),
                    subtitle: Text(_sessionLabel(r)),
                    trailing: Text(
                      _formatValue(valueOf(r)),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _openReadingDetail(BiometricReading r) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sessionLabel(r),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(r.createdAt),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              _detailRow(
                'Herzfrequenz vorher',
                _formatValue(r.hrBefore, 'bpm'),
              ),
              _detailRow(
                'Herzfrequenz nachher',
                _formatValue(r.hrAfter, 'bpm'),
              ),
              _detailRow('HRV vorher', _formatValue(r.hrvBefore, 'ms')),
              _detailRow('HRV nachher', _formatValue(r.hrvAfter, 'ms')),
              _detailRow(
                'Wirkungs-Score',
                _formatValue(r.effectivenessScore, '%'),
              ),
              _detailRow(
                'Dauer',
                r.durationMinutes != null ? '${r.durationMinutes} min' : '--',
              ),
              if (r.notes != null && r.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  r.notes!,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Shared UI-Bausteine ─────────────────────────────────────────────

  Widget _buildInfoCard({
    required String title,
    required Color color,
    required Widget child,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              if (trailing != null)
                IconTheme(
                  data: IconThemeData(color: color.withValues(alpha: 0.7)),
                  child: trailing,
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    // ListView, damit RefreshIndicator auch im Leer-Zustand ziehbar bleibt.
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ── Formatierung ────────────────────────────────────────────────────

  String _sessionLabel(BiometricReading r) {
    final type = r.sessionType.isEmpty ? 'Session' : r.sessionType;
    final world = r.sessionWorld;
    return world == null || world.isEmpty ? type : '$type - $world';
  }

  String _readingSubtitle(BiometricReading r) {
    final parts = <String>[];
    if (r.hrEffective != null) parts.add('HR ${r.hrEffective!.round()} bpm');
    if (r.hrvEffective != null) parts.add('HRV ${r.hrvEffective!.round()} ms');
    if (parts.isEmpty) return _formatDate(r.createdAt);
    return parts.join(' - ');
  }

  String _formatValue(double? v, [String unit = '']) {
    if (v == null) return '--';
    final rounded = v.round().toString();
    return unit.isEmpty ? rounded : '$rounded $unit';
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}
