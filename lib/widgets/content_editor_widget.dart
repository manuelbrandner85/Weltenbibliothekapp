/// 🎨 CONTENT EDITOR WIDGET
/// 
/// Admin UI für Live-Bearbeitung von Content
/// Nur sichtbar für Root-Admin und Content-Editor
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:image_picker/image_picker.dart';
import '../services/dynamic_content_service.dart';
import '../core/constants/roles.dart';

/// Content Editor Button (Floating Action Button)
/// Zeigt Edit-Modus-Button nur für berechtigte User
class ContentEditorButton extends StatefulWidget {
  final String contentType;  // 'tab', 'tool', 'marker'
  final String contentId;
  final VoidCallback? onEditPressed;
  
  const ContentEditorButton({
    super.key,
    required this.contentType,
    required this.contentId,
    this.onEditPressed,
  });

  @override
  State<ContentEditorButton> createState() => _ContentEditorButtonState();
}

class _ContentEditorButtonState extends State<ContentEditorButton> {
  bool _canEdit = false;
  bool _isLoading = true;

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
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading
    if (_isLoading) {
      return const SizedBox.shrink();
    }
    
    // No permission
    if (!_canEdit) {
      return const SizedBox.shrink();
    }
    
    // Show Edit Button
    return FloatingActionButton(
      heroTag: 'edit_${widget.contentId}',
      onPressed: widget.onEditPressed ?? _openEditor,
      backgroundColor: Colors.deepPurple,
      child: const Icon(Icons.edit),
    );
  }

  void _openEditor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentEditorScreen(
          contentType: widget.contentType,
          contentId: widget.contentId,
        ),
      ),
    );
  }
}

/// Content Editor Screen
/// Vollständige Edit-UI für alle Content-Typen
class ContentEditorScreen extends StatefulWidget {
  final String contentType;
  final String contentId;
  
  const ContentEditorScreen({
    super.key,
    required this.contentType,
    required this.contentId,
  });

  @override
  State<ContentEditorScreen> createState() => _ContentEditorScreenState();
}

class _ContentEditorScreenState extends State<ContentEditorScreen> {
  final _service = DynamicContentService();
  bool _isSandboxMode = false;
  String? _userRole;
  
  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _userRole = await _service.getCurrentUserRole();
    _isSandboxMode = _service.isSandboxMode();
    
