import 'package:flutter/foundation.dart';

/// Hält pro Raum den aktuellen (ungesendeten) Textentwurf.
///
/// Use-Case: User tippt im Raum A, springt nach B, kommt nach A zurück →
/// der Text ist noch im Input-Feld. In-Memory only — das reicht für die
/// Session. Bei App-Neustart beginnt man frisch.
class ChatDraftService extends ChangeNotifier {
  ChatDraftService._();
  static final ChatDraftService instance = ChatDraftService._();

  final Map<String, String> _drafts = <String, String>{};

  String get(String roomId) => _drafts[roomId] ?? '';

  void set(String roomId, String text) {
    if (text.isEmpty) {
      if (_drafts.remove(roomId) != null) notifyListeners();
      return;
    }
    if (_drafts[roomId] == text) return;
    _drafts[roomId] = text;
    notifyListeners();
  }

  void clear(String roomId) {
    if (_drafts.remove(roomId) != null) notifyListeners();
  }

  void clearAll() {
    if (_drafts.isEmpty) return;
    _drafts.clear();
    notifyListeners();
  }
}
