import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:flutter/services.dart';
import '../../models/knowledge_extended_models.dart';
import '../../services/unified_knowledge_service.dart';
import 'package:share_plus/share_plus.dart';

/// ============================================
/// READER MODE - OPTIMALE LESEUMGEBUNG
/// Features:
/// - Schriftgrößen-Anpassung (A-, A, A+)
/// - Font-Family Wechsel (Sans, Serif, Mono)
/// - Fortschritts-Bar
/// - Text-to-Speech (placeholder)
/// - Notizen & Highlights
/// ============================================

class KnowledgeReaderMode extends StatefulWidget {
  final KnowledgeEntry entry;
  final String world;

  const KnowledgeReaderMode({
    super.key,
    required this.entry,
    required this.world,
  });

  @override
  State<KnowledgeReaderMode> createState() => _KnowledgeReaderModeState();
}

class _KnowledgeReaderModeState extends State<KnowledgeReaderMode> {
  final _knowledgeService = UnifiedKnowledgeService();
  final _scrollController = ScrollController();
  final _noteController = TextEditingController();
  
  double _fontSize = 16.0;
  String _fontFamily = 'Sans';
  double _readProgress = 0.0;
  bool _isFavorite = false;
  String _userNote = '';
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_updateProgress);
    
    // Auto-hide controls after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final isFav = await _knowledgeService.isFavorite(widget.entry.id);
    final note = await _knowledgeService.getNote(widget.entry.id);
    
    setState(() {
      _isFavorite = isFav;
      _userNote = (note ?? '') as String;
      _noteController.text = _userNote;
    });
  }

  void _updateProgress() {
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    setState(() {
      _readProgress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    });
    
    // Mark as read when 80% scrolled
    if (_readProgress >= 0.8) {
      _knowledgeService.updateProgress(widget.entry.id, isRead: true, progressPercent: 100);
    }
  }

  void _adjustFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(12.0, 28.0);
    });
  }

  void _changeFontFamily(String family) {
    setState(() => _fontFamily = family);
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _knowledgeService.removeFavorite(widget.entry.id);
    } else {
      await _knowledgeService.addFavorite(widget.entry.id);
    }
    
    setState(() => _isFavorite = !_isFavorite);
    
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? '⭐ Zu Favoriten hinzugefügt' : '💔 Von Favoriten entfernt'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveNote() async {
    await _knowledgeService.saveNote(widget.entry.id, _noteController.text);
    setState(() => _userNote = _noteController.text);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📝 Notiz gespeichert')),
      );
    }
  }

  void _share() {
    Share.share(
      '${widget.entry.title}\n\n${widget.entry.description}\n\n📚 Aus der Weltenbibliothek',
      subject: widget.entry.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.world == 'materie' 
        ? const Color(0xFF2196F3) 
        : const Color(0xFF9C27B0);
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // Main Content
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: primaryColor,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.entry.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            primaryColor,
                            primaryColor.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.auto_stories,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: _share,
                    ),
                  ],
                ),
                
                // Progress Bar
                SliverToBoxAdapter(
                  child: LinearProgressIndicator(
                    value: _readProgress,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                
                // Reading Time Badge
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, size: 16, color: primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.entry.readingTimeMinutes} Min Lesezeit • ${(_readProgress * 100).toInt()}% gelesen',
                          style: TextStyle(
                            fontSize: 14,
                            color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Main Content
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  sliver: SliverToBoxAdapter(
                    child: SelectableText(
                      widget.entry.fullContent,
                      style: TextStyle(
                        fontSize: _fontSize,
                        height: 1.8,
                        fontFamily: _getFontFamily(),
                        color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                      ),
                    ),
                  ),
                ),
                
                // User Note Section
                if (_userNote.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.note, color: primaryColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Deine Notiz:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _userNote,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // Bottom Padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
            
            // Floating Reader Controls
            if (_showControls)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _buildReaderControls(isDark, primaryColor),
              ),
          ],
        ),
      ),
      
      // Floating Action Buttons
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Add Note FAB
          FloatingActionButton(
            heroTag: 'note_fab',
            backgroundColor: primaryColor,
            onPressed: _showNoteDialog,
            child: const Icon(Icons.note_add),
          ),
          const SizedBox(height: 12),
          
          // Scroll to Top FAB
          if (_readProgress > 0.2)
            FloatingActionButton(
              heroTag: 'scroll_fab',
              backgroundColor: primaryColor.withValues(alpha: 0.7),
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            ),
        ],
      ),
    );
  }

  Widget _buildReaderControls(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.black.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Font Size Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Schriftgröße',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Row(
                children: [
                  _buildControlButton(
                    icon: Icons.remove,
                    onTap: () => _adjustFontSize(-2),
                    color: primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_fontSize.toInt()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildControlButton(
                    icon: Icons.add,
                    onTap: () => _adjustFontSize(2),
                    color: primaryColor,
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Font Family Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFontButton('Sans', 'Aa', _fontFamily == 'Sans', primaryColor),
              _buildFontButton('Serif', 'Aa', _fontFamily == 'Serif', primaryColor),
              _buildFontButton('Mono', 'Aa', _fontFamily == 'Mono', primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildFontButton(String family, String label, bool isSelected, Color primaryColor) {
    return Expanded(
      child: InkWell(
        onTap: () => _changeFontFamily(family),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? primaryColor.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? primaryColor 
                  : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: _getFontFamily(family),
                color: isSelected ? primaryColor : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getFontFamily([String? family]) {
    switch (family ?? _fontFamily) {
      case 'Sans':
        return 'Roboto';
      case 'Serif':
        return 'Georgia';
      case 'Mono':
        return 'Courier';
      default:
        return 'Roboto';
    }
  }

  void _showNoteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📝 Notiz hinzufügen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Deine Gedanken zu diesem Artikel...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveNote,
                    child: const Text('Speichern'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
