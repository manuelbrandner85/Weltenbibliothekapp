import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../services/cloudflare_api_service.dart';
import '../../services/image_upload_service.dart';
import '../../core/persistence/auto_save_manager.dart';

/// ✍️ Rich Text Content Editor
/// Features:
/// - Rich text formatting (bold, italic, headings)
/// - Image upload & gallery
/// - Draft auto-save (every 5s)
/// - Word & character count
/// - Preview mode
/// - Categories & tags
class ContentEditorScreen extends StatefulWidget {
  final String? draftId;
  final String? initialContent;
  
  const ContentEditorScreen({
    super.key,
    this.draftId,
    this.initialContent,
  });

  @override
  State<ContentEditorScreen> createState() => _ContentEditorScreenState();
}

class _ContentEditorScreenState extends State<ContentEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  
  final CloudflareApiService _api = CloudflareApiService();
  final ImageUploadService _imageService = ImageUploadService();
  final AutoSaveManager _autoSave = AutoSaveManager();
  
  String _selectedCategory = 'general';
  bool _isPreview = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  DateTime? _lastAutoSave;
  Timer? _autoSaveTimer;
  List<String> _uploadedImages = [];
  
  int _wordCount = 0;
  int _charCount = 0;
  
  final List<String> _categories = [
    'general',
    'research',
    'meditation',
    'astral',
    'conspiracy',
    'history',
    'science',
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Load draft if exists
    if (widget.draftId != null) {
      _loadDraft(widget.draftId!);
    } else if (widget.initialContent != null) {
      _bodyController.text = widget.initialContent!;
    }
    
    // Setup listeners
    _titleController.addListener(_onContentChanged);
    _bodyController.addListener(_onContentChanged);
    _tagsController.addListener(_onContentChanged);
    
    // Setup auto-save timer
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_hasUnsavedChanges) {
        _autoSaveDraft();
      }
    });
  }
  
  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDraft(String draftId) async {
    try {
      final draft = await _autoSave.loadDraft(draftId, boxName: 'content_drafts');
      if (draft != null) {
        setState(() {
          _titleController.text = draft['title'] ?? '';
          _bodyController.text = draft['body'] ?? '';
          _tagsController.text = draft['tags'] ?? '';
          _selectedCategory = draft['category'] ?? 'general';
          _uploadedImages = List<String>.from(draft['images'] ?? []);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading draft: $e');
      }
    }
  }
  
  void _onContentChanged() {
    setState(() {
      _hasUnsavedChanges = true;
      _wordCount = _bodyController.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
      _charCount = _bodyController.text.length;
    });
  }
  
  Future<void> _autoSaveDraft() async {
    if (!_hasUnsavedChanges) return;
    
    try {
      final draftId = widget.draftId ?? 'draft_${DateTime.now().millisecondsSinceEpoch}';
      
      _autoSave.scheduleSave(
        key: draftId,
        data: {
          'title': _titleController.text,
          'body': _bodyController.text,
          'tags': _tagsController.text,
          'category': _selectedCategory,
          'images': _uploadedImages,
          'lastSaved': DateTime.now().toIso8601String(),
        },
        boxName: 'content_drafts',
        priority: SavePriority.high,
      );
      
      setState(() {
        _hasUnsavedChanges = false;
        _lastAutoSave = DateTime.now();
      });
      
      if (kDebugMode) {
        debugPrint('✅ Draft auto-saved: $draftId');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Auto-save failed: $e');
      }
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final imageUrl = await _imageService.pickAndUploadImage();
      
      if (imageUrl != null) {
        setState(() {
          _uploadedImages.add(imageUrl);
          _hasUnsavedChanges = true;
        });
        
        // Insert image markdown
        final markdown = '\n![image]($imageUrl)\n';
        final currentText = _bodyController.text;
        final cursorPos = _bodyController.selection.baseOffset;
        
        _bodyController.text = currentText.substring(0, cursorPos) +
            markdown +
            currentText.substring(cursorPos);
        
        _showSnackBar('✅ Bild hochgeladen', Colors.green);
      }
    } catch (e) {
      _showSnackBar('❌ Fehler beim Hochladen', Colors.red);
    }
  }
  
  Future<void> _publishContent() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      _showSnackBar('❌ Titel und Inhalt erforderlich', Colors.orange);
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      await _api.createArticle({
        'title': _titleController.text,
        'content': _bodyController.text,
        'category': _selectedCategory,
        'tags': _tagsController.text.split(',').map((t) => t.trim()).toList(),
        'images': _uploadedImages,
      });
      
      // Delete draft after successful publish
      if (widget.draftId != null) {
        await _autoSave.deleteDraft(widget.draftId!, boxName: 'content_drafts');
      }
      
      _showSnackBar('✅ Inhalt veröffentlicht', Colors.green);
      
      // Navigate back after delay
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      _showSnackBar('❌ Fehler beim Veröffentlichen', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          return await _showUnsavedDialog() ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('✍️ Neuer Inhalt'),
          actions: [
            // Preview toggle
            IconButton(
              icon: Icon(_isPreview ? Icons.edit : Icons.preview),
              onPressed: () {
                setState(() => _isPreview = !_isPreview);
              },
              tooltip: _isPreview ? 'Bearbeiten' : 'Vorschau',
            ),
            
            // Publish button
            if (!_isPreview)
              TextButton.icon(
                onPressed: _isSaving ? null : _publishContent,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.publish),
                label: const Text('Veröffentlichen'),
              ),
          ],
        ),
        body: _isPreview ? _buildPreview() : _buildEditor(),
      ),
    );
  }
  
  Widget _buildEditor() {
    return Column(
      children: [
        // Auto-save indicator
        if (_lastAutoSave != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green[50],
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Automatisch gespeichert: ${_formatAutoSaveTime(_lastAutoSave!)}',
                  style: TextStyle(fontSize: 12, color: Colors.green[700]),
                ),
              ],
            ),
          ),
        
        // Editor
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Titel eingeben...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                maxLines: 2,
              ),
              
              const Divider(height: 32),
              
              // Category selector
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategorie',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                      _hasUnsavedChanges = true;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Body
              TextField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  hintText: 'Inhalt schreiben...\n\nMarkdown wird unterstützt:\n**fett** *kursiv* # Überschrift',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                minLines: 10,
              ),
              
              const SizedBox(height: 16),
              
              // Tags
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (kommagetrennt)',
                  border: OutlineInputBorder(),
                  hintText: 'z.B. meditation, astral, energie',
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Image gallery
              if (_uploadedImages.isNotEmpty) ...[
                const Text(
                  'Hochgeladene Bilder',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _uploadedImages.map((url) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            iconSize: 20,
                            onPressed: () {
                              setState(() {
                                _uploadedImages.remove(url);
                                _hasUnsavedChanges = true;
                              });
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Wörter: $_wordCount | Zeichen: $_charCount',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (_hasUnsavedChanges)
                    Text(
                      'Ungespeicherte Änderungen',
                      style: TextStyle(color: Colors.orange[700], fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
        ),
        
        // Toolbar
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.format_bold),
                onPressed: () => _insertMarkdown('**', '**'),
                tooltip: 'Fett',
              ),
              IconButton(
                icon: const Icon(Icons.format_italic),
                onPressed: () => _insertMarkdown('*', '*'),
                tooltip: 'Kursiv',
              ),
              IconButton(
                icon: const Icon(Icons.title),
                onPressed: () => _insertMarkdown('# ', ''),
                tooltip: 'Überschrift',
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.image),
                onPressed: _pickImage,
                tooltip: 'Bild hochladen',
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPreview() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _titleController.text.isNotEmpty ? _titleController.text : 'Titel Vorschau',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Kategorie: $_selectedCategory',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const Divider(height: 32),
        Text(_bodyController.text.isNotEmpty ? _bodyController.text : 'Inhalt Vorschau'),
        if (_tagsController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: _tagsController.text.split(',').map((tag) {
              return Chip(label: Text(tag.trim()));
            }).toList(),
          ),
        ],
      ],
    );
  }
  
  void _insertMarkdown(String before, String after) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    
    if (selection.isValid) {
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        before + text.substring(selection.start, selection.end) + after,
      );
      
      _bodyController.text = newText;
      _bodyController.selection = TextSelection.collapsed(
        offset: selection.start + before.length + (selection.end - selection.start) + after.length,
      );
    }
  }
  
  String _formatAutoSaveTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'gerade eben';
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
    return 'vor ${diff.inHours}h';
  }
  
  Future<bool?> _showUnsavedDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ungespeicherte Änderungen'),
          content: const Text('Möchtest du die Änderungen speichern?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Verwerfen'),
            ),
            TextButton(
              onPressed: () async {
                await _autoSaveDraft();
                if (mounted) Navigator.pop(context, true);
              },
              child: const Text('Speichern'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
          ],
        );
      },
    );
  }
}
