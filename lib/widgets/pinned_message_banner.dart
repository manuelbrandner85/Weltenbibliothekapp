import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/cloudflare_api_service.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';

/// 📌 PINNED MESSAGE BANNER
/// Zeigt gepinnte Nachricht über dem Chat an
class PinnedMessageBanner extends StatefulWidget {
  final String room;
  final Color worldColor;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;
  
  const PinnedMessageBanner({
    super.key,
    required this.room,
    this.worldColor = Colors.purple,
    this.onTap,
    this.onRefresh,
  });

  @override
  State<PinnedMessageBanner> createState() => _PinnedMessageBannerState();
}

class _PinnedMessageBannerState extends State<PinnedMessageBanner> {
  final CloudflareApiService _api = CloudflareApiService();
  Map<String, dynamic>? _pinnedMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPinnedMessage();
  }

  Future<void> _loadPinnedMessage() async {
    try {
      final pinned = await _api.getPinnedMessage(widget.room);
      if (mounted) {
        setState(() {
          _pinnedMessage = pinned;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Load pinned message error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unpinMessage() async {
    try {
      await _api.unpinMessage(widget.room);
      if (mounted) {
        setState(() => _pinnedMessage = null);
        widget.onRefresh?.call();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Unpin message error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final utils = ResponsiveUtils.of(context);
    final textStyles = ResponsiveTextStyles.of(context);
    
    if (_isLoading) {
      return const SizedBox.shrink();
    }
    
    if (_pinnedMessage == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: utils.spacingMd, 
        vertical: utils.spacingMd * 0.75,
      ),
      decoration: BoxDecoration(
        color: widget.worldColor.withValues(alpha: 0.2),
        border: Border(
          bottom: BorderSide(
            color: widget.worldColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.push_pin, color: widget.worldColor, size: utils.iconSizeMd),
          SizedBox(width: utils.spacingMd * 0.75),
          
          Expanded(
            child: GestureDetector(
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_pinnedMessage!['username'] ?? 'Unbekannt'}',
                    style: textStyles.bodySmall.copyWith(
                      color: widget.worldColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _pinnedMessage!['message'] ?? '',
                    style: textStyles.bodyMedium.copyWith(
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            iconSize: utils.iconSizeMd,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: _unpinMessage,
          ),
        ],
      ),
    );
  }
}
