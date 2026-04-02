import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Social Media Share Widget v8.0
/// 
/// Social Media Integration für Recherche-Sharing
class SocialMediaShareWidget extends StatelessWidget {
  final String query;
  final String url;

  const SocialMediaShareWidget({
    super.key,
    required this.query,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.share, color: Colors.cyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Social Media',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Social Media Buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSocialButton(
                context,
                icon: '𝕏',  // Twitter/X Icon
                label: 'Twitter',
                color: Colors.black,
                onTap: () => _shareToTwitter(),
              ),
              _buildSocialButton(
                context,
                icon: '🚀',
                label: 'Reddit',
                color: const Color(0xFFFF4500),
                onTap: () => _shareToReddit(),
              ),
              _buildSocialButton(
                context,
                icon: '✈️',
                label: 'Telegram',
                color: const Color(0xFF0088CC),
                onTap: () => _shareToTelegram(),
              ),
              _buildSocialButton(
                context,
                icon: '💬',
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => _shareToWhatsApp(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required String icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: TextStyle(fontSize: 18, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Twitter/X Share
  void _shareToTwitter() async {
    final text = Uri.encodeComponent('Interessante Recherche: $query\n\n$url\n\n#Weltenbibliothek #AlternativeMedien');
    final uri = Uri.parse('https://twitter.com/intent/tweet?text=$text');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Reddit Share
  void _shareToReddit() async {
    final title = Uri.encodeComponent('Recherche: $query');
    final urlEncoded = Uri.encodeComponent(url);
    final uri = Uri.parse('https://www.reddit.com/submit?title=$title&url=$urlEncoded');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Telegram Share
  void _shareToTelegram() async {
    final text = Uri.encodeComponent('Interessante Recherche: $query\n\n$url');
    final uri = Uri.parse('https://t.me/share/url?url=$url&text=$text');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // WhatsApp Share
  void _shareToWhatsApp() async {
    final text = Uri.encodeComponent('Interessante Recherche: $query\n\n$url');
    final uri = Uri.parse('https://wa.me/?text=$text');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Embed Code Generator Widget v8.0
/// 
/// Erstellt Embed-Code für Websites
class EmbedCodeWidget extends StatelessWidget {
  final String url;
  final String title;

  const EmbedCodeWidget({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final embedCode = '''
<iframe 
  src="$url" 
  width="100%" 
  height="600" 
  frameborder="0" 
  style="border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);"
  title="$title"
  allowfullscreen>
</iframe>
''';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Embed-Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Binde diese Recherche in deine Website ein:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Code Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: SelectableText(
              embedCode,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 11,
                color: Colors.greenAccent,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Copy Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: embedCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('✅ Embed-Code kopiert'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Code kopieren'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
