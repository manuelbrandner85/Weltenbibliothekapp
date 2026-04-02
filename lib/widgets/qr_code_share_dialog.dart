import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// QR Code Share Dialog v8.0
/// 
/// Zeigt QR-Code für Recherche-Links
class QrCodeShareDialog extends StatelessWidget {
  final String url;
  final String title;

  const QrCodeShareDialog({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.qr_code, color: Colors.cyan, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'QR-Code teilen',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
                errorStateBuilder: (context, error) {
                  return Container(
                    width: 250,
                    height: 250,
                    alignment: Alignment.center,
                    child: const Text(
                      'QR-Code konnte nicht erstellt werden',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 20),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Link kopiert'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Link kopieren'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.cyan,
                      side: const BorderSide(color: Colors.cyan),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Share.share(
                        'Schau dir diese Recherche an: $title\n\n$url',
                        subject: title,
                      );
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Teilen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
