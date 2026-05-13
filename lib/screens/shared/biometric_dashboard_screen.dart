import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 📊 BiometricDashboardScreen — 7-day HRV trend + recent sessions list.
///
/// Reads from `biometric_readings` (own rows via RLS) and renders:
///   • A 7-day HRV line chart (avg per day)
///   • Average effectiveness score
///   • Best single session
///   • Last 10 sessions (table)
class BiometricDashboardScreen extends StatefulWidget {
  const BiometricDashboardScreen({super.key});

  @override
  State<BiometricDashboardScreen> createState() =>
      _BiometricDashboardScreenState();
}

class _BiometricDashboardScreenState extends State<BiometricDashboardScreen> {
  static const _cyan = Color(0xFF00D4AA);
  static const _bgDeep = Color(0xFF050510);
  static const _surface = Color(0xFF080818);

  bool _loading = true;
  String? _error;
  List<_Reading> _readings = const [];

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
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw 'Bitte melde dich an, um deine Biometrie-Historie zu sehen.';
      }
      final since = DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 30))
          .toIso8601String();
      final res = await Supabase.instance.client
          .from('biometric_readings')
          .select('*')
          .eq('user_id', user.id)
          .gte('created_at', since)
          .order('created_at', ascending: false)
          .limit(100);
      final list = (res as List)
          .map((m) => _Reading.fromMap(m as Map<String, dynamic>))
          .toList();
      setState(() {
        _readings = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDeep,
      appBar: AppBar(
        backgroundColor: _bgDeep,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cyan),
        title: const Text(
          'Biometrie-Dashboard',
          style: TextStyle(color: _cyan, letterSpacing: 2.0, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _cyan),
            onPressed: _load,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _cyan))
            : _error != null
                ? _buildError()
                : _readings.isEmpty
                    ? _buildEmpty()
                    : _buildBody(),
      ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error ?? 'Fehler',
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_outline,
                  size: 64, color: _cyan.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text(
                'Noch keine biometrischen Sessions',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Starte eine Gateway- oder Atem-Sitzung mit aktiviertem '
                'biometrischen Feedback, um deine HRV-Entwicklung hier zu '
                'sehen.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildBody() {
    final last7 = _last7DaysAvg();
    final avgScore = _avg(_readings.map((r) => r.effectivenessScore));
    final bestReading = _bestReading();
    final lastTen = _readings.take(10).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionLabel('HRV · LETZTE 7 TAGE'),
          const SizedBox(height: 10),
          _buildChartCard(last7),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  label: 'Ø WIRKUNGS-SCORE',
                  value: avgScore == null
                      ? '—'
                      : '${avgScore >= 0 ? '+' : ''}${avgScore.toStringAsFixed(0)}%',
                  color: _cyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  label: 'BESTE SESSION',
                  value: bestReading == null
                      ? '—'
                      : '+${bestReading.effectivenessScore!.toStringAsFixed(0)}%',
                  sub: bestReading?.sessionType.toUpperCase(),
                  color: const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionLabel('LETZTE ${lastTen.length} SESSIONS'),
          const SizedBox(height: 10),
          ...lastTen.map(_buildSessionRow),
        ],
      ),
    );
  }

  Widget _buildChartCard(List<_DayPoint> data) {
    if (data.isEmpty || data.every((d) => d.avgHrv == null)) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Center(
          child: Text(
            'Noch nicht genug HRV-Daten — mindestens eine Session pro Tag.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      final v = data[i].avgHrv;
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }
    final minY = spots.isEmpty
        ? 0.0
        : (spots.map((s) => s.y).reduce((a, b) => a < b ? a : b)) * 0.85;
    final maxY = spots.isEmpty
        ? 100.0
        : (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b)) * 1.15;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: _cardDecoration(),
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: ((maxY - minY) / 4).clamp(1, 100),
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withValues(alpha: 0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      data[idx].label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: _cyan,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3.5,
                  color: _cyan,
                  strokeColor: _bgDeep,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _cyan.withValues(alpha: 0.30),
                    _cyan.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    String? sub,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 9,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.0,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionRow(_Reading r) {
    final s = r.effectivenessScore;
    final scoreText = s == null
        ? '—'
        : '${s >= 0 ? '+' : ''}${s.toStringAsFixed(0)}%';
    final scoreColor = s == null
        ? Colors.white54
        : (s >= 10 ? _cyan : (s >= 0 ? const Color(0xFFFFD700) : Colors.redAccent.shade100));
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cyan.withValues(alpha: 0.10),
                border: Border.all(color: _cyan.withValues(alpha: 0.30)),
              ),
              child: Icon(_iconFor(r.sessionType),
                  color: _cyan, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _humanizeType(r.sessionType),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(r.createdAt),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (r.hrvBefore != null && r.hrvAfter != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${r.hrvBefore!.toStringAsFixed(0)} → ${r.hrvAfter!.toStringAsFixed(0)} ms',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ),
            Text(
              scoreText,
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: _surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withValues(alpha: 0.15)),
      );

  Widget _sectionLabel(String s) => Text(
        s,
        style: TextStyle(
          color: _cyan.withValues(alpha: 0.8),
          fontSize: 10,
          letterSpacing: 3.5,
          fontWeight: FontWeight.w700,
        ),
      );

  // ── helpers ─────────────────────────────────────────────────

  List<_DayPoint> _last7DaysAvg() {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      return d;
    });
    return days.map((day) {
      final next = day.add(const Duration(days: 1));
      final dayReadings = _readings.where((r) =>
          r.createdAt.isAfter(day.subtract(const Duration(seconds: 1))) &&
          r.createdAt.isBefore(next));
      final hrvs = dayReadings
          .map((r) => r.hrvAfter)
          .whereType<double>()
          .toList();
      final avg = hrvs.isEmpty
          ? null
          : hrvs.reduce((a, b) => a + b) / hrvs.length;
      return _DayPoint(label: _dayLabel(day), avgHrv: avg);
    }).toList();
  }

  double? _avg(Iterable<double?> values) {
    final clean = values.whereType<double>().toList();
    if (clean.isEmpty) return null;
    final sum = clean.reduce((a, b) => a + b);
    return sum / clean.length;
  }

  _Reading? _bestReading() {
    final withScore =
        _readings.where((r) => r.effectivenessScore != null).toList();
    if (withScore.isEmpty) return null;
    withScore.sort(
      (a, b) => b.effectivenessScore!.compareTo(a.effectivenessScore!),
    );
    return withScore.first;
  }

  String _dayLabel(DateTime d) {
    const labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return labels[(d.weekday - 1) % 7];
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final d = '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.${local.year}';
    final t =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$d · $t';
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'gateway':
        return Icons.door_front_door_outlined;
      case 'breathmaster':
        return Icons.air;
      case 'meditation':
        return Icons.self_improvement;
      case 'frequency':
        return Icons.graphic_eq;
      default:
        return Icons.favorite_outline;
    }
  }

  String _humanizeType(String type) {
    switch (type) {
      case 'gateway':
        return 'Gateway-Kammer';
      case 'breathmaster':
        return 'Atemmeister';
      case 'meditation':
        return 'Meditation';
      case 'frequency':
        return 'Frequenz-Generator';
      default:
        return type;
    }
  }
}

