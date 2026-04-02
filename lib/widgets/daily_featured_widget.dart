import 'package:flutter/material.dart';
import '../services/daily_knowledge_service.dart';
import 'dart:async';

/// Daily Featured Narrative Widget
/// Shows today's featured narrative with streak counter and countdown
class DailyFeaturedWidget extends StatefulWidget {
  final VoidCallback? onNarrativeTap;

  const DailyFeaturedWidget({
    super.key,
    this.onNarrativeTap,
  });

  @override
  State<DailyFeaturedWidget> createState() => _DailyFeaturedWidgetState();
}

class _DailyFeaturedWidgetState extends State<DailyFeaturedWidget> {
  final _knowledgeService = DailyKnowledgeService();
  Map<String, dynamic>? _featuredNarrative;
  bool _isLoading = true;
  Timer? _countdownTimer;
  String _countdownText = '';

  @override
  void initState() {
    super.initState();
    _loadFeaturedNarrative();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFeaturedNarrative() async {
    setState(() {
      _isLoading = true;
    });

    final narrative = await _knowledgeService.getTodaysFeaturedNarrative();

    if (mounted) {
      setState(() {
        _featuredNarrative = narrative;
        _isLoading = false;
      });
    }
  }

  void _startCountdownTimer() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (mounted) {
      setState(() {
        _countdownText = _knowledgeService.getCountdownString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF7E57C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _isLoading
            ? _buildLoadingState()
            : _featuredNarrative != null
                ? _buildFeaturedContent()
                : _buildErrorState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 200,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white70, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Keine Entdeckung verfügbar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadFeaturedNarrative,
            child: const Text(
              'Erneut versuchen',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedContent() {
    final narrative = _featuredNarrative!;
    final title = narrative['title'] ?? 'Unbekannt';
    final description = narrative['description'] ?? '';
    final category = narrative['category'] ?? 'Wissen';
    final currentStreak = _knowledgeService.getCurrentStreak();
    final streakEmoji = _knowledgeService.getStreakEmoji(currentStreak);

    return InkWell(
      onTap: widget.onNarrativeTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Badge: "Heute's Entdeckung"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        "Heute's Entdeckung",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Streak Counter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        streakEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$currentStreak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Bottom Row: Countdown + Action
            Row(
              children: [
                // Countdown
                Icon(
                  Icons.timer_outlined,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Nächste in $_countdownText',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                // Read Button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lesen',
                        style: TextStyle(
                          color: Color(0xFF1E88E5),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward,
                        color: Color(0xFF1E88E5),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
