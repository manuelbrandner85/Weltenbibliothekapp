import 'package:flutter/material.dart';
import '../services/ai_search_suggestion_service.dart';

/// Recommended Narratives Widget
/// AI-powered narrative recommendations based on user interests
class RecommendedNarrativesWidget extends StatefulWidget {
  final Function(String)? onNarrativeTap;

  const RecommendedNarrativesWidget({
    super.key,
    this.onNarrativeTap,
  });

  @override
  State<RecommendedNarrativesWidget> createState() => _RecommendedNarrativesWidgetState();
}

class _RecommendedNarrativesWidgetState extends State<RecommendedNarrativesWidget> {
  final _aiService = AISearchSuggestionService();
  List<Map<String, dynamic>> _narratives = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    final narratives = await _aiService.getRecommendedNarratives();

    if (mounted) {
      setState(() {
        _narratives = narratives;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.amber.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Für dich empfohlen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadRecommendations,
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.amber.shade400,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Content
          _isLoading
              ? _buildLoadingState()
              : _narratives.isEmpty
                  ? _buildEmptyState()
                  : _buildNarrativesList(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade400),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              size: 64,
              color: Colors.grey.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'Noch keine Empfehlungen',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Erkunde mehr Inhalte, um personalisierte Empfehlungen zu erhalten',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrativesList() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _narratives.take(10).length,
        itemBuilder: (context, index) {
          final narrative = _narratives[index];
          return _buildNarrativeCard(narrative);
        },
      ),
    );
  }

  Widget _buildNarrativeCard(Map<String, dynamic> narrative) {
    final title = narrative['title'] ?? 'Unbekannt';
    final category = narrative['category'] ?? 'Wissen';
    final id = narrative['id'] ?? '';

    return InkWell(
      onTap: () => widget.onNarrativeTap?.call(id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: Colors.amber.shade300,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI-Tipp',
                          style: TextStyle(
                            color: Colors.amber.shade300,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Read Button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Lesen',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
}
