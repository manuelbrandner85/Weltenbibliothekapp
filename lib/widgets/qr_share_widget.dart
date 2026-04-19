import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// QR Code Share Widget
class QRShareWidget extends StatelessWidget {
  final String url;
  final String title;

  const QRShareWidget({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Teilen via QR-Code',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
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
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            title,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Share Button
              ElevatedButton.icon(
                onPressed: () => _shareUrl(context),
                icon: const Icon(Icons.share),
                label: const Text('Teilen'),
              ),
              
              // Close Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Schließen'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareUrl(BuildContext context) async {
    try {
      await Share.share(
        '$title\n\n$url',
        subject: title,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Teilen: $e')),
        );
      }
    }
  }

  static void show(BuildContext context, {required String url, required String title}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => QRShareWidget(url: url, title: title),
    );
  }
}

/// Share Button Widget
class ShareButton extends StatelessWidget {
  final String url;
  final String title;

  const ShareButton({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.share),
      onSelected: (value) {
        if (value == 'qr') {
          QRShareWidget.show(context, url: url, title: title);
        } else if (value == 'link') {
          Share.share('$title\n\n$url', subject: title);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'qr',
          child: Row(
            children: [
              Icon(Icons.qr_code),
              SizedBox(width: 8),
              Text('QR-Code'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'link',
          child: Row(
            children: [
              Icon(Icons.link),
              SizedBox(width: 8),
              Text('Link teilen'),
            ],
          ),
        ),
      ],
    );
  }
}
