/// KICK USER DIALOG
/// Vollständiger Dialog zum Entfernen von Usern aus Voice Chat
/// 
/// Features:
/// - Grund-Auswahl (Vordefiniert + Custom)
/// - Optional: Grund-Text eingeben
/// - Confirmation
/// - Cooldown-Info

import 'package:flutter/material.dart';

class KickUserDialog extends StatefulWidget {
  final String username;
  final String userId;
  final Function(String? reason) onKick;
  
  const KickUserDialog({
    super.key,
    required this.username,
    required this.userId,
    required this.onKick,
  });

  @override
  State<KickUserDialog> createState() => _KickUserDialogState();
}

class _KickUserDialogState extends State<KickUserDialog> {
  String? _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  bool _useCustomReason = false;
  
  final List<String> _predefinedReasons = [
    'Spam',
    'Beleidigung',
    'Störendes Verhalten',
    'Unangemessene Inhalte',
    'Regelverstoß',
  ];
  
  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }
  
  String? get _finalReason {
    if (_useCustomReason) {
      final custom = _customReasonController.text.trim();
      return custom.isEmpty ? null : custom;
    }
    return _selectedReason;
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.exit_to_app,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User entfernen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.username,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Info Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Der User wird aus dem Voice Chat entfernt und kann erst nach 30 Sekunden wieder beitreten.',
                      style: TextStyle(
                        color: Colors.orange.shade200,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Grund auswählen
            const Text(
              'Grund für Entfernung (Optional)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Vordefinierte Gründe
            if (!_useCustomReason) ...[
              ...(_predefinedReasons.map((reason) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedReason = _selectedReason == reason ? null : reason;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedReason == reason
                          ? Colors.red.withOpacity(0.2)
                          : const Color(0xFF252538),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedReason == reason
                            ? Colors.red
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedReason == reason
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: _selectedReason == reason
                              ? Colors.red
                              : Colors.white.withOpacity(0.3),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          reason,
                          style: TextStyle(
                            color: _selectedReason == reason
                                ? Colors.white
                                : Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: _selectedReason == reason
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ))),
              
              // Custom Reason Button
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _useCustomReason = true;
                      _selectedReason = null;
                    });
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Eigenen Grund eingeben'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
              ),
            ],
            
            // Custom Reason TextField
            if (_useCustomReason) ...[
              TextField(
                controller: _customReasonController,
                maxLines: 3,
                maxLength: 200,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Grund für Entfernung eingeben...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF252538),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
              
              // Back to predefined
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _useCustomReason = false;
                    _customReasonController.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Zurück zur Auswahl'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onKick(_finalReason);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Entfernen',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
