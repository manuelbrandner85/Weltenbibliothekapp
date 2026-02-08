import 'package:flutter/material.dart';
import '../models/community_post.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';
import '../utils/responsive_spacing.dart';

/// Responsive Post Card Widget für Community Posts
/// Automatische Anpassung an alle Bildschirmgrößen
class ResponsivePostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onMoreOptions;
  final Color? primaryColor;
  final Color? secondaryColor;
  
  const ResponsivePostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onMoreOptions,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final textStyles = context.textStyles;
    final primary = primaryColor ?? Colors.blue;
    final secondary = secondaryColor ?? Colors.purple;
    
    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacingMd),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(responsive.borderRadiusLg),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: responsive.borderRadiusXs / 8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: responsive.spacingXs,
            offset: Offset(0, responsive.spacingXs / 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Avatar und Username
          _buildHeader(context, responsive, textStyles, primary, secondary),
          
          // Content
          _buildContent(context, responsive, textStyles),
          
          context.vSpaceSm,
          
          // Tags
          if (post.tags.isNotEmpty) ...[
            _buildTags(context, responsive, textStyles),
            context.vSpaceSm,
          ],
          
          // Image-Placeholder (wenn hasImage true)
          if (post.hasImage == true) ...[
            _buildImagePlaceholder(context, responsive, primary, secondary),
            context.vSpaceMd,
          ],
          
          // Engagement Stats
          _buildEngagementStats(context, responsive, textStyles),
          
          context.vSpaceMd,
          
          // Action-Buttons
          _buildActionButtons(context, responsive, textStyles),
        ],
      ),
    );
  }
  
  Widget _buildHeader(
    BuildContext context,
    ResponsiveUtils responsive,
    ResponsiveTextStyles textStyles,
    Color primary,
    Color secondary,
  ) {
    return Padding(
      padding: context.paddingMd,
      child: Row(
        children: [
          // Avatar
          Container(
            width: responsive.iconSize3Xl,
            height: responsive.iconSize3Xl,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  secondary,
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: responsive.borderRadiusXs / 4,
              ),
            ),
            child: Center(
              child: Text(
                post.authorAvatar ?? '👤',
                style: textStyles.headlineMedium,
              ),
            ),
          ),
          
          context.hSpaceSm,
          
          // Username und Zeit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.authorUsername,
                  style: textStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatTimestamp(post.createdAt),
                  style: textStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          
          // More-Button
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: Colors.white.withValues(alpha: 0.7),
              size: responsive.iconSizeMd,
            ),
            onPressed: onMoreOptions ?? () {},
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(
    BuildContext context,
    ResponsiveUtils responsive,
    ResponsiveTextStyles textStyles,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.spacingMd),
      child: Text(
        post.content,
        style: textStyles.bodyMedium.copyWith(
          color: Colors.white,
          height: 1.5,
        ),
      ),
    );
  }
  
  Widget _buildTags(
    BuildContext context,
    ResponsiveUtils responsive,
    ResponsiveTextStyles textStyles,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.spacingMd),
      child: Wrap(
        spacing: responsive.spacingXs,
        runSpacing: responsive.spacingXs,
        children: post.tags
            .map((tag) => _buildPostTag(tag, responsive, textStyles))
            .toList(),
      ),
    );
  }
  
  Widget _buildPostTag(
    String tag,
    ResponsiveUtils responsive,
    ResponsiveTextStyles textStyles,
  ) {
    // Farbe basierend auf Tag
    Color tagColor = Colors.blue;
    if (tag.contains('Geopolitik')) {
      tagColor = Colors.green;
    } else if (tag.contains('Geschichte') || tag.contains('Dokumente')) {
      tagColor = Colors.orange;
    } else if (tag.contains('Machtstrukturen') || tag.contains('Recherche')) {
      tagColor = Colors.purple;
    } else if (tag.contains('Transparenz') || tag.contains('WikiLeaks')) {
      tagColor = Colors.yellow;
    } else if (tag.contains('CERN') || tag.contains('Physik')) {
      tagColor = Colors.cyan;
    } else if (tag.contains('Meditation') || tag.contains('Energie')) {
      tagColor = Colors.pink;
    } else if (tag.contains('Chakra') || tag.contains('Heilung')) {
      tagColor = Colors.teal;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacingXs,
        vertical: responsive.spacingXs / 2,
      ),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(responsive.borderRadiusSm),
        border: Border.all(
          color: tagColor.withValues(alpha: 0.5),
          width: responsive.borderRadiusXs / 8,
        ),
      ),
      child: Text(
        '#$tag',
        style: textStyles.labelSmall.copyWith(
          color: tagColor.withValues(alpha: 0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildImagePlaceholder(
    BuildContext context,
    ResponsiveUtils responsive,
    Color primary,
    Color secondary,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: responsive.spacingMd),
      height: responsive.heightPercent(0.25), // 25% of screen height
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.3),
            secondary.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(responsive.borderRadiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: responsive.borderRadiusXs / 8,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: responsive.iconSize3Xl,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
  
  Widget _buildEngagementStats(
    BuildContext context,
    ResponsiveUtils responsive,
    ResponsiveTextStyles textStyles,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.spacingMd),
      child: Row(
        children: [
          _buildEngagementStat(
            Icons.favorite_border,
            post.likes,
            Colors.red,
            responsive,
            textStyles,
          ),
          SizedBox(width: responsive.spacingSm),
          _buildEngagementStat(
            Icons.comment_outlined,
            post.comments,
            Colors.blue,
            responsive,
            textStyles,
          ),
          SizedBox(width: responsive.spacingSm),
          _buildEngagementStat(
            Icons.share_outlined,
            post.shares ?? 0,
            Colors.green,
            responsive,
            textStyles,
          ),
        ],
      ),
    );
  }
  
  Widget _buildEngagementStat(
    IconData icon,
    int count,
    Color color,
    ResponsiveUtils responsive,
    ResponsiveTextStyles textStyles,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: responsive.iconSizeSm,
          color: color.withValues(alpha: 0.7),
        ),
        SizedBox(width: responsive.spacingXs / 2),
        Text(
          count.toString(),
          style: textStyles.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons(
    BuildContext context,
    ResponsiveUtils responsive,
    ResponsiveTextStyles textStyles,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: responsive.borderRadiusXs / 8,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: responsive.spacingXs,
        horizontal: responsive.spacingMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            Icons.favorite_border,
            'Like',
            Colors.red,
            onLike ?? () {},
            responsive,
            textStyles,
          ),
          _buildActionButton(
            Icons.comment_outlined,
            'Kommentieren',
            Colors.blue,
            onComment ?? () {},
            responsive,
            textStyles,
          ),
          _buildActionButton(
            Icons.share_outlined,
            'Teilen',
            Colors.green,
            onShare ?? () {},
            responsive,
            textStyles,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
    ResponsiveUtils responsive,
    ResponsiveTextStyles textStyles,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(responsive.borderRadiusSm),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacingXs,
          vertical: responsive.spacingXs / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: responsive.iconSizeSm,
              color: color.withValues(alpha: 0.8),
            ),
            SizedBox(width: responsive.spacingXs / 2),
            Text(
              label,
              style: textStyles.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Gerade eben';
    } else if (difference.inMinutes < 60) {
      return 'vor ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'vor ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays}d';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }
}
