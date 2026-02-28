import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:convert';
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';

/// 🌙 Astrales Tagebuch Screen
/// Außerkörperliche Erfahrungen dokumentieren & teilen
class AstralJournalScreen extends StatefulWidget {
  final String roomId;
  
  const AstralJournalScreen({
    super.key,
    this.roomId = 'astralreisen',
  });

  @override
  State<AstralJournalScreen> createState() => _AstralJournalScreenState();
}

class _AstralJournalScreenState extends State<AstralJournalScreen> {
  final GroupToolsService _toolsService = GroupToolsService();
  final UserService _userService = UserService();
  
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;
  String _username = '';
  String _userId = '';
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadEntries();
  }
  
  Future<void> _loadUserData() async {
    final user = await _userService.getCurrentUser();
    setState(() {
      _username = user.username;
      _userId = 'user_${user.username.toLowerCase()}';
    });
  }
  
  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final entries = await _toolsService.getAstralJournal(
        roomId: widget.roomId,
        limit: 50,
      );
      
      if (kDebugMode) {
        debugPrint('🌙 Loaded ${entries.length} entries');
      }
      
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading entries: $e');
      }
      setState(() {
        _errorMessage = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _showAddEntryDialog() async {
    if (_username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Bitte erstelle erst ein Profil'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddAstralEntryDialog(
        username: _username,
        userId: _userId,
        roomId: widget.roomId,
      ),
    );
    
    if (result != null && result['success'] == true) {
      _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['title']} hinzugefügt!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('🌙 Astrales Tagebuch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadEntries(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bedtime, size: 64, color: Colors.purple),
                          const SizedBox(height: 16),
                          const Text(
                            'Noch keine Astralreisen',
                            style: TextStyle(color: Colors.white70, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Dokumentiere deine erste außerkörperliche Erfahrung!',
                            style: TextStyle(color: Colors.white38),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return _buildEntryCard(entry);
                      },
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEntryDialog,
        backgroundColor: const Color(0xFF9C27B0),
        icon: const Icon(Icons.add),
        label: const Text('Reise dokumentieren'),
      ),
    );
  }
  
  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final title = entry['title'] ?? 'Unbekannt';
    final experience = entry['experience'] ?? '';
    final username = entry['username'] ?? 'Anonym';
    final successLevel = entry['success_level'] ?? 3;
    final likes = entry['likes'] ?? 0;
    
    // Parse techniques
    List<String> techniques = [];
    try {
      final techJson = entry['techniques_used'];
      if (techJson is String && techJson.isNotEmpty) {
        techniques = List<String>.from(
          techJson.startsWith('[') 
            ? (jsonDecode(techJson) as List) 
            : [techJson]
        );
      } else if (techJson is List) {
        techniques = List<String>.from(techJson);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing techniques: $e');
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
                    ),
                  ),
                  child: const Icon(Icons.bedtime, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        username,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Success Level Stars
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < successLevel ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Experience
            Text(
              experience,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Techniques
            if (techniques.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: techniques.map((tech) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      tech,
                      style: const TextStyle(color: Colors.purple, fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ],
            
            // Footer
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.favorite, size: 16, color: Colors.purple),
                const SizedBox(width: 4),
                Text(
                  likes.toString(),
                  style: const TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _AstralEntryDetailsDialog(entry: entry),
                    );
                  },
                  child: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// 🌙 ADD ASTRAL ENTRY DIALOG
// ========================================

class _AddAstralEntryDialog extends StatefulWidget {
  final String username;
  final String userId;
  final String roomId;
  
  const _AddAstralEntryDialog({
    required this.username,
    required this.userId,
    required this.roomId,
  });

  @override
  State<_AddAstralEntryDialog> createState() => _AddAstralEntryDialogState();
}

class _AddAstralEntryDialogState extends State<_AddAstralEntryDialog> {
  final GroupToolsService _toolsService = GroupToolsService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _experienceController = TextEditingController();
  final _techniqueController = TextEditingController();
  
  final List<String> _techniques = [];
  int _successLevel = 3;
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    _experienceController.dispose();
    _techniqueController.dispose();
    super.dispose();
  }
  
  void _addTechnique() {
    final tech = _techniqueController.text.trim();
    if (tech.isNotEmpty && !_techniques.contains(tech)) {
      setState(() {
        _techniques.add(tech);
        _techniqueController.clear();
      });
    }
  }
  
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final entryId = await _toolsService.createAstralEntry(
        roomId: widget.roomId,
        userId: widget.userId,
        username: widget.username,
        title: _titleController.text.trim(),
        experience: _experienceController.text.trim(),
        techniques: _techniques,
        successLevel: _successLevel,
      );
      
      if (entryId != null && mounted) {
        Navigator.of(context).pop({
          'success': true,
          'title': _titleController.text.trim(),
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Fehler beim Hinzufügen'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
                        ),
                      ),
                      child: const Icon(Icons.bedtime, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '🌙 Astralreise dokumentieren',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Title
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Titel *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'z.B. Erste erfolgreiche Projektion',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte Titel eingeben';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Experience
                TextFormField(
                  controller: _experienceController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Erfahrung *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'Beschreibe deine außerkörperliche Erfahrung...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte Erfahrung beschreiben';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Success Level
                const Text(
                  'Erfolgs-Level',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final level = index + 1;
                    return IconButton(
                      onPressed: () {
                        setState(() => _successLevel = level);
                      },
                      icon: Icon(
                        level <= _successLevel ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 16),
                
                // Techniques
                const Text(
                  'Verwendete Techniken',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _techniqueController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'z.B. Rope-Technik',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _addTechnique(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addTechnique,
                      icon: const Icon(Icons.add_circle, color: Colors.purple),
                    ),
                  ],
                ),
                
                if (_techniques.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _techniques.map((tech) {
                      return Chip(
                        label: Text(tech),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() => _techniques.remove(tech));
                        },
                        backgroundColor: Colors.purple.withValues(alpha: 0.2),
                        labelStyle: const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Abbrechen'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF673AB7),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Hinzufügen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================
// 🌙 ASTRAL ENTRY DETAILS DIALOG
// ========================================

class _AstralEntryDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> entry;
  
  const _AstralEntryDetailsDialog({required this.entry});

  @override
  Widget build(BuildContext context) {
    final title = entry['title'] ?? 'Unbekannt';
    final experience = entry['experience'] ?? '';
    final username = entry['username'] ?? 'Anonym';
    final successLevel = entry['success_level'] ?? 3;
    final likes = entry['likes'] ?? 0;
    
    // Parse techniques
    List<String> techniques = [];
    try {
      final techJson = entry['techniques_used'];
      if (techJson is String && techJson.isNotEmpty) {
        techniques = List<String>.from(
          techJson.startsWith('[') 
            ? (jsonDecode(techJson) as List) 
            : [techJson]
        );
      } else if (techJson is List) {
        techniques = List<String>.from(techJson);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing techniques in details: $e');
      }
    }
    
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
                      ),
                    ),
                    child: const Icon(Icons.bedtime, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < successLevel ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Experience
              const Text(
                'Erfahrung',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                experience,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
              ),
              
              // Techniques
              if (techniques.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Verwendete Techniken',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: techniques.map((tech) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        tech,
                        style: const TextStyle(color: Colors.purple, fontSize: 14),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: Colors.white54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        username,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ),
                    const Icon(Icons.favorite, size: 20, color: Colors.purple),
                    const SizedBox(width: 4),
                    Text(
                      likes.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
