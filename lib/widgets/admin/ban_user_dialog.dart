/// BAN USER DIALOG
/// Vollständiger Dialog zum Bannen von Usern (Permanent oder Temporär)
/// 
/// Features:
/// - Dauer-Auswahl (5min, 30min, 1h, 24h, Permanent)
/// - Grund-Eingabe (Vordefiniert + Custom)
/// - Warnung bei permanentem Ban
/// - Confirmation
library;

import 'package:flutter/material.dart';
import '../../models/admin_action.dart';

class BanUserDialog extends StatefulWidget {
  final String username;
  final String userId;
  final Function(BanDuration duration, String? reason) onBan;
  
  const BanUserDialog({
    super.key,
    required this.username,
    required this.userId,
    required this.onBan,
  });

  @override
  State<BanUserDialog> createState() => _BanUserDialogState();
}

class _BanUserDialogState extends State<BanUserDialog> {
  BanDuration _selectedDuration = BanDuration.oneDay;
  String? _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  bool _useCustomReason = false;
  
  final List<String> _predefinedReasons = [
    'Wiederholte Regelverstöße',
    'Spam',
    'Beleidigung anderer User',
    'Unangemessene Inhalte',
    'Trolling',
    'Drohungen',
  ];
  
  final Map<BanDuration, Map<String, dynamic>> _durationInfo = {
    BanDuration.fiveMinutes: {
      'label': '5 Minuten',
      'icon': Icons.timer,
      'color': Colors.orange,
      'description': 'Kurze Abkühlung',
    },
    BanDuration.thirtyMinutes: {
      'label': '30 Minuten',
      'icon': Icons.timer,
      'color': Colors.orange,
      'description': 'Mittlere Auszeit',
    },
    BanDuration.oneHour: {
      'label': '1 Stunde',
      'icon': Icons.access_time,
      'color': Colors.deepOrange,
      'description': 'Längere Auszeit',
    },
    BanDuration.oneDay: {
      'label': '24 Stunden',
      'icon': Icons.today,
      'color': Colors.red,
      'description': 'Tages-Ban',
    },
    BanDuration.permanent: {
      'label': 'Permanent',
      'icon': Icons.block,
      'color': Colors.red.shade900,
      'description': 'Dauerhafter Ban',
    },
  };
  
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
    final durationInfo = _durationInfo[_selectedDuration]!;
    final isPermanent = _selectedDuration == BanDuration.permanent;
    
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
                      color: (durationInfo['color'] as Color).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      durationInfo['icon'] as IconData,
                      color: durationInfo['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User bannen',
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
              
              // Permanent Ban Warning
              if (isPermanent)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ACHTUNG: Permanenter Ban! Der User kann nicht mehr beitreten und keine Nachrichten mehr senden.',
                          style: TextStyle(
                            color: Colors.red.shade200,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
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
                          'Temporärer Ban: Der User kann nach Ablauf der Zeit automatisch wieder beitreten.',
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
              
              // Dauer auswählen
              const Text(
                'Ban-Dauer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Duration Options
              ...(_durationInfo.entries.map((entry) {
                final duration = entry.key;
                final info = entry.value;
                final isSelected = _selectedDuration == duration;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDuration = duration;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (info['color'] as Color).withValues(alpha: 0.2)
                            : const Color(0xFF252538),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? info['color'] as Color
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? info['color'] as Color
                                : Colors.white.withValues(alpha: 0.3),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            info['icon'] as IconData,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  info['label'] as String,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.7),
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  info['description'] as String,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              })),
              
              const SizedBox(height: 24),
              
              // Grund auswählen
              const Text(
                'Grund für Ban (Optional)',
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
                            ? Colors.red.withValues(alpha: 0.2)
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
                  maxLines: 3,
                  maxLength: 200,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Grund für Ban eingeben...',
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
                      onPressed: () {
                        widget.onBan(_selectedDuration, _finalReason);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: durationInfo['color'] as Color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isPermanent ? 'Permanent Bannen' : 'Bannen',
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
