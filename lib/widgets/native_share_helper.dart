import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Native Share Helper v8.0
/// 
/// Nutzt das native System Share Sheet optimal
class NativeShareHelper {
  /// Share Text with native dialog
  static Future<void> shareText({
    required String text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    await Share.share(
      text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
  
  /// Share with Files (for PDFs, Images, etc.)
  static Future<void> shareFiles({
    required List<XFile> files,
    String? text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    await Share.shareXFiles(
      files,
      text: text,
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
  
  /// Quick Share Research Result
  static Future<void> shareResearch({
    required String query,
    required String summary,
    List<String>? sources,
    BuildContext? context,
  }) async {
    final sourcesText = sources != null && sources.isNotEmpty
        ? '\n\n📚 Quellen:\n${sources.take(5).map((s) => '• $s').join('\n')}'
        : '';
    
    final text = '''
🔍 Weltenbibliothek Recherche

📋 Thema: $query

📄 Zusammenfassung:
$summary$sourcesText

🌐 Mehr auf: https://weltenbibliothek.app
    '''.trim();
    
    // Get share position for iPad
    Rect? sharePositionOrigin;
    if (context != null) {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
      }
    }
    
    await Share.share(
      text,
      subject: 'Recherche: $query',
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}

/// Quick Share FAB Widget v8.0
/// 
/// Floating Action Button für schnelles Teilen
class QuickShareFAB extends StatelessWidget {
  final String query;
  final String summary;
  final List<String>? sources;
  final VoidCallback? onPressed;

  const QuickShareFAB({
    super.key,
    required this.query,
    required this.summary,
    this.sources,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        if (onPressed != null) {
          onPressed!();
        } else {
          await NativeShareHelper.shareResearch(
            query: query,
            summary: summary,
            sources: sources,
            context: context,
          );
        }
      },
      backgroundColor: Colors.cyan,
      foregroundColor: Colors.black,
      tooltip: 'Schnell teilen',
      child: const Icon(Icons.share),
    );
  }
}

/// Enhanced Share Button Widget v8.0
/// 
/// Button mit nativer Share-Integration
class EnhancedShareButton extends StatelessWidget {
  final String query;
  final String summary;
  final List<String>? sources;
  final bool isCompact;

  const EnhancedShareButton({
    super.key,
    required this.query,
    required this.summary,
    this.sources,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return IconButton(
        icon: const Icon(Icons.ios_share),
        tooltip: 'Teilen',
        onPressed: () => _share(context),
      );
    }
    
    return ElevatedButton.icon(
      onPressed: () => _share(context),
      icon: const Icon(Icons.ios_share, size: 18),
      label: const Text('Teilen'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
  
  Future<void> _share(BuildContext context) async {
    await NativeShareHelper.shareResearch(
      query: query,
      summary: summary,
      sources: sources,
      context: context,
    );
  }
}
