// 🌍 UNIVERSAL EDIT WRAPPER - Macht JEDES Widget editierbar
// Phase 4B.1: Universal Edit System für ALLE Welten
// Automatisch editierbar wenn Edit-Modus aktiv + Nutzer hat Rechte

import 'package:flutter/material.dart';
import '../services/edit_mode_service.dart';
import '../services/universal_content_service.dart';

/// Enum für alle editierbaren Content-Typen
enum EditableContentType {
  text,        // String (Title, Label, Hint, etc.)
  button,      // Button Label + Optional Tooltip
  icon,        // IconData oder Emoji String
  color,       // Color (#HEX)
  font,        // Font Family/Size/Weight
  image,       // Image URL/Asset Path
  navigation,  // Route Name + Params
}

/// 🎯 UNIVERSAL EDIT WRAPPER
/// Wraps any Widget and makes it editable in Edit Mode
/// 
/// Usage:
/// ```dart
/// EditWrapper(
///   contentId: 'energie.chat.title',
///   contentType: EditableContentType.text,
///   defaultValue: 'ENERGIE LIVE-CHAT',
///   child: Text(_appBarTitle),
/// )
/// ```
class EditWrapper extends StatefulWidget {
  /// Eindeutige Content-ID (hierarchisch): 'world.screen.section.element'
  /// Beispiele:
  /// - 'energie.chat.appbar.title'
  /// - 'materie.research.search.placeholder'
  /// - 'spirit.meditation.timer.start_button'
  final String contentId;
  
  /// Typ des Inhalts (text, button, icon, color, font, image, navigation)
  final EditableContentType contentType;
  
  /// Kind Widget (das editiert werden soll)
  final Widget child;
  
  /// Default-Value (Fallback wenn kein Backend-Value)
  final dynamic defaultValue;
  
  /// Optional: Label für Edit-Dialog
  final String? label;
  
  /// Optional: Beschreibung für Edit-Dialog
  final String? description;
  
  /// Optional: Callback nach erfolgreichem Speichern
  final Function(dynamic newValue)? onSaved;
  
  /// Optional: Custom Validator
  final String? Function(dynamic value)? validator;
  
  const EditWrapper({
    super.key,
    required this.contentId,
    required this.contentType,
    required this.child,
    required this.defaultValue,
    this.label,
    this.description,
    this.onSaved,
    this.validator,
  });

  @override
  State<EditWrapper> createState() => _EditWrapperState();
}

class _EditWrapperState extends State<EditWrapper> {
  final _editModeService = EditModeService.instance;
  final _contentService = UniversalContentService.instance;
  
  bool _isHovering = false;
  bool _canEdit = false;
  bool _isCheckingPermissions = true;
  
  @override
  void initState() {
    super.initState();
    _checkEditPermissions();
  }
  
  /// Check if user has edit permissions
  Future<void> _checkEditPermissions() async {
    final canEdit = await _contentService.canEditContent();
    if (mounted) {
      setState(() {
        _canEdit = canEdit;
        _isCheckingPermissions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wenn noch Permissions gecheckt werden -> Zeige Child ohne Edit-Button
    if (_isCheckingPermissions) {
      return widget.child;
    }
    
    // Wenn NICHT im Edit-Modus -> Zeige nur Child ohne Edit-Button
    if (!_editModeService.isEditMode) {
      return widget.child;
    }
    
    // Wenn KEIN Edit-Recht -> Zeige nur Child
    if (!_canEdit) {
      return widget.child;
    }
    
    // Edit-Modus aktiv + User hat Rechte -> Zeige Child + Edit-Button
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Original Widget
          widget.child,
          
          // Edit-Button Overlay (nur bei Hover sichtbar)
          if (_isHovering)
            Positioned(
              top: -8,
              right: -8,
              child: _buildEditButton(),
            ),
        ],
      ),
    );
  }
  
  /// 🖊️ BUILD EDIT BUTTON
  Widget _buildEditButton() {
    return GestureDetector(
      onTap: () => _showEditDialog(),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF9B51E0),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.edit,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }
  
  /// 📝 SHOW UNIVERSAL EDIT DIALOG
  Future<void> _showEditDialog() async {
    // Aktuellen Wert aus Content Service holen
    final currentValue = _getCurrentValue();
    
    // Dialog öffnen basierend auf Content Type
    final newValue = await _showTypeSpecificDialog(context, currentValue);
    
    // Wenn Wert geändert wurde -> Speichern
    if (newValue != null && newValue != currentValue) {
      await _saveContent(newValue);
    }
  }
  
  /// 📥 GET CURRENT VALUE
  dynamic _getCurrentValue() {
    // Versuche Wert aus Content Service zu holen
    try {
      final cachedContent = _contentService.getCachedGenericContent(widget.contentId);
      if (cachedContent != null && cachedContent['value'] != null) {
        return cachedContent['value'];
      }
    } catch (e) {
      debugPrint('⚠️ EditWrapper: Fehler beim Laden von ${widget.contentId}: $e');
    }
    
    // Fallback zu Default Value
    return widget.defaultValue;
  }
  
