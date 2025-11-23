import 'package:flutter/material.dart';
import '../../services/cloudflare_chat_service.dart';

/// Music Chat Integration Helper
///
/// Sendet automatische Chat-Nachrichten wenn:
/// - Ein neues Genre ausgewählt wird
/// - Ein neuer Song startet
/// - Musik pausiert/fortgesetzt wird
class MusicChatIntegration {
  final CloudflareChatService _chatService;
  final String roomId;

  MusicChatIntegration({
    required this.roomId,
    CloudflareChatService? chatService,
  }) : _chatService = chatService ?? CloudflareChatService();

  /// Sendet Nachricht wenn neues Genre ausgewählt wurde
  Future<void> notifyGenreSelected(
    BuildContext context,
    String genreName,
    String genreEmoji,
  ) async {
    try {
      await _chatService.sendMessage(
        chatRoomId: roomId,
        content: '🎵 $genreEmoji $genreName Musik wurde ausgewählt!',
        type: 'system',
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Senden der Genre-Nachricht: $e');
    }
  }

  /// Sendet Nachricht wenn neuer Song startet
  Future<void> notifySongStarted(
    BuildContext context,
    String title,
    String artist,
  ) async {
    try {
      await _chatService.sendMessage(
        chatRoomId: roomId,
        content: '🎵 Jetzt läuft: $title - $artist',
        type: 'system',
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Senden der Song-Nachricht: $e');
    }
  }

  /// Sendet Nachricht wenn Musik pausiert wird
  Future<void> notifyMusicPaused(BuildContext context) async {
    try {
      await _chatService.sendMessage(
        chatRoomId: roomId,
        content: '⏸️ Musik pausiert',
        type: 'system',
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Senden der Pause-Nachricht: $e');
    }
  }

  /// Sendet Nachricht wenn Musik fortgesetzt wird
  Future<void> notifyMusicResumed(BuildContext context) async {
    try {
      await _chatService.sendMessage(
        chatRoomId: roomId,
        content: '▶️ Musik fortgesetzt',
        type: 'system',
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Senden der Resume-Nachricht: $e');
    }
  }

  /// Sendet Nachricht wenn Lautstärke-Limit angewendet wird
  Future<void> notifyVolumeLimited(
    BuildContext context,
    int maxVolume,
    int participantCount,
  ) async {
    try {
      await _chatService.sendMessage(
        chatRoomId: roomId,
        content:
            '🔊 Lautstärke auf max. $maxVolume% limitiert ($participantCount Teilnehmer)',
        type: 'system',
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Senden der Volume-Nachricht: $e');
    }
  }
}

/// Helper-Funktion für automatische Chat-Notifications
///
/// Optional: Kann verwendet werden um automatische Nachrichten bei
/// Musik-Ereignissen zu senden (Genre-Wechsel, Song-Start, etc.)
///
/// Beispiel-Nutzung in initState():
/// ```dart
/// final musicIntegration = MusicChatIntegration(roomId: widget.chatRoom.id);
/// final musicProvider = context.read<SimpleMusicProvider>();
///
/// // Manuelle Notifications bei Bedarf:
/// await musicIntegration.notifyGenreSelected(context, 'Rock', '🎸');
/// ```
