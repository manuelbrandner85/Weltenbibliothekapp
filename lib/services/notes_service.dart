import 'package:hive_flutter/hive_flutter.dart';
import '../models/research_note.dart';

class NotesService {
  static const String _boxName = 'research_notes';
  late Box<ResearchNote> _notesBox;

  Future<void> init() async {
    await Hive.initFlutter();
    // Registriere Adapter wenn noch nicht registriert
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(ResearchNoteAdapter());
    }
    _notesBox = await Hive.openBox<ResearchNote>(_boxName);
  }

  Future<void> addNote(ResearchNote note) async {
    await _notesBox.put(note.id, note);
  }

  Future<void> updateNote(ResearchNote note) async {
    note.updatedAt = DateTime.now();
    await _notesBox.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  ResearchNote? getNote(String id) {
    return _notesBox.get(id);
  }

  List<ResearchNote> getAllNotes() {
    return _notesBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<ResearchNote> getNotesByUrl(String url) {
    return _notesBox.values
        .where((note) => note.sourceUrl == url)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<ResearchNote> searchNotes(String query) {
    final lowerQuery = query.toLowerCase();
    return _notesBox.values
        .where((note) =>
            note.title.toLowerCase().contains(lowerQuery) ||
            note.content.toLowerCase().contains(lowerQuery) ||
            note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
