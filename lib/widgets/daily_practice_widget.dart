import 'package:flutter/material.dart';
import '../models/spirit_extended_models.dart';
import '../services/daily_spirit_practice_service.dart';

/// ============================================
/// DAILY PRACTICE WIDGET
/// Zeigt heutige Spirit-Übungen an
/// ============================================

class DailyPracticeWidget extends StatefulWidget {
  final Color accentColor;

  const DailyPracticeWidget({
    super.key,
    this.accentColor = const Color(0xFF9C27B0),
  });

  @override
  State<DailyPracticeWidget> createState() => _DailyPracticeWidgetState();
}

class _DailyPracticeWidgetState extends State<DailyPracticeWidget> {
  final _service = DailySpiritPracticeService();

  @override
  void initState() {
    super.initState();
    _loadPractices();
  }

  Future<void> _loadPractices() async {
    await _service.loadTodaysPractices();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final practices = _service.todaysPractices;
    final completedCount = _service.completedCount;
    final totalCount = _service.totalCount;
    final progressPercent = _service.progressPercent;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F1E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.accentColor,
                        widget.accentColor.withValues(alpha: 0.6),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.self_improvement,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Titel & Fortschritt
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deine Übungen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount von $totalCount abgeschlossen',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress-Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${progressPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Progress-Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercent / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(widget.accentColor),
                minHeight: 6,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Practice-Liste
          Expanded(
            child: practices.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: practices.length,
                    itemBuilder: (context, index) {
                      final practice = practices[index];
                      return _buildPracticeCard(practice);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Practice-Card
  Widget _buildPracticeCard(DailySpiritPractice practice) {
    final isCompleted = practice.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted
            ? widget.accentColor.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? widget.accentColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Kategorie-Badge
            Row(
              children: [
                // Kategorie-Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(practice.category).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(practice.category),
                    size: 16,
                    color: _getCategoryColor(practice.category),
                  ),
                ),
                const SizedBox(width: 8),

                // Kategorie-Name
                Text(
                  _getCategoryName(practice.category),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(practice.category),
                    letterSpacing: 0.5,
                  ),
                ),

                const Spacer(),

                // Dauer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${practice.durationMinutes} Min',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Completed-Icon
                if (isCompleted) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: widget.accentColor,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Titel
            Text(
              practice.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCompleted
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Beschreibung
            Text(
              practice.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Complete-Button
            if (!isCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _completePractice(practice),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'ABSCHLIESSEN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // Completed-Status
            if (isCompleted)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: widget.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Abgeschlossen',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: widget.accentColor,
                      ),
                    ),
                    const Spacer(),
                    if (practice.completedAt != null)
                      Text(
                        _formatTime(practice.completedAt!),
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.accentColor.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Übung abschließen
  Future<void> _completePractice(DailySpiritPractice practice) async {
    await _service.completePractice(practice.id);
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${practice.title} abgeschlossen! +10 Punkte'),
          backgroundColor: widget.accentColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Empty-State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.self_improvement,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Übungen für heute',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Übungen werden täglich generiert',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Kategorie-Icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'meditation':
        return Icons.self_improvement;
      case 'breathing':
        return Icons.air;
      case 'chakra':
        return Icons.energy_savings_leaf;
      case 'journal':
        return Icons.edit_note;
      default:
        return Icons.self_improvement;
    }
  }

  /// Kategorie-Farbe
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'meditation':
        return const Color(0xFF9C27B0); // Lila
      case 'breathing':
        return const Color(0xFF00BCD4); // Cyan
      case 'chakra':
        return const Color(0xFFFF9800); // Orange
      case 'journal':
        return const Color(0xFF4CAF50); // Grün
      default:
        return const Color(0xFF9C27B0);
    }
  }

  /// Kategorie-Name
  String _getCategoryName(String category) {
    switch (category) {
      case 'meditation':
        return 'MEDITATION';
      case 'breathing':
        return 'ATEMÜBUNG';
      case 'chakra':
        return 'CHAKRA';
      case 'journal':
        return 'JOURNAL';
      default:
        return 'ÜBUNG';
    }
  }

  /// Zeit formatieren
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute Uhr';
  }
}
