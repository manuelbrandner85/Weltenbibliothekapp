/// 🎨 INLINE CONTENT EDITOR
/// 
/// Edit-Funktionen direkt in den Screens (nicht im Admin-Dashboard)
/// Nur sichtbar für Root-Admin und Content-Editor
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../services/dynamic_content_service.dart';

/// Inline Edit Mode Wrapper
/// Wraps any widget and adds edit controls when in edit mode
class InlineEditWrapper extends StatefulWidget {
  final Widget child;
  final String contentType;  // 'tab', 'tool', 'marker', 'text', 'button'
  final String contentId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  
  const InlineEditWrapper({
    super.key,
    required this.child,
    required this.contentType,
    required this.contentId,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<InlineEditWrapper> createState() => _InlineEditWrapperState();
}

class _InlineEditWrapperState extends State<InlineEditWrapper> {
  bool _canEdit = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final service = DynamicContentService();
    final canEdit = await service.canEditContent();
    
    if (mounted) {
      setState(() {
        _canEdit = canEdit;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Normal user - no edit controls
    if (!_canEdit) {
      return widget.child;
    }
    
    // Admin - show with edit controls
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Stack(
        children: [
          // Original Content
          Container(
            decoration: _isHovering
                ? BoxDecoration(
                    border: Border.all(
                      color: Colors.deepPurple.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: widget.child,
          ),
          
          // Edit Controls (nur bei Hover)
          if (_isHovering)
            Positioned(
              top: 4,
              right: 4,
              child: _buildEditControls(),
            ),
        ],
      ),
    );
  }

  Widget _buildEditControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit Button
          IconButton(
            icon: const Icon(Icons.edit, size: 16, color: Colors.white),
            onPressed: () => _showInlineEditor(context),
            tooltip: 'Bearbeiten',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          
          // Delete Button
          IconButton(
            icon: const Icon(Icons.delete, size: 16, color: Colors.white),
            onPressed: () => _confirmDelete(context),
            tooltip: 'Löschen',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  void _showInlineEditor(BuildContext context) {
    if (widget.onEdit != null) {
      widget.onEdit!();
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => InlineEditDialog(
        contentType: widget.contentType,
        contentId: widget.contentId,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Löschen bestätigen'),
        content: Text(
          'Möchten Sie diesen ${widget.contentType} wirklich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      if (widget.onDelete != null) {
        widget.onDelete!();
      } else {
        _deleteContent();
      }
    }
  }

  Future<void> _deleteContent() async {
    // TODO: Delete via API
    if (kDebugMode) {
      debugPrint('🗑️  Delete ${widget.contentType}: ${widget.contentId}');
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Inhalt gelöscht')),
      );
    }
  }
}

/// Inline Edit Dialog
/// Quick edit dialog that opens directly in the current screen
class InlineEditDialog extends StatefulWidget {
  final String contentType;
  final String contentId;
  
  const InlineEditDialog({
    super.key,
    required this.contentType,
    required this.contentId,
  });

  @override
  State<InlineEditDialog> createState() => _InlineEditDialogState();
}

class _InlineEditDialogState extends State<InlineEditDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    // TODO: Load content from API
    if (kDebugMode) {
      debugPrint('📥 Load ${widget.contentType}: ${widget.contentId}');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.contentType.toUpperCase()} bearbeiten',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            
            // Form
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titel',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Speichern'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    
    // TODO: Save to API
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Änderungen gespeichert')),
      );
    }
  }
}

/// Edit Mode Toggle Button
/// Floating button to enable/disable edit mode globally
class EditModeToggle extends StatefulWidget {
  const EditModeToggle({super.key});

  @override
  State<EditModeToggle> createState() => _EditModeToggleState();
}

class _EditModeToggleState extends State<EditModeToggle> {
  bool _canEdit = false;
  bool _editModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final service = DynamicContentService();
    final canEdit = await service.canEditContent();
    
    if (mounted) {
      setState(() {
        _canEdit = canEdit;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hide for normal users
    if (!_canEdit) {
      return const SizedBox.shrink();
    }
    
    return Positioned(
      bottom: 80,
      right: 16,
      child: FloatingActionButton.extended(
        heroTag: 'edit_mode_toggle',
        onPressed: _toggleEditMode,
        backgroundColor: _editModeEnabled 
            ? Colors.orange 
            : Colors.deepPurple,
        icon: Icon(_editModeEnabled ? Icons.edit_off : Icons.edit),
        label: Text(_editModeEnabled ? 'Edit-Modus AUS' : 'Edit-Modus AN'),
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _editModeEnabled = !_editModeEnabled;
    });
    
    // TODO: Notify all InlineEditWrappers
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_editModeEnabled 
            ? '✏️  Edit-Modus aktiviert - Hover über Elemente zum Bearbeiten'
            : '👁️  Edit-Modus deaktiviert'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Quick Add Button
/// Adds new content directly in the current screen
class QuickAddButton extends StatelessWidget {
  final String contentType;
  final VoidCallback onAdd;
  
  const QuickAddButton({
    super.key,
    required this.contentType,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'quick_add_$contentType',
      onPressed: onAdd,
      backgroundColor: Colors.green,
      child: const Icon(Icons.add),
    );
  }
}
