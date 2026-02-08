import 'package:flutter/material.dart';

/// Konsistente Text-Styles für die gesamte App
/// 
/// VERWENDUNG:
/// - Titel: AppTextStyles.cardTitle
/// - Subtitle: AppTextStyles.cardSubtitle
/// - Body: AppTextStyles.cardBody
/// - Caption: AppTextStyles.cardCaption
class AppTextStyles {
  AppTextStyles._(); // Private constructor - nur statische Methoden
  
  // 🎨 CARD TEXT STYLES
  
  /// Card Titel (16px, Bold, 2 Zeilen max)
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: Colors.white,
  );
  
  /// Card Subtitle (14px, Medium, 2 Zeilen max)
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: Colors.white70,
  );
  
  /// Card Body Text (13px, Normal, 3 Zeilen max)
  static const TextStyle cardBody = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: Colors.white70,
  );
  
  /// Card Caption (12px, Normal, 1 Zeile max)
  static const TextStyle cardCaption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.2,
    color: Colors.white54,
  );
  
  // 🎨 CHAT TEXT STYLES
  
  /// Chat Username (14px, Bold)
  static const TextStyle chatUsername = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  /// Chat Message (14px, Normal)
  static const TextStyle chatMessage = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: Colors.white,
  );
  
  /// Chat Timestamp (11px, Normal)
  static const TextStyle chatTimestamp = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: Colors.white54,
  );
  
  // 🎨 BUTTON TEXT STYLES
  
  /// Primary Button Text (15px, Bold)
  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  /// Secondary Button Text (14px, Medium)
  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );
  
  // 🎨 HEADER TEXT STYLES
  
  /// Section Header (18px, Bold)
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  /// Section Subheader (15px, Medium)
  static const TextStyle sectionSubheader = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );
  
  // 🎨 RECHERCHE TEXT STYLES
  
  /// Recherche Quelle Titel (15px, Bold, 2 Zeilen)
  static const TextStyle rechercheTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: Colors.white,
  );
  
  /// Recherche Snippet (13px, Normal, 3 Zeilen)
  static const TextStyle rechercheSnippet = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: Colors.white70,
  );
  
  /// Recherche URL (12px, Normal, 1 Zeile)
  static const TextStyle rechercheUrl = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Colors.white54,
  );
}

/// Text Constraints für konsistente Anzeige
class AppTextConstraints {
  AppTextConstraints._(); // Private constructor
  
  /// Card Titel: Max 2 Zeilen
  static const int cardTitleMaxLines = 2;
  
  /// Card Subtitle: Max 2 Zeilen
  static const int cardSubtitleMaxLines = 2;
  
  /// Card Body: Max 3 Zeilen
  static const int cardBodyMaxLines = 3;
  
  /// Card Caption: Max 1 Zeile
  static const int cardCaptionMaxLines = 1;
  
  /// Chat Message: Max 50 Zeilen (sehr lange Messages)
  static const int chatMessageMaxLines = 50;
  
  /// Recherche Title: Max 2 Zeilen
  static const int rechercheTitleMaxLines = 2;
  
  /// Recherche Snippet: Max 3 Zeilen
  static const int rechercheSnippetMaxLines = 3;
  
  /// URL: Max 1 Zeile
  static const int urlMaxLines = 1;
  
  /// Default Overflow Behavior
  static const TextOverflow defaultOverflow = TextOverflow.ellipsis;
}

/// Helper Extension für schnelle Text-Widget Erstellung
extension TextStyleExtensions on Text {
  /// Wendet Card Title Style an
  Text asCardTitle() => Text(
    data ?? '',
    style: AppTextStyles.cardTitle,
    maxLines: AppTextConstraints.cardTitleMaxLines,
    overflow: AppTextConstraints.defaultOverflow,
  );
  
  /// Wendet Card Body Style an
  Text asCardBody() => Text(
    data ?? '',
    style: AppTextStyles.cardBody,
    maxLines: AppTextConstraints.cardBodyMaxLines,
    overflow: AppTextConstraints.defaultOverflow,
  );
}
