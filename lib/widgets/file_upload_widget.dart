import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

/// File Upload Widget
/// Unterstützt: PDF, Images, Audio, Video
class FileUploadWidget extends StatefulWidget {
  final Function(File file, String fileType) onFileSelected;
  final VoidCallback onCancel;
  
  const FileUploadWidget({
    super.key,
    required this.onFileSelected,
    required this.onCancel,
  });
  
  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  bool _isUploading = false;
  
  Future<void> _pickFile(String type) async {
    try {
      FilePickerResult? result;
      
      switch (type) {
        case 'image':
          result = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: false,
          );
          break;
        case 'video':
          result = await FilePicker.platform.pickFiles(
            type: FileType.video,
            allowMultiple: false,
          );
          break;
        case 'audio':
          result = await FilePicker.platform.pickFiles(
            type: FileType.audio,
            allowMultiple: false,
          );
          break;
        case 'pdf':
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            allowMultiple: false,
          );
          break;
        default:
          result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: false,
          );
      }
      
      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);
        
        // Check file size (max 10MB)
        final fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Datei zu groß (max 10 MB)'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        setState(() => _isUploading = true);
        
        // Simulate upload delay
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          widget.onFileSelected(file, type);
          Navigator.pop(context);
        }
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
        setState(() => _isUploading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          const Text(
            'Datei hochladen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          if (_isUploading)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Upload läuft...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            )
          else
            Column(
              children: [
                // Image Button
                _buildFileTypeButton(
                  icon: Icons.image,
                  label: 'Bild',
                  color: Colors.green,
                  onTap: () => _pickFile('image'),
                ),
                const SizedBox(height: 12),
                
                // Video Button
                _buildFileTypeButton(
                  icon: Icons.video_library,
                  label: 'Video',
                  color: Colors.pink,
                  onTap: () => _pickFile('video'),
                ),
                const SizedBox(height: 12),
                
                // Audio Button
                _buildFileTypeButton(
                  icon: Icons.audiotrack,
                  label: 'Audio',
                  color: Colors.blue,
                  onTap: () => _pickFile('audio'),
                ),
                const SizedBox(height: 12),
                
                // PDF Button
                _buildFileTypeButton(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  color: Colors.red,
                  onTap: () => _pickFile('pdf'),
                ),
                const SizedBox(height: 20),
                
                // Cancel Button
                TextButton(
                  onPressed: () {
                    widget.onCancel();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Abbrechen',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildFileTypeButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Max 10 MB',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// File Preview Widget
class FilePreviewWidget extends StatelessWidget {
  final File file;
  final String fileType;
  final VoidCallback onRemove;
  
  const FilePreviewWidget({
    super.key,
    required this.file,
    required this.fileType,
    required this.onRemove,
  });
  
  IconData _getIcon() {
    switch (fileType) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_library;
      case 'audio':
        return Icons.audiotrack;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  Color _getColor() {
    switch (fileType) {
      case 'image':
        return Colors.green;
      case 'video':
        return Colors.pink;
      case 'audio':
        return Colors.blue;
      case 'pdf':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getFileName() {
    return file.path.split('/').last;
  }
  
  String _getFileSize() {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getColor().withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getIcon(), color: _getColor(), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFileName(),
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
                  _getFileSize(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: onRemove,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
