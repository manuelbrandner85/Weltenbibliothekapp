import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/biometric_service.dart';

/// 📊 BiometricResultSheet — Modal showing HR/HRV before-vs-after + score.
///
/// Layout matches the AUFGABE 6C spec:
///
///   ┌──────────────────────────────────────┐
///   │     SITZUNGS-ERGEBNIS                │
///   │  Herzfrequenz:  72 → 64 bpm  ↓ 11%  │
///   │  HRV (SDNN):   42 → 58 ms   ↑ 38%  │
///   │  ╔═══════════════════════════════╗   │
///   │  ║   WIRKUNGS-SCORE: +38%  🌟   ║   │
///   │  ╚═══════════════════════════════╝   │
///   │  [Speichern] [Teilen] [Nächste]      │
///   └──────────────────────────────────────┘
///
/// Used by Gateway-Kammer, Atemmeister and any future biometric tool.
class BiometricResultSheet extends StatelessWidget {
  final BiometricComparison comparison;
  final String sessionType; // e.g. 'gateway', 'breathmaster'
  final String? sessionWorld; // e.g. 'ursprung'
  final int? durationMinutes;
  final VoidCallback? onSave;
  final VoidCallback? onNext;

  const BiometricResultSheet({
    super.key,
    required this.comparison,
    required this.sessionType,
    this.sessionWorld,
    this.durationMinutes,
    this.onSave,
    this.onNext,
  });

  static const _cyan = Color(0xFF00D4AA);
  static const _bgDeep = Color(0xFF050510);

  /// Convenience helper to show this as a bottom sheet from any screen.
  static Future<void> show(
    BuildContext context, {
    required BiometricComparison comparison,
    required String sessionType,
    String? sessionWorld,
    int? durationMinutes,
    VoidCallback? onSave,
    VoidCallback? onNext,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: _bgDeep,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BiometricResultSheet(
        comparison: comparison,
        sessionType: sessionType,
        sessionWorld: sessionWorld,
        durationMinutes: durationMinutes,
        onSave: onSave,
        onNext: onNext,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score = comparison.effectivenessScore;
    final scoreEmoji = _scoreEmoji(score);
    final scoreColor = _scoreColor(score);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'SITZUNGS-ERGEBNIS',
                style: TextStyle(
                  color: _cyan.withValues(alpha: 0.85),
                  letterSpacing: 4.0,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (!comparison.hasAnyData) _buildNoDataNotice() else _buildRows(),
            const SizedBox(height: 18),
            _buildScoreBox(score, scoreColor, scoreEmoji),
            const SizedBox(height: 20),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              color: _cyan.withValues(alpha: 0.7), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Keine biometrischen Daten verfügbar. Verbinde Apple Health '
              'oder Health Connect mit Herzfrequenz-Quelle (Apple Watch, '
              'Wear OS, Mi Band, …) um deinen Wirkungs-Score zu sehen.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRows() {
    return Column(
      children: [
        _metricRow(
          label: 'Herzfrequenz',
          before: comparison.heartRateBefore,
          after: comparison.heartRateAfter,
          unit: 'bpm',
          // For HR, a DROP (negative delta) is GOOD → invert direction colour
          goodWhenDecreasing: true,
        ),
        const SizedBox(height: 10),
        _metricRow(
          label: 'HRV (SDNN)',
          before: comparison.hrvBefore,
          after: comparison.hrvAfter,
          unit: 'ms',
          goodWhenDecreasing: false,
        ),
      ],
    );
  }

  Widget _metricRow({
    required String label,
    required double? before,
    required double? after,
    required String unit,
    required bool goodWhenDecreasing,
  }) {
    final hasData = before != null && after != null && before > 0;
    final delta = hasData ? ((after - before) / before) * 100 : null;
    final arrow = delta == null ? '—' : (delta >= 0 ? '↑' : '↓');
    final pct = delta == null ? '—' : '${delta.abs().toStringAsFixed(0)}%';
    final isGood =
        delta == null ? null : (goodWhenDecreasing ? delta < 0 : delta > 0);
    final deltaColor = isGood == null
        ? Colors.white54
        : (isGood ? _cyan : Colors.redAccent.shade100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.80),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: hasData
                ? Text(
                    '${before.toStringAsFixed(0)} → ${after.toStringAsFixed(0)} $unit',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  )
                : Text(
                    '— $unit',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 14,
                    ),
                  ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '$arrow $pct',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: deltaColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBox(double score, Color color, String emoji) {
    final prefix = score >= 0 ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.20),
            color.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 30,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'WIRKUNGS-SCORE',
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 11,
              letterSpacing: 4.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$prefix${score.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 36,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 10),
              Text(emoji, style: const TextStyle(fontSize: 28)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              onSave?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: _cyan.withValues(alpha: 0.9),
                  content: const Text('Gespeichert in Apple/Google Health'),
                ),
              );
            },
            icon:
                const Icon(Icons.bookmark_add_outlined, color: _cyan, size: 18),
            label: const Text('Speichern',
                style: TextStyle(color: _cyan, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: _cyan.withValues(alpha: 0.4)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _share(context),
            icon: const Icon(Icons.share_outlined, color: _cyan, size: 18),
            label: const Text('Teilen',
                style: TextStyle(color: _cyan, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: _cyan.withValues(alpha: 0.4)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).maybePop();
              onNext?.call();
            },
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Nächste',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _cyan,
              foregroundColor: _bgDeep,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context) async {
    final s = comparison.effectivenessScore;
    final prefix = s >= 0 ? '+' : '';
    final hr = (comparison.heartRateBefore != null &&
            comparison.heartRateAfter != null)
        ? 'HR ${comparison.heartRateBefore!.toStringAsFixed(0)} → '
            '${comparison.heartRateAfter!.toStringAsFixed(0)} bpm'
        : null;
    final hrv = (comparison.hrvBefore != null && comparison.hrvAfter != null)
        ? 'HRV ${comparison.hrvBefore!.toStringAsFixed(0)} → '
            '${comparison.hrvAfter!.toStringAsFixed(0)} ms'
        : null;
    final lines = <String>[
      'Meine $sessionType-Session in der Weltenbibliothek:',
      if (hr != null) hr,
      if (hrv != null) hrv,
      'Wirkungs-Score: $prefix${s.toStringAsFixed(0)}% ${_scoreEmoji(s)}',
    ];
    final text = lines.join('\n');
    try {
      await Share.share(text);
    } catch (_) {
      // Fallback: clipboard
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('In Zwischenablage kopiert')),
        );
      }
    }
  }

  String _scoreEmoji(double score) {
    if (score >= 30) return '🌟';
    if (score >= 10) return '✨';
    if (score >= 0) return '🙂';
    if (score >= -10) return '😐';
    return '⚠️';
  }

  Color _scoreColor(double score) {
    if (score >= 10) return _cyan;
    if (score >= 0) return const Color(0xFFFFD700);
    return Colors.redAccent.shade100;
  }
}
