/// Data Export/Import Widget
/// UI for backing up and restoring data
library;

import 'package:flutter/material.dart';
import '../services/export_import_service.dart';

class ExportImportWidget extends StatefulWidget {
  final Color accentColor;

  const ExportImportWidget({
    super.key,
    this.accentColor = const Color(0xFF9C27B0),
  });

  @override
  State<ExportImportWidget> createState() => _ExportImportWidgetState();
}

class _ExportImportWidgetState extends State<ExportImportWidget> {
  final ExportImportService _exportImportService = ExportImportService();
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF0F0F1E),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.save_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Daten Export & Import',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Export Section
          _buildSection(
            title: 'Daten exportieren',
            subtitle: 'Sichere alle deine Journal-Einträge, Synchronizitäten und Einstellungen',
            icon: Icons.file_download,
            buttonText: 'JSON-Datei herunterladen',
            buttonIcon: Icons.download,
            onPressed: _isExporting ? null : _handleExport,
            isLoading: _isExporting,
          ),

          const Divider(color: Colors.white12, height: 32),

          // Import Section
          _buildSection(
            title: 'Daten importieren',
            subtitle: 'Stelle deine Daten aus einem Backup wieder her',
            icon: Icons.file_upload,
            buttonText: 'JSON-Datei auswählen',
            buttonIcon: Icons.upload,
            onPressed: _isImporting ? null : _handleImport,
            isLoading: _isImporting,
            buttonColor: Colors.orange,
          ),

          const SizedBox(height: 16),

          // Warning
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Import überschreibt keine bestehenden Daten, sondern fügt neue hinzu.',
                    style: TextStyle(
                      color: Colors.orange.shade200,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required String buttonText,
    required IconData buttonIcon,
    required VoidCallback? onPressed,
    required bool isLoading,
    Color? buttonColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: widget.accentColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        buttonColor ?? widget.accentColor,
                      ),
                    ),
                  )
                : Icon(buttonIcon),
            label: Text(isLoading ? 'Verarbeite...' : buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: (buttonColor ?? widget.accentColor).withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              disabledBackgroundColor: Colors.grey.withValues(alpha: 0.1),
              disabledForegroundColor: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      await _exportImportService.downloadExportFile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Export erfolgreich! Datei wird heruntergeladen...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Export fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _handleImport() async {
    setState(() {
      _isImporting = true;
    });

    try {
      final result = await _exportImportService.importFromFile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? '✅ ${result.message}'
                  : '❌ ${result.message}',
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Import fehlgeschlagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }
}
