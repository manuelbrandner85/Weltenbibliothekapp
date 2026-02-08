import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/community_interaction_service.dart';

/// Enhanced Share Dialog
/// Multi-platform sharing with QR code and deep links
class ShareDialog extends StatelessWidget {
  final String postId;
  final String postTitle;
  final String postContent;
  final String userId;

  const ShareDialog({
    super.key,
    required this.postId,
    required this.postTitle,
    required this.postContent,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final deepLink = _generateDeepLink();
    final shareText = _generateShareText();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.share, color: Colors.cyan, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Teilen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // QR Code Section
                  _buildQRCodeSection(deepLink, context),
                  
                  const SizedBox(height: 24),
                  
                  // Link Section
                  _buildLinkSection(deepLink, context),
                  
                  const SizedBox(height: 24),
                  
                  // Share Platforms
                  _buildSharePlatforms(shareText, deepLink, context),
                  
                  const SizedBox(height: 24),
                  
                  // Generic Share Button
                  _buildGenericShareButton(shareText, context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection(String deepLink, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyan.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '📱 QR-Code scannen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
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
              data: deepLink,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
          
          const SizedBox(height: 12),
          Text(
            'Scanne mit deiner Kamera',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkSection(String deepLink, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade800,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔗 Direkter Link',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // Link Display + Copy Button
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    deepLink,
                    style: TextStyle(
                      color: Colors.cyan.shade300,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _copyToClipboard(deepLink, context),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Kopieren'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSharePlatforms(String shareText, String deepLink, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📲 Plattformen',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Platform Grid
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildPlatformButton(
              icon: '💬',
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              onTap: () => _shareToWhatsApp(shareText, deepLink, context),
            ),
            _buildPlatformButton(
              icon: '✈️',
              label: 'Telegram',
              color: const Color(0xFF0088CC),
              onTap: () => _shareToTelegram(shareText, deepLink, context),
            ),
            _buildPlatformButton(
              icon: '🐦',
              label: 'Twitter',
              color: const Color(0xFF1DA1F2),
              onTap: () => _shareToTwitter(shareText, deepLink, context),
            ),
            _buildPlatformButton(
              icon: '📧',
              label: 'E-Mail',
              color: Colors.red.shade600,
              onTap: () => _shareViaEmail(shareText, deepLink, context),
            ),
            _buildPlatformButton(
              icon: '💬',
              label: 'SMS',
              color: Colors.green.shade600,
              onTap: () => _shareViaSMS(shareText, deepLink, context),
            ),
            _buildPlatformButton(
              icon: '📱',
              label: 'Mehr',
              color: Colors.grey.shade700,
              onTap: () => _genericShare(shareText, context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlatformButton({
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericShareButton(String shareText, BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _genericShare(shareText, context),
      icon: const Icon(Icons.share),
      label: const Text('Über System teilen'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ============================================
  // SHARE METHODS
  // ============================================

  String _generateDeepLink() {
    // Deep link format: weltenbibliothek://post/{postId}
    return 'https://weltenbibliothek.app/post/$postId';
  }

  String _generateShareText() {
    return '📖 $postTitle\n\n${_truncateText(postContent, 100)}\n\nLies mehr in der Weltenbibliothek App! 🌟';
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Future<void> _copyToClipboard(String text, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Link kopiert!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Track share
    await CommunityInteractionService().trackShare(
      postId: postId,
      userId: userId,
      platform: 'clipboard',
    );
  }

  Future<void> _shareToWhatsApp(String text, String link, BuildContext context) async {
    final message = '$text\n\n$link';
    // URL encode for WhatsApp
    final encoded = Uri.encodeComponent(message);
    final url = 'https://wa.me/?text=$encoded';
    
    try {
      await Share.shareUri(Uri.parse(url));
      
      // Track share
      await CommunityInteractionService().trackShare(
        postId: postId,
        userId: userId,
        platform: 'whatsapp',
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'WhatsApp nicht verfügbar');
      }
    }
  }

  Future<void> _shareToTelegram(String text, String link, BuildContext context) async {
    final message = '$text\n\n$link';
    final encoded = Uri.encodeComponent(message);
    final url = 'https://t.me/share/url?url=$encoded';
    
    try {
      await Share.shareUri(Uri.parse(url));
      
      await CommunityInteractionService().trackShare(
        postId: postId,
        userId: userId,
        platform: 'telegram',
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Telegram nicht verfügbar');
      }
    }
  }

  Future<void> _shareToTwitter(String text, String link, BuildContext context) async {
    final encoded = Uri.encodeComponent(text);
    final urlEncoded = Uri.encodeComponent(link);
    final url = 'https://twitter.com/intent/tweet?text=$encoded&url=$urlEncoded';
    
    try {
      await Share.shareUri(Uri.parse(url));
      
      await CommunityInteractionService().trackShare(
        postId: postId,
        userId: userId,
        platform: 'twitter',
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Twitter nicht verfügbar');
      }
    }
  }

  Future<void> _shareViaEmail(String text, String link, BuildContext context) async {
    final subject = Uri.encodeComponent(postTitle);
    final body = Uri.encodeComponent('$text\n\n$link');
    final url = 'mailto:?subject=$subject&body=$body';
    
    try {
      await Share.shareUri(Uri.parse(url));
      
      await CommunityInteractionService().trackShare(
        postId: postId,
        userId: userId,
        platform: 'email',
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'E-Mail nicht verfügbar');
      }
    }
  }

  Future<void> _shareViaSMS(String text, String link, BuildContext context) async {
    final message = Uri.encodeComponent('$text\n\n$link');
    final url = 'sms:?body=$message';
    
    try {
      await Share.shareUri(Uri.parse(url));
      
      await CommunityInteractionService().trackShare(
        postId: postId,
        userId: userId,
        platform: 'sms',
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'SMS nicht verfügbar');
      }
    }
  }

  Future<void> _genericShare(String text, BuildContext context) async {
    try {
      await Share.share(
        '$text\n\n${_generateDeepLink()}',
        subject: postTitle,
      );
      
      await CommunityInteractionService().trackShare(
        postId: postId,
        userId: userId,
        platform: 'system',
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Teilen fehlgeschlagen');
      }
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }
}
