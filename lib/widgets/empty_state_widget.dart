import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Wiederverwendbares Empty State Widget
/// 
/// VERWENDUNG:
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.search,
///   title: 'Keine Ergebnisse',
///   message: 'Versuche eine andere Suche',
///   actionLabel: 'Neue Suche',
///   onAction: () => ...,
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<String>? suggestions;
  final Color? iconColor;
  
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.suggestions,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon mit Animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: AppDurations.slow,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (iconColor ?? AppColors.textTertiary).withValues(alpha: 0.1),
                ),
                child: Icon(
                  icon,
                  size: AppIconSize.xxl,
                  color: iconColor ?? AppColors.textTertiary,
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Titel
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Nachricht
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Action Button (optional)
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(actionLabel!),
                style: AppButtonStyles.primary,
              ),
            ],
            
            // Suggestions (optional)
            if (suggestions != null && suggestions!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Vorschläge:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: suggestions!.map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    onPressed: onAction != null 
                      ? () {
                          // Pass suggestion to action callback
                          onAction!();
                        }
                      : null,
                    backgroundColor: AppColors.backgroundLight,
                    labelStyle: const TextStyle(
                      color: AppColors.textPrimary,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Vordefinierte Empty States für häufige Szenarien
class EmptyStates {
  EmptyStates._();
  
  /// Kein Wissen/Artikel gefunden
  static Widget noKnowledge(VoidCallback? onSearch) => EmptyStateWidget(
    icon: Icons.auto_stories_outlined,
    iconColor: AppColors.energiePurple,
    title: 'Noch kein Wissen',
    message: 'Starte deine erste Recherche und entdecke\ndie Geheimnisse der Welt!',
    actionLabel: 'Recherche starten',
    onAction: onSearch,
    suggestions: const [
      'WikiLeaks CIA',
      'MK-ULTRA',
      'Area 51',
      'Verschwörungen',
    ],
  );
  
  /// Keine Suchergebnisse
  static Widget noSearchResults(String query) => EmptyStateWidget(
    icon: Icons.search_off,
    iconColor: AppColors.warning,
    title: 'Keine Ergebnisse',
    message: 'Für "$query" wurden keine Ergebnisse gefunden.\nVersuche andere Suchbegriffe.',
    actionLabel: 'Neue Suche',
    onAction: null,
  );
  
  /// Keine Bookmarks
  static Widget noBookmarks(VoidCallback? onBrowse) => EmptyStateWidget(
    icon: Icons.bookmark_border,
    iconColor: AppColors.materieBlue,
    title: 'Keine Lesezeichen',
    message: 'Markiere interessante Artikel und\nfinde sie hier wieder.',
    actionLabel: 'Artikel durchsuchen',
    onAction: onBrowse,
  );
  
  /// Kein Netzwerk
  static Widget noNetwork(VoidCallback? onRetry) => EmptyStateWidget(
    icon: Icons.wifi_off,
    iconColor: AppColors.error,
    title: 'Keine Verbindung',
    message: 'Bitte prüfe deine Internetverbindung\nund versuche es erneut.',
    actionLabel: 'Erneut versuchen',
    onAction: onRetry,
  );
  
  /// Keine Community-Posts
  static Widget noPosts(VoidCallback? onCreate) => EmptyStateWidget(
    icon: Icons.forum_outlined,
    iconColor: AppColors.energiePurple,
    title: 'Noch keine Beiträge',
    message: 'Sei der Erste, der etwas teilt!\nStarte eine Diskussion.',
    actionLabel: 'Beitrag erstellen',
    onAction: onCreate,
  );
  
  /// Keine Chat-Nachrichten
  static Widget get noMessages => const EmptyStateWidget(
    icon: Icons.chat_bubble_outline,
    iconColor: AppColors.textTertiary,
    title: 'Noch keine Nachrichten',
    message: 'Sei der Erste, der etwas schreibt!',
  );
  
  /// Loading State (während Daten laden)
  static Widget loading([String? message]) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          color: AppColors.energiePurple,
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ],
    ),
  );
}
