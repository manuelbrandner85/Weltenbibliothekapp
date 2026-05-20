// LiveScheduleService -- speichert geplante Live-Sessions pro World+Room
// in SharedPreferences. Wird vom LiveChatHero (scheduledAt / scheduledTopic)
// gelesen und vom onSchedule-Callback geschrieben.
//
// Persistenz-Schema (SharedPreferences):
//   live_schedule_<world>_<room>__when  = ISO-8601 String
//   live_schedule_<world>_<room>__topic = String
//
// In v107 wird die Persistenz auf Supabase (Tabelle live_schedules) erweitert
// damit Sessions cross-device sichtbar werden -- aktuell lokal-only.

import 'package:shared_preferences/shared_preferences.dart';

class LiveSchedule {
  final DateTime when;
  final String topic;

  const LiveSchedule({required this.when, required this.topic});
}

class LiveScheduleService {
  LiveScheduleService._();
  static final LiveScheduleService instance = LiveScheduleService._();

  String _whenKey(String world, String room) =>
      'live_schedule_${world}_${room}__when';
  String _topicKey(String world, String room) =>
      'live_schedule_${world}_${room}__topic';

  Future<LiveSchedule?> load(String world, String room) async {
    final prefs = await SharedPreferences.getInstance();
    final w = prefs.getString(_whenKey(world, room));
    final t = prefs.getString(_topicKey(world, room));
    if (w == null || t == null || t.trim().isEmpty) return null;
    final dt = DateTime.tryParse(w);
    if (dt == null) return null;
    // Vergangene Sessions automatisch verwerfen
    if (dt.isBefore(DateTime.now().subtract(const Duration(hours: 2)))) {
      await clear(world, room);
      return null;
    }
    return LiveSchedule(when: dt, topic: t);
  }

  Future<void> save(String world, String room, LiveSchedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _whenKey(world, room), schedule.when.toIso8601String());
    await prefs.setString(_topicKey(world, room), schedule.topic);
  }

  Future<void> clear(String world, String room) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_whenKey(world, room));
    await prefs.remove(_topicKey(world, room));
  }
}