    // Load content data based on type and id
    await _service.initialize();
    
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.contentType.toUpperCase()} bearbeiten'),
        actions: [
          // Sandbox Toggle
          IconButton(
            icon: Icon(_isSandboxMode ? Icons.visibility : Icons.visibility_off),
            onPressed: _toggleSandbox,
            tooltip: _isSandboxMode ? 'Sandbox aktiv' : 'Sandbox inaktiv',
          ),
          
          // Save Button
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'Speichern',
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Banner
          _buildInfoBanner(),
          
          // Editor Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildEditorForm(),
            ),
          ),
          
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    final roleColor = _userRole == AppRoles.rootAdmin 
        ? Colors.red 
        : Colors.deepPurple;
    
    final roleName = AppRoles.getRoleName(_userRole);
    
    return Container(
      padding: const EdgeInsets.all(12),
      color: roleColor.withValues(alpha: 0.2),
      child: Row(
        children: [
          Icon(Icons.shield, color: roleColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bearbeitung als: $roleName',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                  ),
                ),
                Text(
                  AppRoles.getPermissionSummary(_userRole),
                  style: TextStyle(fontSize: 12, color: roleColor),
                ),
              ],
            ),
          ),
          if (_isSandboxMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'SANDBOX',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditorForm() {
    switch (widget.contentType) {
      case 'tab':
        return _buildTabEditor();
      case 'marker':
        return _buildMarkerEditor();
      case 'tool':
        return _buildToolEditor();
      default:
        return _buildGenericEditor();
    }
  }

  Widget _buildTabEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Tab-Titel',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Icon Picker
        _buildIconPicker(),
        const SizedBox(height: 16),
        
        // Color Picker
        _buildColorPicker(),
        const SizedBox(height: 16),
        
        // Order
        _buildOrderSelector(),
        const SizedBox(height: 16),
        
        // Visibility Toggle
        _buildVisibilityToggle(),
      ],
    );
  }

  Widget _buildMarkerEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Marker-Titel',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        
        // Description
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Beschreibung',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        
        // Location Picker
        _buildLocationPicker(),
        const SizedBox(height: 16),
        
        // Category Picker
        _buildCategoryPicker(),
        const SizedBox(height: 16),
        
        // Media Upload
        _buildMediaUpload(),
      ],
    );
  }

  Widget _buildToolEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tool-Editor',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text('Tool-Editor ist nur für Root-Admins verfügbar.\nNutze das Admin-Dashboard für Tool-Verwaltung.'),
      ],
    );
  }

  Widget _buildGenericEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildIconPicker() {
    final icons = ['⭐', '🔥', '💎', '🌍', '✨', '🎯', '📚', '🔮', '🌙', '☀️', '🌊', '🎵'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Icon auswählen', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: icons
                  .map((icon) => InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(icon, style: const TextStyle(fontSize: 24)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final colors = [Colors.blue, Colors.purple, Colors.green, Colors.orange,
      Colors.red, Colors.teal, Colors.indigo, Colors.pink];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Farbe auswählen', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: colors
                  .map((c) => InkWell(
                        onTap: () {},
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reihenfolge', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Slider(
              value: 1.0,
              min: 1,
              max: 10,
              divisions: 9,
              label: '1',
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityToggle() {
    return Card(
      child: SwitchListTile(
        title: const Text('Sichtbar'),
        subtitle: const Text('Tab für User anzeigen'),
        value: _isSandboxMode ? false : true,
        onChanged: (value) {
          _service.updateInSandbox(widget.contentType, widget.contentId, {'visible': value});
        },
      ),
    );
  }

  Widget _buildLocationPicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Position', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Standort-Eingabe: Lat/Lng manuell eingeben'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Breitengrad', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Längengrad', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kategorie', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              value: 'allgemein',
              items: ['allgemein', 'tool', 'screen', 'tab', 'marker']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaUpload() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medien', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _uploadImage,
              icon: const Icon(Icons.image),
              label: const Text('Bild hochladen'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _uploadVideo,
              icon: const Icon(Icons.video_library),
              label: const Text('Video hochladen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Discard Button
          Expanded(
            child: OutlinedButton(
              onPressed: _discardChanges,
              child: const Text('Verwerfen'),
            ),
          ),
          const SizedBox(width: 12),
          
          // Publish Button
          Expanded(
            child: ElevatedButton(
              onPressed: _publishContent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Veröffentlichen'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSandbox() async {
    if (_isSandboxMode) {
      _service.disableSandboxMode();
    } else {
      _service.enableSandboxMode(); // Remove await since method returns void
    }
    
    if (mounted) {
      setState(() {
        _isSandboxMode = _service.isSandboxMode();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSandboxMode 
              ? '🔒 Sandbox-Modus aktiviert' 
              : '🔓 Sandbox-Modus deaktiviert'),
        ),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (kDebugMode) debugPrint('💾 Saving changes...');
    
    try {
      // Save via sandbox update
      _service.updateInSandbox(widget.contentType, widget.contentId, {
        'title': _titleController.text,
        'description': _descriptionController.text,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Änderungen gespeichert')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Speichern fehlgeschlagen: $e')),
        );
      }
    }
  }

  Future<void> _publishContent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Content veröffentlichen?'),
        content: const Text(
          'Dieser Content wird sofort für alle User sichtbar sein.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Veröffentlichen'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _service.publishSandboxChanges();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🚀 Content veröffentlicht!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Veröffentlichen fehlgeschlagen: $e')),
          );
        }
      }
    }
  }

  void _discardChanges() {
    Navigator.pop(context);
  }

  Future<void> _uploadImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📷 Bild ausgewählt: ${image.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Bild-Upload fehlgeschlagen: $e')),
        );
      }
    }
  }

  Future<void> _uploadVideo() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎥 Video ausgewählt: ${video.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Video-Upload fehlgeschlagen: $e')),
        );
      }
    }
  }
}
