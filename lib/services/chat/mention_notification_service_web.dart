// Web-Stub für MentionNotificationService — keine lokalen Notifications auf Web.

class MentionNotificationService {
  MentionNotificationService._();
  static final MentionNotificationService instance =
      MentionNotificationService._();

  Future<void> init() async {}

  static bool containsMention(String message, String username) {
    if (username.isEmpty) return false;
    final escaped = RegExp.escape(username);
    final re = RegExp('(^|[^a-zA-Z0-9_])@$escaped(?![a-zA-Z0-9_])',
        caseSensitive: false);
    return re.hasMatch(message);
  }

  Future<void> notifyMention({
    required String fromUsername,
    required String roomLabel,
    required String snippet,
  }) async {}
}
