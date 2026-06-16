// LearningModuleService — Katalog + Fortschritt fuer tagesweise Lernreihen.
//
// Provides the metadata for every learning module (name, description,
// emoji, accent colour, lessons) from a single source of truth and computes
// the locally stored progress from SharedPreferences. Previously this data
// lived inline inside LernreihenIndexScreen; extracting it makes the overview
// widgets reusable and unit-testable.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/affirmations_habit_21.dart';
import '../data/ancestral_lines_7.dart';
import '../data/archetypes_12.dart';
import '../data/chakra_program_7.dart';
import '../data/earthing_program_10.dart';
import '../data/elder_futhark_24.dart';
import '../data/hermetic_laws_7.dart';
import '../data/iching_kingwen_64.dart';
import '../data/kabbalah_paths_22.dart';
import '../data/mantra_path_21.dart';
import '../data/meditation_progression_21.dart';
import '../data/numerology_life_path_9.dart';
import '../data/olympian_gods_12.dart';
import '../data/sacred_geometry_12.dart';
import '../data/shamanic_initiation_7.dart';
import '../data/tarot_major_arcana_22.dart';
import '../data/yoga_challenge_30.dart';
import '../widgets/lesson_series_screen.dart';

/// Metadata describing a single tagesweise Lernreihe (learning module).
///
/// `description` carries the tradition/context line shown in the overview.
/// `accent` is the module's theme colour. `entries` are the daily lessons.
class LearningModule {
  final String title;
  final String emoji;
  final String description;
  final String storageKey;
  final Color accent;
  final List<LessonSeriesEntry> entries;

  const LearningModule({
    required this.title,
    required this.emoji,
    required this.description,
    required this.storageKey,
    required this.accent,
    required this.entries,
  });

  /// Number of daily lessons in this module.
  int get lessonCount => entries.length;
}

/// Completion state of a single module derived from local storage.
class LearningModuleProgress {
  final int completed;
  final int total;

  const LearningModuleProgress({required this.completed, required this.total});

  /// 0.0–1.0 fraction of completed lessons (0 when the module is empty).
  double get fraction => total == 0 ? 0.0 : completed / total;

  /// True once every lesson of the module has been completed.
  bool get isComplete => total > 0 && completed >= total;
}

/// Single source of truth for the learning-module catalog and its progress.
class LearningModuleService {
  LearningModuleService._();
  static final LearningModuleService instance = LearningModuleService._();

