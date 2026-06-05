import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// A user that can be invited to a livestream.
class InviteUser {
  final String userId;
  final String username;
  final String? avatarUrl;
  const InviteUser({
    required this.userId,
    required this.username,
    this.avatarUrl,
  });
}

/// Handles inviting users to an active LiveKit room: push to online app
/// users + shareable deep-link text.
class LivestreamInviteService {
  LivestreamInviteService._();
  static final instance = LivestreamInviteService._();

  /// Fetch app users online in the last 15 minutes (excluding [excludeUserId]).
  Future<List<InviteUser>> getOnlineUsers({
    String? excludeUserId,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.workerUrl}/api/presence/online'
        '${excludeUserId != null ? '?exclude=$excludeUserId' : ''}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body) as Map<String, dynamic>;
      final list = (data['users'] as List?) ?? const [];
      return list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return InviteUser(
          userId: (m['user_id'] ?? '').toString(),
          username: (m['username'] ?? '').toString(),
          avatarUrl: (m['avatar_url'])?.toString(),
        );
      }).where((u) => u.userId.isNotEmpty && u.username.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  /// Send push invites to [userIds] for [roomName] in [world].
  /// Returns the number of invites accepted by the server (best effort).
  Future<bool> invite({
    required String roomName,
    required String world,
    required String fromName,
    required List<String> userIds,
  }) async {
    if (userIds.isEmpty) return false;
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.workerUrl}/api/livekit/invite'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'from_name': fromName,
              'room_name': roomName,
              'world': world,
              'target_user_ids': userIds,
            }),
          )
          .timeout(const Duration(seconds: 12));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Build a shareable invite text with a deep link into the room.
  String buildShareText({
    required String roomName,
    required String world,
    required String fromName,
  }) {
    final link = 'weltenbibliothek://live?room='
        '${Uri.encodeComponent(roomName)}&world=${Uri.encodeComponent(world)}';
    final worldLabel = switch (world) {
      'materie' => 'Materie',
      'energie' => 'Energie',
      'vorhang' => 'Vorhang',
      'ursprung' => 'Ursprung',
      _ => 'Weltenbibliothek',
    };
    return '$fromName lädt dich in einen Live-Call in der Welt "$worldLabel" ein!\n\n'
        'Öffne die Weltenbibliothek-App und tritt bei:\n$link\n\n'
        '(Noch keine App? Frag nach dem Download-Link.)';
  }
}
