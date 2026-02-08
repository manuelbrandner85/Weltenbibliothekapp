import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_styles.dart';

/// Mention Auto-Complete Widget für Chat Input
class MentionAutoComplete extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSelectUser;
  final Color accentColor;
  
  const MentionAutoComplete({
    super.key,
    required this.suggestions,
    required this.onSelectUser,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final utils = ResponsiveUtils.of(context);
    final textStyles = ResponsiveTextStyles.of(context);
    
    if (suggestions.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(bottom: utils.spacingXs),
      constraints: BoxConstraints(maxHeight: utils.spacingXl * 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(utils.borderRadiusMd),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: utils.spacingMd * 0.75,
            offset: Offset(0, -utils.spacingXs / 2),
          ),
        ],
      ),
      child: ListView.separated(
        padding: EdgeInsets.all(utils.spacingXs),
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.white.withValues(alpha: 0.1),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final username = suggestions[index];
          return ListTile(
            dense: true,
            leading: Container(
              width: utils.iconSizeLg,
              height: utils.iconSizeLg,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.7),
                    accentColor.withValues(alpha: 0.3),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(Icons.person, color: Colors.white, size: utils.iconSizeMd),
              ),
            ),
            title: Text(
              '@$username',
              style: textStyles.bodyMedium.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Erwähnen',
              style: textStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            onTap: () => onSelectUser(username),
          );
        },
      ),
    );
  }
}