  // The catalog. Order defines the display order in the overview.
  static final List<LearningModule> _modules = [
    LearningModule(
      title: '7-Tage-Chakra-Programm',
      emoji: '🌈',
      description: 'Hinduistisch — 7 Energiezentren mit Mantra & Solfeggio',
      storageKey: 'lr_chakra_7',
      accent: const Color(0xFFE91E63),
      entries: chakraProgram7,
    ),
    LearningModule(
      title: '7-Tage-Kybalion',
      emoji: '✨',
      description:
          'Hermetisch — Die 7 universellen Prinzipien (Three Initiates, 1908)',
      storageKey: 'lr_hermetic_7',
      accent: const Color(0xFFFF9800),
      entries: hermeticLaws7,
    ),
    LearningModule(
      title: '7-Tage-Schamanen-Initiation',
      emoji: '🥁',
      description: 'Core Shamanism — Drei-Welten-Modell (M. Harner)',
      storageKey: 'lr_shamanic_7',
      accent: const Color(0xFF8E5AE2),
      entries: shamanicInitiation7,
    ),
    LearningModule(
      title: '7-Tage-Ahnen-Linien',
      emoji: '🕯️',
      description:
          'Systemisch — Hellinger-orientiert, weibliche & männliche Linien',
      storageKey: 'lr_ancestral_7',
      accent: const Color(0xFFD4A24C),
      entries: ancestralLines7,
    ),
    LearningModule(
      title: '9-Tage-Lebenszahlen',
      emoji: '🔢',
      description: 'Pythagoräische Numerologie — die 9 Grundzahlen',
      storageKey: 'lr_numerology_9',
      accent: const Color(0xFF9C27B0),
      entries: numerologyLifePath9,
    ),
    LearningModule(
      title: '10-Tage-Earthing',
      emoji: '🌍',
      description: 'Naturmedizin — progressives Erdungs-Programm',
      storageKey: 'lr_earthing_10',
      accent: const Color(0xFF558B2F),
      entries: earthingProgram10,
    ),
    LearningModule(
      title: '12-Tage-Archetypen',
      emoji: '🧠',
      description: 'Carol Pearson — die 12 Hauptarchetypen in 4 Stufen',
      storageKey: 'lr_archetypes_12',
      accent: const Color(0xFF673AB7),
      entries: archetypes12,
    ),
    LearningModule(
      title: '12-Tage-Olymp',
      emoji: '🏛️',
      description: 'Griechisches Pantheon — die 12 Olympier (Hesiod, Homer)',
      storageKey: 'lr_olympian_12',
      accent: const Color(0xFF6A1B9A),
      entries: olympianGods12,
    ),
    LearningModule(
      title: '12-Tage-Heilige-Geometrie',
      emoji: '🔯',
      description: 'Sakrale Muster — von Kreis bis Torus',
      storageKey: 'lr_geometry_12',
      accent: const Color(0xFF00838F),
      entries: sacredGeometry12,
    ),
    LearningModule(
      title: '21-Tage-Meditation',
      emoji: '🧘',
      description: '3-Wochen-Aufbau: Atem · Body-Scan · Open Awareness',
      storageKey: 'lr_meditation_21',
      accent: const Color(0xFF4527A0),
      entries: meditationProgression21,
    ),
    LearningModule(
      title: '21-Tage-Mantras',
      emoji: '🕉️',
      description:
          '7 Sanskrit-Mantras über 3 Wochen (OM, So Ham, Gayatri, Shiva...)',
      storageKey: 'lr_mantras_21',
      accent: const Color(0xFFE65100),
      entries: mantraPath21,
    ),
    LearningModule(
      title: '21-Tage-Affirmationen',
      emoji: '💫',
      description: 'Habit-Formation: Selbstwert · Liebe · Fülle · Gesundheit',
      storageKey: 'lr_affirmations_21',
      accent: const Color(0xFFE91E63),
      entries: affirmationsHabit21,
    ),
    LearningModule(
      title: '22-Pfade-Kabbala',
      emoji: '🌳',
      description: 'Hebräische Mystik — Verbindungen im Lebensbaum',
      storageKey: 'lr_kabbalah_22',
      accent: const Color(0xFF00BCD4),
      entries: kabbalahPaths22,
    ),
    LearningModule(
      title: '22-Tage-Tarot-Major',
      emoji: '🔮',
      description: 'Rider-Waite-Smith — die 22 Trumpfkarten der Reise',
      storageKey: 'lr_tarot_22',
      accent: const Color(0xFF4A148C),
      entries: tarotMajorArcana22,
    ),
    LearningModule(
      title: '24-Tage-Elder-Futhark',
      emoji: 'ᚱ',
      description: 'Nordische Mystik — 24 Runen in 3 Aetts',
      storageKey: 'lr_runes_24',
      accent: const Color(0xFF795548),
      entries: elderFutharkPath24,
    ),
    LearningModule(
      title: '30-Tage-Yoga-Challenge',
      emoji: '🧘‍♀️',
      description: 'Progressiv: Grund · Sonnengruß · Standasanas · Inversion',
      storageKey: 'lr_yoga_30',
      accent: const Color(0xFF00695C),
      entries: yogaChallenge30,
    ),
    LearningModule(
      title: '64-Tage-I-Ging',
      emoji: '☯',
      description: 'King-Wen-Sequenz · Wilhelm-Übersetzung der 64 Hexagramme',
      storageKey: 'lr_iching_64',
      accent: const Color(0xFF424242),
      entries: ichingKingWen64,
    ),
  ];

  /// Immutable view of the module catalog in display order.
  List<LearningModule> get modules => List.unmodifiable(_modules);

  /// Total number of lessons across all modules.
  int get totalLessons => _modules.fold<int>(0, (a, m) => a + m.lessonCount);

  /// Loads the number of completed lessons per module from SharedPreferences,
  /// keyed by each module's `storageKey`.
  Future<Map<String, int>> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final m in _modules)
        m.storageKey: (prefs.getStringList(m.storageKey) ?? const []).length,
    };
  }

  /// Builds a [LearningModuleProgress] for [module] from a raw progress map.
  LearningModuleProgress progressFor(
    LearningModule module,
    Map<String, int> raw,
  ) {
    return LearningModuleProgress(
      completed: raw[module.storageKey] ?? 0,
      total: module.lessonCount,
    );
  }

  /// Total completed lessons across all modules for the given progress map.
  int completedLessons(Map<String, int> raw) =>
      raw.values.fold<int>(0, (a, b) => a + b);
}
