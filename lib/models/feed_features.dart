import 'live_feed_entry.dart';

/// Feature 1: Push-Benachrichtigung
class FeedNotification {
  final String feedId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  
  FeedNotification({
    required this.feedId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

/// Feature 2: Lesezeichen/Favoriten
class FeedBookmark {
  final String feedId;
  final DateTime savedAt;
  final String? notes;
  final List<String> tags;
  
  FeedBookmark({
    required this.feedId,
    required this.savedAt,
    this.notes,
    this.tags = const [],
  });
}

/// Feature 3: Teilen-Funktion
class FeedShare {
  final String feedId;
  final ShareType shareType;
  final DateTime sharedAt;
  final String? recipientUserId;
  
  FeedShare({
    required this.feedId,
    required this.shareType,
    required this.sharedAt,
    this.recipientUserId,
  });
}

enum ShareType {
  copyLink,
  postToCommunity,
  shareWithUser,
}

/// Feature 4: Erweiterte Filter
class FeedFilter {
  final Set<String> selectedThemes;
  final Set<QuellenTyp> selectedTypes;
  final DateRange? dateRange;
  final int? minTiefeLevel;
  final int? maxTiefeLevel;
  final Set<String> selectedSources;
  
  FeedFilter({
    this.selectedThemes = const {},
    this.selectedTypes = const {},
    this.dateRange,
    this.minTiefeLevel,
    this.maxTiefeLevel,
    this.selectedSources = const {},
  });
  
  bool matches(LiveFeedEntry feed) {
    // Thema
    if (selectedThemes.isNotEmpty) {
      if (feed is MaterieFeedEntry && !selectedThemes.contains(feed.thema)) {
        return false;
      }
      if (feed is EnergieFeedEntry && !selectedThemes.contains(feed.spiritThema)) {
        return false;
      }
    }
    
    // Typ
    if (selectedTypes.isNotEmpty && !selectedTypes.contains(feed.quellentyp)) {
      return false;
    }
    
    // Datum
    if (dateRange != null) {
      if (feed.fetchTimestamp.isBefore(dateRange!.start) || 
          feed.fetchTimestamp.isAfter(dateRange!.end)) {
        return false;
      }
    }
    
    // Tiefe-Level (nur Materie)
    if (feed is MaterieFeedEntry) {
      if (minTiefeLevel != null && feed.tiefeLevel < minTiefeLevel!) {
        return false;
      }
      if (maxTiefeLevel != null && feed.tiefeLevel > maxTiefeLevel!) {
        return false;
      }
    }
    
    // Quelle
    if (selectedSources.isNotEmpty && !selectedSources.contains(feed.quelle)) {
      return false;
    }
    
    return true;
  }
}

class DateRange {
  final DateTime start;
  final DateTime end;
  
  DateRange(this.start, this.end);
}

/// Feature 5: Feed-Statistiken
class FeedStatistics {
  final int totalFeeds;
  final int newThisWeek;
  final int newToday;
  final Map<String, int> themeDistribution;
  final Map<QuellenTyp, int> typeDistribution;
  final String topTheme;
  final int bookmarkedCount;
  
  FeedStatistics({
    required this.totalFeeds,
    required this.newThisWeek,
    required this.newToday,
    required this.themeDistribution,
    required this.typeDistribution,
    required this.topTheme,
    required this.bookmarkedCount,
  });
}

/// Feature 6: Feed-Kommentare
class FeedComment {
  final String commentId;
  final String feedId;
  final String userId;
  final String username;
  final String content;
  final DateTime createdAt;
  final int likes;
  
  FeedComment({
    required this.commentId,
    required this.feedId,
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    this.likes = 0,
  });
}

/// Feature 7: Verwandte Feeds
class RelatedFeeds {
  static List<LiveFeedEntry> findRelated(
    LiveFeedEntry currentFeed, 
    List<LiveFeedEntry> allFeeds,
  ) {
    final related = <LiveFeedEntry>[];
    
    for (final feed in allFeeds) {
      if (feed.feedId == currentFeed.feedId) continue;
      
      int score = 0;
      
      // Gleicher Typ: +2
      if (feed.quellentyp == currentFeed.quellentyp) score += 2;
      
      // Ähnliches Thema: +3
      if (currentFeed is MaterieFeedEntry && feed is MaterieFeedEntry) {
        if (feed.thema == currentFeed.thema) score += 3;
      }
      if (currentFeed is EnergieFeedEntry && feed is EnergieFeedEntry) {
        if (feed.spiritThema == currentFeed.spiritThema) score += 3;
      }
      
      // Gleiche Welt: +1
      if (feed.welt == currentFeed.welt) score += 1;
      
      if (score >= 3) {
        related.add(feed);
      }
    }
    
    related.sort((a, b) => b.fetchTimestamp.compareTo(a.fetchTimestamp));
    return related.take(5).toList();
  }
}

/// Feature 8: Offline-Speicherung
class OfflineFeed {
  final String feedId;
  final String content;
  final DateTime downloadedAt;
  final int fileSize;
  
  OfflineFeed({
    required this.feedId,
    required this.content,
    required this.downloadedAt,
    required this.fileSize,
  });
}

/// Feature 9: Kategorie-Farben
class CategoryColors {
  static const Map<String, int> materieColors = {
    'Geopolitik': 0xFFE53935,        // Rot
    'Geschichte': 0xFF1E88E5,         // Blau
    'Wirtschaft': 0xFF43A047,         // Grün
    'Sicherheit': 0xFFFB8C00,         // Orange
    'Forschung': 0xFF8E24AA,          // Lila
  };
  
  static const Map<String, int> energieColors = {
    'Kabbala': 0xFF9C27B0,            // Lila
    'Hermetik': 0xFFD81B60,           // Pink
    'Symbolik': 0xFF00ACC1,           // Cyan
    'Archetypen': 0xFF5E35B1,         // Deep Purple
    'Meditation': 0xFF00897B,         // Teal
  };
}

/// Feature 10: Lesezeit & Fortschritt
class ReadingProgress {
  final String feedId;
  final int totalWords;
  final int estimatedMinutes;
  final double progressPercent;
  final DateTime? lastReadAt;
  
  ReadingProgress({
    required this.feedId,
    required this.totalWords,
    required this.estimatedMinutes,
    required this.progressPercent,
    this.lastReadAt,
  });
  
  int get wordsRead => (totalWords * (progressPercent / 100)).round();
  
  static int calculateReadingTime(String text) {
    final words = text.split(RegExp(r'\s+')).length;
    // Durchschnittlich 200 Wörter pro Minute
    return (words / 200).ceil();
  }
  
  static int countWords(String text) {
    return text.split(RegExp(r'\s+')).length;
  }
}
