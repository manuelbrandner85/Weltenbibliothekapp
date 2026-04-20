/// 📌 PINNED VOICE ROOMS SERVICE
/// Manages pinned voice rooms per user
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PinnedRoomsService {
  static final PinnedRoomsService _instance = PinnedRoomsService._internal();
  factory PinnedRoomsService() => _instance;
  PinnedRoomsService._internal();

  static const String _keyPinnedRooms = 'pinned_voice_rooms';

  Set<String> _pinnedRooms = {};

  Set<String> get pinnedRooms => Set.unmodifiable(_pinnedRooms);

  /// Load pinned rooms from storage
  Future<void> loadPinnedRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyPinnedRooms);
    
    if (jsonString != null) {
      final List<dynamic> list = json.decode(jsonString);
      _pinnedRooms = list.cast<String>().toSet();
    }
  }

  /// Check if room is pinned
  bool isPinned(String roomId) {
    return _pinnedRooms.contains(roomId);
  }

  /// Pin a room
  Future<void> pinRoom(String roomId) async {
    _pinnedRooms.add(roomId);
    await _savePinnedRooms();
  }

  /// Unpin a room
  Future<void> unpinRoom(String roomId) async {
    _pinnedRooms.remove(roomId);
    await _savePinnedRooms();
  }

  /// Toggle pin status
  Future<void> togglePin(String roomId) async {
    if (isPinned(roomId)) {
      await unpinRoom(roomId);
    } else {
      await pinRoom(roomId);
    }
  }

  /// Save to storage
  Future<void> _savePinnedRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_pinnedRooms.toList());
    await prefs.setString(_keyPinnedRooms, jsonString);
  }

  /// Clear all pinned rooms
  Future<void> clearAll() async {
    _pinnedRooms.clear();
    await _savePinnedRooms();
  }
}