class _DayPoint {
  final String label;
  final double? avgHrv;
  const _DayPoint({required this.label, required this.avgHrv});
}

class _Reading {
  final String id;
  final String sessionType;
  final String? sessionWorld;
  final double? hrvBefore;
  final double? hrvAfter;
  final double? hrBefore;
  final double? hrAfter;
  final double? effectivenessScore;
  final int? durationMinutes;
  final DateTime createdAt;

  const _Reading({
    required this.id,
    required this.sessionType,
    this.sessionWorld,
    this.hrvBefore,
    this.hrvAfter,
    this.hrBefore,
    this.hrAfter,
    this.effectivenessScore,
    this.durationMinutes,
    required this.createdAt,
  });

  factory _Reading.fromMap(Map<String, dynamic> m) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return _Reading(
      id: m['id']?.toString() ?? '',
      sessionType: (m['session_type'] ?? 'session').toString(),
      sessionWorld: m['session_world']?.toString(),
      hrvBefore: toDouble(m['hrv_before']),
      hrvAfter: toDouble(m['hrv_after']),
      hrBefore: toDouble(m['hr_before']),
      hrAfter: toDouble(m['hr_after']),
      effectivenessScore: toDouble(m['effectiveness_score']),
      durationMinutes: m['duration_minutes'] is int
          ? m['duration_minutes'] as int
          : int.tryParse(m['duration_minutes']?.toString() ?? ''),
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