  /// 💾 SAVE CONTENT
  Future<void> _saveContent(dynamic newValue) async {
    try {
      // Validation (wenn vorhanden)
      if (widget.validator != null) {
        final error = widget.validator!(newValue);
        if (error != null) {
          _showErrorSnackBar(error);
          return;
        }
      }
      
      // Speichern über Content Service
      await _contentService.saveGenericContent(
        widget.contentId,
        newValue,
        contentType: widget.contentType.name,
      );
      
      // Callback (wenn vorhanden)
      widget.onSaved?.call(newValue);
      
      // Success Feedback
      _showSuccessSnackBar('✅ Erfolgreich gespeichert!');
      
      // UI Update triggern
      setState(() {});
      
    } catch (e) {
      debugPrint('❌ EditWrapper: Fehler beim Speichern von ${widget.contentId}: $e');
      _showErrorSnackBar('Fehler beim Speichern: $e');
    }
  }
  
  /// 🎨 SHOW TYPE-SPECIFIC EDIT DIALOG
  Future<dynamic> _showTypeSpecificDialog(BuildContext context, dynamic currentValue) async {
    switch (widget.contentType) {
      case EditableContentType.text:
        return _showTextEditDialog(context, currentValue);
      
      case EditableContentType.button:
        return _showButtonEditDialog(context, currentValue);
      
      case EditableContentType.icon:
        return _showIconPickerDialog(context, currentValue);
      
      case EditableContentType.color:
        return _showColorPickerDialog(context, currentValue);
      
      case EditableContentType.font:
        return _showFontEditDialog(context, currentValue);
      
      case EditableContentType.image:
        return _showImagePickerDialog(context, currentValue);
      
      case EditableContentType.navigation:
        return _showNavigationEditDialog(context, currentValue);
    }
  }
  
  /// 📝 TEXT EDIT DIALOG
  Future<String?> _showTextEditDialog(BuildContext context, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          widget.label ?? 'Text bearbeiten',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.description != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  widget.description!,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Text eingeben...',
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF16213E),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B51E0),
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
  
  /// 🔘 BUTTON EDIT DIALOG
  Future<Map<String, dynamic>?> _showButtonEditDialog(
    BuildContext context,
    dynamic currentValue,
  ) async {
    final labelController = TextEditingController(
      text: currentValue is Map ? currentValue['label'] : currentValue.toString(),
    );
    final tooltipController = TextEditingController(
      text: currentValue is Map ? currentValue['tooltip'] ?? '' : '',
    );
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Button bearbeiten', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Button Label',
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF16213E),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tooltipController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Tooltip (Optional)',
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF16213E),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'label': labelController.text,
              'tooltip': tooltipController.text,
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B51E0),
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
  
  /// 🎨 ICON PICKER DIALOG (Simplified - zeigt Emoji-Auswahl)
  Future<String?> _showIconPickerDialog(BuildContext context, dynamic currentValue) async {
    final iconController = TextEditingController(text: currentValue.toString());
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Icon bearbeiten', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Emoji oder Icon-Name eingeben:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: iconController,
              style: const TextStyle(color: Colors.white, fontSize: 24),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '🎨',
                filled: true,
                fillColor: Color(0xFF16213E),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, iconController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B51E0),
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
  
  /// 🎨 COLOR PICKER DIALOG (Simplified - HEX Input)
  Future<Color?> _showColorPickerDialog(BuildContext context, dynamic currentValue) async {
    Color color = currentValue is Color ? currentValue : const Color(0xFF9B51E0);
    // Use toARGB32() instead of deprecated .value
    final hexValue = color.toARGB32().toRadixString(16).substring(2).toUpperCase();
    final hexController = TextEditingController(text: '#$hexValue');
    
    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Farbe bearbeiten', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hexController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'HEX Color (#RRGGBB)',
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF16213E),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final hex = hexController.text.replaceAll('#', '');
                final newColor = Color(int.parse('FF$hex', radix: 16));
                Navigator.pop(context, newColor);
              } catch (e) {
                _showErrorSnackBar('Ungültige Farbe: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B51E0),
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
  
  /// 🔤 FONT EDIT DIALOG (Simplified - Size only for now)
  Future<Map<String, dynamic>?> _showFontEditDialog(
    BuildContext context,
    dynamic currentValue,
  ) async {
    final sizeController = TextEditingController(
      text: (currentValue is Map ? currentValue['size'] : 16).toString(),
    );
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Schrift bearbeiten', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: sizeController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Schriftgröße (px)',
            labelStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Color(0xFF16213E),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'size': double.tryParse(sizeController.text) ?? 16,
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B51E0),
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
  
  /// 🖼️ IMAGE PICKER DIALOG (Simplified - URL Input)
  Future<String?> _showImagePickerDialog(BuildContext context, dynamic currentValue) async {
    final urlController = TextEditingController(text: currentValue.toString());
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Bild bearbeiten', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: urlController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Bild-URL oder Asset-Path',
            labelStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Color(0xFF16213E),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, urlController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B51E0),
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
  
  /// 🧭 NAVIGATION EDIT DIALOG (Simplified - Route Input)
  Future<String?> _showNavigationEditDialog(BuildContext context, dynamic currentValue) async {
    final routeController = TextEditingController(text: currentValue.toString());
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Navigation bearbeiten', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: routeController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Route Name (z.B. /energie/meditation)',
            labelStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Color(0xFF16213E),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, routeController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B51E0),
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
  
  /// ✅ SUCCESS SNACKBAR
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// ❌ ERROR SNACKBAR
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
