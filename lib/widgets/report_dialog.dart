import 'package:flutter/material.dart';
import '../services/moderation_service.dart';

class ReportDialog extends StatefulWidget {
  final int? reportedUserId;
  final String? reportedUsername;
  final String reportType; // 'user', 'message', 'room', 'profile'
  final int? referenceId;
  final Map<String, dynamic>? referenceData;

  const ReportDialog({
    super.key,
    this.reportedUserId,
    this.reportedUsername,
    required this.reportType,
    this.referenceId,
    this.referenceData,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ModerationService _moderationService = ModerationService();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedReason = 'spam';
  bool _isSubmitting = false;

  final Map<String, String> _reasonLabels = {
    'spam': '🚫 Spam',
    'harassment': '⚠️ Belästigung',
    'inappropriate': '🔞 Unangemessener Inhalt',
    'violence': '⚔️ Gewalt/Drohungen',
    'other': '📝 Sonstiges',
  };

  Future<void> _submitReport() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _moderationService.createReport(
        reportType: widget.reportType,
        reason: _selectedReason,
        reportedUserId: widget.reportedUserId,
        description: _descriptionController.text.trim(),
        referenceId: widget.referenceId,
        referenceData: widget.referenceData,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Meldung erfolgreich eingereicht'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Fehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.flag, color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Inhalt melden',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reported user info
              if (widget.reportedUsername != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Gemeldet: ${widget.reportedUsername}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Reason selection
              const Text(
                'Grund der Meldung:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              ..._reasonLabels.entries.map((entry) {
                return RadioListTile<String>(
                  title: Text(entry.value),
                  value: entry.key,
                  groupValue: _selectedReason,
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedReason = value!;
                          });
                        },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }),

              const SizedBox(height: 16),

              // Description
              const Text(
                'Zusätzliche Informationen (optional):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 500,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: 'Beschreibe das Problem...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Abbrechen'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Melden'),
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

/// Helper function to show report dialog
Future<bool?> showReportDialog(
  BuildContext context, {
  int? reportedUserId,
  String? reportedUsername,
  required String reportType,
  int? referenceId,
  Map<String, dynamic>? referenceData,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ReportDialog(
      reportedUserId: reportedUserId,
      reportedUsername: reportedUsername,
      reportType: reportType,
      referenceId: referenceId,
      referenceData: referenceData,
    ),
  );
}
