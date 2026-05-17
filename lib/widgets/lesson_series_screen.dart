// 📚 LESSON-SERIES — Generisches Widget für tagesweise Lernpfade
//
// Wird genutzt von Kabbala (22 Pfade), Runen-Orakel (24 Elder-Futhark Tage)
// und I-Ging (64 Hexagramm-Tage). Jeder Eintrag = 1 Tag mit Symbol,
// Bedeutung, Reflexionsfrage. Fortschritt persistiert via SharedPreferences.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonSeriesEntry {
  final String code;
  final String symbol;
  final String title;
  final String subtitle;
  final String meaning;
  final String reflection;

  const LessonSeriesEntry({
    required this.code,
    required this.symbol,
    required this.title,
    required this.subtitle,
    required this.meaning,
    required this.reflection,
  });
}

class LessonSeriesScreen extends StatefulWidget {
  final String title;
  final String emoji;
  final Color accent;
  final String storageKey;
  final List<LessonSeriesEntry> entries;
  final String tradition;

  const LessonSeriesScreen({
    super.key,
    required this.title,
    required this.emoji,
    required this.accent,
    required this.storageKey,
    required this.entries,
    required this.tradition,
  });

  @override
  State<LessonSeriesScreen> createState() => _LessonSeriesScreenState();
}

class _LessonSeriesScreenState extends State<LessonSeriesScreen> {
  static const _bg = Color(0xFF06040F);
  static const _surface = Color(0xFF100B1E);

  Set<String> _completed = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _completed =
        (prefs.getStringList(widget.storageKey) ?? const []).toSet();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(String code) async {
    setState(() {
      if (_completed.contains(code)) {
        _completed.remove(code);
      } else {
        _completed.add(code);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(widget.storageKey, _completed.toList());
  }

  void _openDetails(LessonSeriesEntry e, int dayIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EntryDetailSheet(
        entry: e,
        dayIndex: dayIndex,
        totalDays: widget.entries.length,
        accent: widget.accent,
        isCompleted: _completed.contains(e.code),
        onToggle: () {
          _toggle(e.code);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.entries.isEmpty
        ? 0.0
        : _completed.length / widget.entries.length;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: widget.accent.withValues(alpha: 0.9),
        title: Row(
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: widget.accent),
            )
          : Column(
              children: [
                _buildHeader(progress),
                Expanded(child: _buildList()),
              ],
            ),
    );
  }

  Widget _buildHeader(double progress) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.accent.withValues(alpha: 0.35), _surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.entries.length}-TAGES-LERNREIHE',
              style: TextStyle(
                color: widget.accent,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 6),
          Text(
            widget.tradition,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(widget.accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_completed.length} / ${widget.entries.length} abgeschlossen',
            style: TextStyle(color: widget.accent, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      itemCount: widget.entries.length,
      itemBuilder: (_, i) {
        final e = widget.entries[i];
        final done = _completed.contains(e.code);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: done ? widget.accent.withValues(alpha: 0.18) : _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: done
                  ? widget.accent.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openDetails(e, i + 1),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.accent.withValues(alpha: 0.15),
                        border: Border.all(
                            color: widget.accent.withValues(alpha: 0.4)),
                      ),
                      child: Text('${i + 1}',
                          style: TextStyle(
                            color: widget.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                    const SizedBox(width: 12),
                    Text(e.symbol, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              )),
                          if (e.subtitle.isNotEmpty)
                            Text(e.subtitle,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done
                          ? widget.accent
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EntryDetailSheet extends StatelessWidget {
  final LessonSeriesEntry entry;
  final int dayIndex;
  final int totalDays;
  final Color accent;
  final bool isCompleted;
  final VoidCallback onToggle;

  const _EntryDetailSheet({
    required this.entry,
    required this.dayIndex,
    required this.totalDays,
    required this.accent,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child:
                  Text(entry.symbol, style: const TextStyle(fontSize: 72)),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('TAG $dayIndex / $totalDays',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(entry.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  )),
            ),
            if (entry.subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(entry.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    )),
              ),
            ],
            const SizedBox(height: 22),
            _section('📖 Bedeutung', entry.meaning, accent),
            const SizedBox(height: 16),
            _section('🪞 Reflexion', entry.reflection, accent),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onToggle,
                icon: Icon(isCompleted ? Icons.refresh : Icons.check),
                label: Text(isCompleted
                    ? 'Wieder als offen markieren'
                    : 'Als abgeschlossen markieren'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _section(String label, String body, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                color: accent,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.6,
              )),
        ],
      ),
    );
  }
}
