import 'package:flutter/material.dart';
import '../services/ai_search_suggestion_service.dart';

/// Smart Suggestions Widget
/// AI-powered search suggestions based on user interests
class SmartSuggestionsWidget extends StatefulWidget {
  final Function(String)? onSuggestionTap;

  const SmartSuggestionsWidget({
    super.key,
    this.onSuggestionTap,
  });

  @override
  State<SmartSuggestionsWidget> createState() => _SmartSuggestionsWidgetState();
}

class _SmartSuggestionsWidgetState extends State<SmartSuggestionsWidget> {
  final _aiService = AISearchSuggestionService();
  List<String> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    final suggestions = await _aiService.getSmartSuggestions();

    if (mounted) {
      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: Colors.purple.shade300,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Das könnte dich interessieren',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadSuggestions,
                icon: Icon(
                  Icons.refresh,
                  color: Colors.purple.shade300,
                  size: 20,
                ),
                tooltip: 'Aktualisieren',
              ),
            ],
          ),
          
          const SizedBox(height: 12),

          // Suggestions
          _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                    ),
                  ),
                )
              : _suggestions.isEmpty
                  ? _buildEmptyState()
                  : _buildSuggestionsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 12),
            Text(
              'Noch keine Vorschläge',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Durchsuche mehr Inhalte für Empfehlungen',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestions.take(8).map((suggestion) {
        return _buildSuggestionChip(suggestion);
      }).toList(),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return InkWell(
      onTap: () => widget.onSuggestionTap?.call(suggestion),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withValues(alpha: 0.2),
              Colors.deepPurple.withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.purple.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 16,
              color: Colors.purple.shade200,
            ),
            const SizedBox(width: 6),
            Text(
              suggestion,
              style: TextStyle(
                color: Colors.purple.shade100,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
