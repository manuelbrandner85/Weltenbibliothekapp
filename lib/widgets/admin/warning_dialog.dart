/// WARNING DIALOG
/// Vollständiger Dialog zum Aussprechen von Verwarnungen
/// 
/// Features:
/// - Verwarnung mit Grund
/// - Warning-Counter (X/3)
/// - Automatischer Ban bei 3 Warnings
/// - Vordefinierte Gründe + Custom
library;

import 'package:flutter/material.dart';

class WarningDialog extends StatefulWidget {
  final String username;
  final String userId;
  final int currentWarningCount;
  final Function(String reason) onWarn;
  
  const WarningDialog({
    super.key,
    required this.username,
    required this.userId,
    required this.currentWarningCount,
    required this.onWarn,
  });

  @override
  State<WarningDialog> createState() => _WarningDialogState();
}

class _WarningDialogState extends State<WarningDialog> {
  String? _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  bool _useCustomReason = false;
  
  final List<String> _predefinedReasons = [
    'Spam',
    'Unangemessene Sprache',
    'Störendes Verhalten',
    'Off-Topic',
    'Respektloses Verhalten',
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
  
  bool get _canSubmit {
    if (_useCustomReason) {
      return _customReasonController.text.trim().isNotEmpty;
    }
    return _selectedReason != null;
  }
  
  @override
  Widget build(BuildContext context) {
    final newWarningCount = widget.currentWarningCount + 1;
    final willBeBanned = newWarningCount >= 3;
    
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
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
                      color: Colors.orange.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verwarnung aussprechen',
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
                            color: Colors.white.withValues(alpha: 0.7),
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
              
              // Warning Counter
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: willBeBanned
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: willBeBanned
                        ? Colors.red.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final isFilled = index < newWarningCount;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            isFilled
                                ? Icons.warning_amber_rounded
                                : Icons.warning_amber_outlined,
                            color: isFilled
                                ? (willBeBanned ? Colors.red : Colors.orange)
                                : Colors.white.withValues(alpha: 0.3),
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      willBeBanned
                          ? '⚠️ LETZTE VERWARNUNG!'
                          : 'Verwarnung $newWarningCount/3',
                      style: TextStyle(
                        color: willBeBanned ? Colors.red : Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (willBeBanned) ...[
                      const SizedBox(height: 8),
                      Text(
                        'User wird automatisch für 24 Stunden gebannt!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade200,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Verwarnungen helfen, Regelverstöße zu dokumentieren. Bei 3 Verwarnungen erfolgt ein automatischer 24-Stunden-Ban.',
                        style: TextStyle(
                          color: Colors.blue.shade200,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Grund auswählen (PFLICHT)
              Row(
                children: [
                  const Text(
                    'Grund für Verwarnung',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PFLICHT',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Vordefinierte Gründe
              if (!_useCustomReason) ...[
                ...(_predefinedReasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedReason = reason;
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
                            ? Colors.orange.withValues(alpha: 0.2)
                            : const Color(0xFF252538),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedReason == reason
                              ? Colors.orange
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
                                ? Colors.orange
                                : Colors.white.withValues(alpha: 0.3),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            reason,
                            style: TextStyle(
                              color: _selectedReason == reason
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.7),
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
                  onChanged: (_) => setState(() {}),
                  maxLines: 3,
                  maxLength: 200,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Grund für Verwarnung eingeben... (Pflichtfeld)',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF252538),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange, width: 2),
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
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
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
                      onPressed: _canSubmit
                          ? () {
                              if (_finalReason != null) {
                                widget.onWarn(_finalReason!);
                                Navigator.pop(context);
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: willBeBanned ? Colors.red : Colors.orange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        willBeBanned ? 'Verwarnen & Bannen' : 'Verwarnen',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
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
