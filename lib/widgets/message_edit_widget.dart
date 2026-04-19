import 'package:flutter/material.dart';

/// Message Edit Widget
/// In-Place-Editing für Chat-Nachrichten
class MessageEditWidget extends StatefulWidget {
  final Map<String, dynamic> message;
  final Function(String newContent) onSave;
  final VoidCallback onCancel;
  
  const MessageEditWidget({
    super.key,
    required this.message,
    required this.onSave,
    required this.onCancel,
  });
  
  @override
  State<MessageEditWidget> createState() => _MessageEditWidgetState();
}

class _MessageEditWidgetState extends State<MessageEditWidget> {
  late TextEditingController _controller;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.message['message']?.toString() ?? '',
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _save() async {
    final newContent = _controller.text.trim();
    
    if (newContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nachricht darf nicht leer sein'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      widget.onSave(newContent);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Nachricht aktualisiert'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9B51E0),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.edit,
                color: Color(0xFF9B51E0),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Nachricht bearbeiten',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Cancel Button
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: _isSaving ? null : widget.onCancel,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Text Field
          TextField(
            controller: _controller,
            enabled: !_isSaving,
            autofocus: true,
            maxLines: 4,
            minLines: 1,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nachricht eingeben...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF9B51E0),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Cancel
              TextButton(
                onPressed: _isSaving ? null : widget.onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
                child: const Text('Abbrechen'),
              ),
              const SizedBox(width: 8),
              
              // Save
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B51E0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Speichern'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
