import '../models/spirit_extended_models.dart';
import '../models/spirit_dashboard.dart';
import '../models/energie_profile.dart';
import 'storage_service.dart';

/// VORSCHLAG 1: TÄGLICHE SPIRIT-ÜBUNGEN GENERATOR
/// Generiert personalisierte Übungen basierend auf:
/// - Aktuellem Zyklus
/// - Archetyp
/// - Schwachen Chakren (falls Analyse vorhanden)
class DailyPracticesService {
  final StorageService _storage = StorageService();

  /// Generiere tägliche Übungen für heute
  Future<List<DailySpiritPractice>> generateDailyPractices({
    required EnergieProfile profile,
    required SpiritDashboard dashboard,
  }) async {
    final today = DateTime.now();
    final practices = <DailySpiritPractice>[];

    // Prüfe ob bereits Übungen für heute existieren
    final existingPractices = _storage.getDailyPractices(forDate: today);
    if (existingPractices.isNotEmpty) {
      return existingPractices;
    }

    // 1. ÜBUNG BASIEREND AUF ZYKLUS
    final cyclePhase = dashboard.nineYearCycle['phase'] as String;
    practices.add(_generateCyclePractice(cyclePhase, dashboard.personalYear, today));

    // 2. ÜBUNG BASIEREND AUF ARCHETYP
    final archetype = dashboard.primaryArchetype['name'] as String;
    practices.add(_generateArchetypePractice(archetype, today));

    // 3. ALLGEMEINE MEDITATIONS-ÜBUNG
    practices.add(_generateMeditationPractice(today));

    // 4. JOURNAL-PROMPT
    practices.add(_generateJournalPrompt(dashboard, today));

    // 5. ATEM-ÜBUNG (immer dabei)
    practices.add(_generateBreathingExercise(today));

    // Speichere generierte Übungen
    for (var practice in practices) {
      await _storage.saveDailyPractice(practice);
    }

    return practices;
  }

  DailySpiritPractice _generateCyclePractice(String phase, int personalYear, DateTime date) {
    final practices = {
      'Neuanfang': DailySpiritPractice(
        id: 'cycle_${date.toIso8601String()}',
        title: 'Morgen-Intention setzen',
        description: 'Du bist in einer Neuanfang-Phase (Jahr $personalYear). '
            'Visualisiere heute Morgen für 5 Minuten deine Ziele für dieses Jahr. '
            'Was möchtest du manifestieren?',
        category: 'meditation',
        durationMinutes: 5,
        basedOn: 'cycle',
        recommendedDate: date,
      ),
      'Wachstum': DailySpiritPractice(
        id: 'cycle_${date.toIso8601String()}',
        title: 'Dankbarkeits-Meditation',
        description: 'Du befindest dich in einer Wachstums-Phase. '
            'Reflektiere über deine Fortschritte und sei dankbar für das Gelernte.',
        category: 'meditation',
        durationMinutes: 10,
        basedOn: 'cycle',
        recommendedDate: date,
      ),
      'Höhepunkt': DailySpiritPractice(
        id: 'cycle_${date.toIso8601String()}',
        title: 'Energie-Integration',
        description: 'Du bist auf dem Höhepunkt deines Zyklus. '
            'Integriere all deine Erfahrungen durch eine tiefe Meditation.',
        category: 'meditation',
        durationMinutes: 15,
        basedOn: 'cycle',
        recommendedDate: date,
      ),
    };

    return practices[phase] ?? practices['Neuanfang']!;
  }

