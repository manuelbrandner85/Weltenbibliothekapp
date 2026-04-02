import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Telegram Channels Widget v7.4
/// 
/// Zeigt Telegram-Kanäle mit direkten Links
class TelegramChannelsWidget extends StatelessWidget {
  final List<dynamic> channels;
  final String query;

  const TelegramChannelsWidget({
    super.key,
    required this.channels,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.telegram,
                    color: Colors.cyan,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📱 Telegram Kanäle',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Alternative Quellen & Leaks',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.grey, height: 1),

          // Channel List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: channels.length > 10 ? 10 : channels.length,
            separatorBuilder: (context, index) => const Divider(
              color: Colors.grey,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final channel = channels[index];
              return _buildChannelTile(context, channel);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChannelTile(BuildContext context, dynamic channel) {
    final name = channel['name'] ?? 'Unknown Channel';
    final handle = channel['handle'] ?? '';
    final type = channel['type'] ?? 'general';
    final description = channel['description'] ?? '';
    final link = channel['link'] ?? 'https://t.me/$handle';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getTypeColor(type).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _getTypeIcon(type),
          color: _getTypeColor(type),
          size: 24,
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBadge(type, _getTypeColor(type)),
              const SizedBox(width: 8),
              Text(
                '@$handle',
                style: TextStyle(
                  color: Colors.cyan.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.open_in_new, color: Colors.cyan),
        onPressed: () => _openTelegramChannel(link),
      ),
      onTap: () => _openTelegramChannel(link),
    );
  }

  Widget _buildBadge(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        _getTypeLabel(type),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _openTelegramChannel(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'archive':
        return Icons.folder;
      case 'research':
        return Icons.science;
      case 'news':
        return Icons.newspaper;
      case 'leaks':
        return Icons.lock_open;
      case 'investigation':
        return Icons.search;
      case 'documentary':
        return Icons.movie;
      case 'activism':
        return Icons.campaign;
      default:
        return Icons.telegram;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'archive':
        return Colors.amber;
      case 'research':
        return Colors.blue;
      case 'news':
        return Colors.red;
      case 'leaks':
        return Colors.orange;
      case 'investigation':
        return Colors.purple;
      case 'documentary':
        return Colors.green;
      case 'activism':
        return Colors.pink;
      default:
        return Colors.cyan;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'archive':
        return '📁 Archiv';
      case 'research':
        return '🔍 Forschung';
      case 'news':
        return '📰 News';
      case 'leaks':
        return '🔓 Leaks';
      case 'investigation':
        return '🕵️ Investigation';
      case 'documentary':
        return '🎬 Doku';
      case 'activism':
        return '📢 Aktivismus';
      default:
        return '📱 Kanal';
    }
  }
}
