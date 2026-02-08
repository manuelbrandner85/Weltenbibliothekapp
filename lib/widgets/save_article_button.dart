import 'package:flutter/material.dart';
import '../services/offline_storage_service.dart';

/// Button zum Speichern/Entfernen von Artikeln für Offline-Zugriff
class SaveArticleButton extends StatefulWidget {
  final String articleId;
  final String title;
  final String content;
  final String category;
  final String world; // 'materie' oder 'energie'
  final String? imageUrl;
  final String? author;
  final DateTime? publishedDate;
  
  const SaveArticleButton({
    super.key,
    required this.articleId,
    required this.title,
    required this.content,
    required this.category,
    required this.world,
    this.imageUrl,
    this.author,
    this.publishedDate,
  });

  @override
  State<SaveArticleButton> createState() => _SaveArticleButtonState();
}

class _SaveArticleButtonState extends State<SaveArticleButton> with SingleTickerProviderStateMixin {
  final OfflineStorageService _offlineService = OfflineStorageService();
  late bool _isSaved;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isSaved = _offlineService.isArticleSaved(widget.articleId);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleSave() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      if (_isSaved) {
        // Entfernen
        final success = await _offlineService.deleteArticle(widget.articleId);
        if (success) {
          setState(() => _isSaved = false);
          _showSnackBar('Artikel entfernt', Icons.delete, Colors.red);
        }
      } else {
        // Speichern
        final success = await _offlineService.saveArticle(
          articleId: widget.articleId,
          title: widget.title,
          content: widget.content,
          category: widget.category,
          world: widget.world,
          imageUrl: widget.imageUrl,
          author: widget.author,
          publishedDate: widget.publishedDate,
        );
        
        if (success) {
          setState(() => _isSaved = true);
          _animationController.forward().then((_) {
            _animationController.reverse();
          });
          _showSnackBar('Offline gespeichert', Icons.check_circle, Colors.green);
        }
      }
    } catch (e) {
      _showSnackBar('Fehler: $e', Icons.error, Colors.red);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Text(message),
            ],
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          _isSaved ? Icons.bookmark : Icons.bookmark_border,
          color: _isSaved ? Colors.amber : Colors.grey.shade400,
        ),
        onPressed: _isProcessing ? null : _toggleSave,
        tooltip: _isSaved ? 'Gespeichert' : 'Offline speichern',
      ),
    );
  }
}

/// Kompakter Speichern-Button (für Listen)
class CompactSaveButton extends StatefulWidget {
  final String articleId;
  final String title;
  final String content;
  final String category;
  final String world;
  
  const CompactSaveButton({
    super.key,
    required this.articleId,
    required this.title,
    required this.content,
    required this.category,
    required this.world,
  });

  @override
  State<CompactSaveButton> createState() => _CompactSaveButtonState();
}

class _CompactSaveButtonState extends State<CompactSaveButton> {
  final OfflineStorageService _offlineService = OfflineStorageService();
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = _offlineService.isArticleSaved(widget.articleId);
  }

  Future<void> _toggleSave() async {
    if (_isSaved) {
      await _offlineService.deleteArticle(widget.articleId);
      setState(() => _isSaved = false);
    } else {
      await _offlineService.saveArticle(
        articleId: widget.articleId,
        title: widget.title,
        content: widget.content,
        category: widget.category,
        world: widget.world,
      );
      setState(() => _isSaved = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleSave,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _isSaved 
              ? Colors.green.withValues(alpha: 0.2) 
              : Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isSaved 
                ? Colors.green.withValues(alpha: 0.5) 
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isSaved ? Icons.offline_bolt : Icons.download,
              size: 14,
              color: _isSaved ? Colors.green.shade400 : Colors.grey.shade400,
            ),
            const SizedBox(width: 4),
            Text(
              _isSaved ? 'OFFLINE' : 'SPEICHERN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _isSaved ? Colors.green.shade400 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