  DailySpiritPractice _generateArchetypePractice(String archetype, DateTime date) {
    final practices = {
      'Der Weise': DailySpiritPractice(
        id: 'archetype_${date.toIso8601String()}',
        title: 'Stille Kontemplation',
        description: 'Als "Der Weise" ist Stille deine Kraftquelle. '
            'Setze dich 10 Minuten in Stille und beobachte deine Gedanken ohne Urteil.',
        category: 'meditation',
        durationMinutes: 10,
        basedOn: 'archetype',
        recommendedDate: date,
      ),
      'Der Krieger': DailySpiritPractice(
        id: 'archetype_${date.toIso8601String()}',
        title: 'Mut-Affirmationen',
        description: 'Als "Der Krieger" stärke deine innere Kraft. '
            'Wiederhole 3x: "Ich bin mutig, stark und bereit für jede Herausforderung."',
        category: 'meditation',
        durationMinutes: 5,
        basedOn: 'archetype',
        recommendedDate: date,
      ),
      'Der Magier': DailySpiritPractice(
        id: 'archetype_${date.toIso8601String()}',
        title: 'Manifestations-Ritual',
        description: 'Als "Der Magier" kannst du Realität formen. '
            'Visualisiere dein größtes Ziel und fühle es bereits als Realität.',
        category: 'meditation',
        durationMinutes: 15,
        basedOn: 'archetype',
        recommendedDate: date,
      ),
      'Der Liebende': DailySpiritPractice(
        id: 'archetype_${date.toIso8601String()}',
        title: 'Herzöffnung-Meditation',
        description: 'Als "Der Liebende" ist dein Herz dein Kompass. '
            'Lege eine Hand auf dein Herz und sende Liebe zu dir selbst und anderen.',
        category: 'chakra',
        durationMinutes: 10,
        basedOn: 'archetype',
        recommendedDate: date,
      ),
    };

    return practices[archetype] ?? DailySpiritPractice(
      id: 'archetype_${date.toIso8601String()}',
      title: 'Archetyp-Meditation',
      description: 'Verbinde dich mit deinem inneren Archetyp "$archetype". '
          'Frage dich: Was möchte dieser Teil von mir heute ausdrücken?',
      category: 'meditation',
      durationMinutes: 10,
      basedOn: 'archetype',
      recommendedDate: date,
    );
  }

  DailySpiritPractice _generateMeditationPractice(DateTime date) {
    return DailySpiritPractice(
      id: 'meditation_${date.toIso8601String()}',
      title: 'Achtsamkeits-Meditation',
      description: 'Eine einfache Achtsamkeits-Meditation für den Alltag. '
          'Fokussiere dich 5 Minuten nur auf deinen Atem. '
          'Einatmen - Ausatmen. Lass Gedanken wie Wolken vorbeiziehen.',
      category: 'meditation',
      durationMinutes: 5,
      basedOn: 'daily',
      recommendedDate: date,
    );
  }

  DailySpiritPractice _generateJournalPrompt(SpiritDashboard dashboard, DateTime date) {
    final prompts = [
      'Was hat mir heute am meisten Freude bereitet?',
      'Welche Synchronizität habe ich heute bemerkt?',
      'Wofür bin ich heute besonders dankbar?',
      'Was möchte mein höheres Selbst mir heute sagen?',
      'Welche Lektion durfte ich heute lernen?',
    ];

    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final prompt = prompts[dayOfYear % prompts.length];

    return DailySpiritPractice(
      id: 'journal_${date.toIso8601String()}',
      title: 'Journal-Reflexion',
      description: 'Tägliche Reflexionsfrage:\n\n"$prompt"\n\n'
          'Nimm dir 5 Minuten Zeit und schreibe deine Gedanken auf.',
      category: 'journal',
      durationMinutes: 5,
      basedOn: 'daily',
      recommendedDate: date,
    );
  }

  DailySpiritPractice _generateBreathingExercise(DateTime date) {
    return DailySpiritPractice(
      id: 'breathing_${date.toIso8601String()}',
      title: '4-7-8 Atemtechnik',
      description: 'Eine kraftvolle Atemübung zur Entspannung:\n\n'
          '1. Atme 4 Sekunden durch die Nase ein\n'
          '2. Halte den Atem 7 Sekunden\n'
          '3. Atme 8 Sekunden durch den Mund aus\n\n'
          'Wiederhole 4 Runden.',
      category: 'breathing',
      durationMinutes: 3,
      basedOn: 'daily',
      recommendedDate: date,
    );
  }

  /// Übung als abgeschlossen markieren
  Future<void> completePractice(String practiceId) async {
    final practices = _storage.getDailyPractices();
    final practice = practices.firstWhere((p) => p.id == practiceId);
    
    final completed = practice.copyWith(
      completed: true,
      completedAt: DateTime.now(),
    );
    
    await _storage.saveDailyPractice(completed);
    
    // Punkte vergeben (VORSCHLAG 8)
    await _storage.addPoints(10, 'meditation');
  }
}
