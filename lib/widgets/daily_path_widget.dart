// 🌅 Daily Path Widget
//
// Zeigt den heutigen ambient Pfad: Wetter + Insight + 3 Aktivitäten + Mood-Picker.

import 'package:flutter/material.dart';

import '../services/ambient_service.dart';

class DailyPathWidget extends StatefulWidget {
  const DailyPathWidget({super.key});

  @override
  State<DailyPathWidget> createState() => _DailyPathWidgetState();
}

class _DailyPathWidgetState extends State<DailyPathWidget> {
  DailyPath? _path;
  bool _loading = true;
  bool _error = false;
  String _mood = 'neutral';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final mood = await AmbientService.instance.getMood();
    final path =
        await AmbientService.instance.loadDailyPath(forceRefresh: force);
    if (!mounted) return;
    setState(() {
      _path = path;
      _mood = mood;
      _loading = false;
      _error = path == null;
    });
  }

  Color _worldColor(String world) {
    switch (world.toLowerCase()) {
      case 'materie':
        return const Color(0xFFE53935);
      case 'energie':
        return const Color(0xFF7C4DFF);
      case 'noir':
      case 'vorhang':
        return const Color(0xFFC9A84C);
      case 'genesis':
      case 'ursprung':
        return const Color(0xFF00D4AA);
      default:
        return Colors.white70;
    }
  }

  String _weatherIcon(String? cond) {
    switch ((cond ?? '').toLowerCase()) {
      case 'clear':
      case 'sunny':
        return '☀️';
      case 'clouds':
      case 'cloudy':
        return '☁️';
      case 'rain':
      case 'rainy':
        return '🌧️';
      case 'snow':
        return '❄️';
      case 'thunderstorm':
        return '⛈️';
      case 'fog':
      case 'mist':
        return '🌫️';
      default:
        return '🌍';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _loading
          ? const _SkeletonView(key: ValueKey('loading'))
          : (_error || _path == null)
              ? _ErrorView(
                  key: const ValueKey('error'),
                  onRetry: () => _load(force: true))
              : _buildLoaded(_path!),
    );
  }

  Widget _buildLoaded(DailyPath p) {
    final ctx = p.context;
    final weather = ctx['weather'] is Map
        ? Map<String, dynamic>.from(ctx['weather'] as Map)
        : <String, dynamic>{};
    final city = (weather['city'] as String?) ?? (ctx['city'] as String?) ?? '';
    final temp = weather['temp'] ?? weather['temperature'];
    final cond = weather['condition'] as String?;

    return Padding(
      key: const ValueKey('loaded'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wetter-Zeile
          if (city.isNotEmpty || temp != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Text(_weatherIcon(cond),
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      [
                        if (city.isNotEmpty) city,
                        if (temp != null) '${(temp as num).round()}°C',
                        if ((cond ?? '').isNotEmpty) cond!,
                      ].join(' · '),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (p.dailyInsight.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome, size: 14, color: Colors.amber),
                      SizedBox(width: 6),
                      Text(
                        'HEUTIGER INSIGHT',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2.5,
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.dailyInsight,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (p.activities.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 142,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: p.activities.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _ActivityCard(
                    activity: p.activities[i],
                    color: _worldColor(p.activities[i].world)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _MoodPicker(
            selected: _mood,
            onSelect: (m) async {
              await AmbientService.instance.setMood(m);
              if (!mounted) return;
              setState(() => _mood = m);
            },
          ),
          const SizedBox(height: 6),
          Text(
            'Ambient: ${p.ambientFrequency.toStringAsFixed(2)} Hz',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10.5,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final Color color;
  const _ActivityCard({required this.activity, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        // TODO: Navigation zum Modul wenn activity.moduleCode != null
        if (activity.moduleCode != null) {
          debugPrint('🔗 Tap auf Modul: ${activity.moduleCode}');
        }
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 14,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(activity.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activity.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                activity.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11.5,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  '${activity.durationMin} min',
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                if (activity.moduleCode != null) ...[
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      activity.moduleCode!,
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _MoodPicker({required this.selected, required this.onSelect});

  static const _moods = [
    ('sleepy', '😴'),
    ('neutral', '😐'),
    ('focused', '🧘'),
    ('energetic', '⚡'),
    ('peak', '🔥'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _moods.map((m) {
        final isSelected = m.$1 == selected;
        return InkWell(
          onTap: () => onSelect(m.$1),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.amber.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.amber
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: Text(m.$2, style: const TextStyle(fontSize: 20)),
          ),
        );
      }).toList(),
    );
  }
}

class _SkeletonView extends StatelessWidget {
  const _SkeletonView({super.key});
  @override
  Widget build(BuildContext context) {
    Widget bar(double h, {double w = double.infinity}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          bar(40),
          const SizedBox(height: 10),
          bar(62),
          const SizedBox(height: 12),
          SizedBox(
            height: 142,
            child: Row(
              children: [
                Expanded(child: bar(double.infinity)),
                const SizedBox(width: 10),
                Expanded(child: bar(double.infinity)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({super.key, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white54, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tagespfad nicht verfügbar.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}
