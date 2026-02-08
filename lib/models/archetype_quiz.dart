class ArchetypeQuestion {
  final String question;
  final Map<String, int> answers; // answer -> archetype score mapping

  ArchetypeQuestion(this.question, this.answers);

  static List<ArchetypeQuestion> getQuestions() {
    return [
      ArchetypeQuestion('Wie gehst du mit Herausforderungen um?', {
        'Ich kämpfe für das Richtige': 0, // Warrior
        'Ich suche nach Wissen': 1, // Sage
        'Ich transformiere die Situation': 2, // Magician
        'Ich helfe anderen': 3, // Caregiver
      }),
      ArchetypeQuestion('Was motiviert dich am meisten?', {
        'Freiheit und Abenteuer': 4, // Explorer
        'Schönheit und Harmonie': 5, // Lover
        'Macht und Kontrolle': 6, // Ruler
        'Innovation und Kreation': 7, // Creator
      }),
      ArchetypeQuestion('Wie würdest du dich selbst beschreiben?', {
        'Unschuldig und optimistisch': 8, // Innocent
        'Witzig und verspielt': 9, // Jester
        'Normal und bodenständig': 10, // Everyman
        'Rebellisch und nonkonformistisch': 11, // Rebel
      }),
      ArchetypeQuestion('Was ist dir am wichtigsten?', {
        'Gerechtigkeit': 0,
        'Wahrheit': 1,
        'Transformation': 2,
        'Liebe': 5,
      }),
      ArchetypeQuestion('Deine Stärke liegt in...', {
        'Mut und Tapferkeit': 0,
        'Weisheit und Analyse': 1,
        'Kreativität und Vision': 2,
        'Empathie und Fürsorge': 3,
      }),
    ];
  }
}

class ArchetypeResult {
  final String name;
  final String description;
  final List<String> strengths;
  final List<String> crystals;
  final List<String> mantras;
  final String emoji;
  final double score;

  ArchetypeResult({
    required this.name,
    required this.description,
    required this.strengths,
    required this.crystals,
    required this.mantras,
    required this.emoji,
    required this.score,
  });

  static List<ArchetypeResult> getAllArchetypes() {
    return [
      ArchetypeResult(name: 'Der Krieger', description: 'Mutig, diszipliniert, kämpft für Gerechtigkeit', strengths: ['Mut', 'Disziplin', 'Schutz'], crystals: ['Roter Jaspis', 'Hämatit'], mantras: ['Ich bin stark', 'Ich schütze'], emoji: '⚔️', score: 0),
      ArchetypeResult(name: 'Der Weise', description: 'Sucht Wahrheit, analysiert, teilt Wissen', strengths: ['Weisheit', 'Objektivität', 'Wissen'], crystals: ['Lapislazuli', 'Sodalith'], mantras: ['Ich verstehe', 'Ich lerne'], emoji: '📚', score: 0),
      ArchetypeResult(name: 'Der Magier', description: 'Transformiert Realität, manifestiert Träume', strengths: ['Transformation', 'Vision', 'Macht'], crystals: ['Amethyst', 'Labradorit'], mantras: ['Ich manifestiere', 'Ich transformiere'], emoji: '🔮', score: 0),
      ArchetypeResult(name: 'Der Fürsorgliche', description: 'Hilft anderen, empathisch, selbstlos', strengths: ['Empathie', 'Fürsorge', 'Heilung'], crystals: ['Rosenquarz', 'Rhodonit'], mantras: ['Ich heile', 'Ich pflege'], emoji: '❤️', score: 0),
      ArchetypeResult(name: 'Der Entdecker', description: 'Sucht Freiheit, liebt Abenteuer', strengths: ['Freiheit', 'Neugier', 'Mut'], crystals: ['Citrin', 'Aventurin'], mantras: ['Ich erkunde', 'Ich bin frei'], emoji: '🧭', score: 0),
      ArchetypeResult(name: 'Der Liebende', description: 'Sucht Schönheit, Leidenschaft, Harmonie', strengths: ['Liebe', 'Schönheit', 'Leidenschaft'], crystals: ['Rosenquarz', 'Mondstein'], mantras: ['Ich liebe', 'Ich bin geliebt'], emoji: '💕', score: 0),
      ArchetypeResult(name: 'Der Herrscher', description: 'Führt, organisiert, kontrolliert', strengths: ['Führung', 'Kontrolle', 'Ordnung'], crystals: ['Tigerauge', 'Pyrit'], mantras: ['Ich führe', 'Ich kontrolliere'], emoji: '👑', score: 0),
      ArchetypeResult(name: 'Der Schöpfer', description: 'Erschafft, innoviert, drückt sich aus', strengths: ['Kreativität', 'Innovation', 'Vision'], crystals: ['Karneol', 'Citrin'], mantras: ['Ich erschaffe', 'Ich gestalte'], emoji: '🎨', score: 0),
      ArchetypeResult(name: 'Der Unschuldige', description: 'Optimistisch, vertrauensvoll, rein', strengths: ['Optimismus', 'Vertrauen', 'Hoffnung'], crystals: ['Bergkristall', 'Selenit'], mantras: ['Ich vertraue', 'Alles ist gut'], emoji: '🌟', score: 0),
      ArchetypeResult(name: 'Der Narr', description: 'Verspielt, witzig, lebt im Moment', strengths: ['Humor', 'Spontanität', 'Freude'], crystals: ['Orangencalcit', 'Sonnenstein'], mantras: ['Ich lache', 'Ich spiele'], emoji: '🤹', score: 0),
      ArchetypeResult(name: 'Der Jedermann', description: 'Bodenständig, verbindend, realistisch', strengths: ['Empathie', 'Verbindung', 'Realismus'], crystals: ['Jaspis', 'Achat'], mantras: ['Ich gehöre dazu', 'Ich bin genug'], emoji: '👤', score: 0),
      ArchetypeResult(name: 'Der Rebell', description: 'Bricht Regeln, revolutioniert, rebelliert', strengths: ['Rebellion', 'Freiheit', 'Revolution'], crystals: ['Obsidian', 'Schwarzer Turmalin'], mantras: ['Ich breche frei', 'Ich rebelliere'], emoji: '⚡', score: 0),
    ];
  }

  static List<ArchetypeResult> calculateResults(List<int> answers) {
    final archetypes = getAllArchetypes();
    final scores = List<int>.filled(12, 0);
    
    for (var answer in answers) {
      scores[answer]++;
    }
    
    for (int i = 0; i < archetypes.length; i++) {
      archetypes[i] = ArchetypeResult(
        name: archetypes[i].name,
        description: archetypes[i].description,
        strengths: archetypes[i].strengths,
        crystals: archetypes[i].crystals,
        mantras: archetypes[i].mantras,
        emoji: archetypes[i].emoji,
        score: scores[i] / answers.length,
      );
    }
    
    archetypes.sort((a, b) => b.score.compareTo(a.score));
    return archetypes;
  }
}
