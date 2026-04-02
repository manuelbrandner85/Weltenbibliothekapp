/// 📁 File Upload Button Widget
/// Compact button for file uploads in chat
library;

import 'package:flutter/material.dart';
import '../services/file_upload_service.dart';
import 'package:file_picker/file_picker.dart';

class FileUploadButton extends StatefulWidget {
  final Function(String url, String filename, int size) onFileUploaded;
  final Color color;

  const FileUploadButton({
    super.key,
    required this.onFileUploaded,
    this.color = Colors.blue,
  });

  @override
  State<FileUploadButton> createState() => _FileUploadButtonState();
}

class _FileUploadButtonState extends State<FileUploadButton> {
  final FileUploadService _uploadService = FileUploadService();
  bool _isUploading = false;

  Future<void> _handleFilePick() async {
    try {
      // Pick file
      final file = await _uploadService.pickFile(
        type: FileType.any,
      );

      if (file == null) return;

      setState(() => _isUploading = true);

      // Upload file
      final url = await _uploadService.uploadFile(
        file: file,
        folder: 'chat-files',
      );

      if (url != null && mounted) {
        widget.onFileUploaded(url, file.name, file.size);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Datei hochgeladen: ${file.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Upload fehlgeschlagen'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }

      setState(() => _isUploading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isUploading ? null : _handleFilePick,
      icon: _isUploading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(widget.color),
              ),
            )
          : Icon(Icons.attach_file, color: widget.color),
      tooltip: 'Datei anhängen',
    );
  }
}

/// 📎 File Attachment Display Widget
class FileAttachmentWidget extends StatelessWidget {
  final String url;
  final String filename;
  final int size;
  final VoidCallback? onRemove;

  const FileAttachmentWidget({
    super.key,
    required this.url,
    required this.filename,
    required this.size,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = FileUploadService.isImageFile(filename);
    final isDocument = FileUploadService.isDocumentFile(filename);
    final isVideo = FileUploadService.isVideoFile(filename);

    IconData icon;
    Color iconColor;

    if (isImage) {
      icon = Icons.image;
      iconColor = Colors.blue;
    } else if (isDocument) {
      icon = Icons.description;
      iconColor = Colors.red;
    } else if (isVideo) {
      icon = Icons.video_library;
      iconColor = Colors.purple;
    } else {
      icon = Icons.insert_drive_file;
      iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  FileUploadService.formatFileSize(size),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              tooltip: 'Entfernen',
            ),
        ],
      ),
    );
  }
}
