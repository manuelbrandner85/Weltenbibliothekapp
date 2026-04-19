import 'package:flutter/material.dart';
import 'dart:math';

class PropagandaAnalysis {
  final String text;
  final double biasScore; // 0-100
  final Map<String, double> techniques; // technique name -> confidence
  final List<String> emotionalWords;
  final List<String> warnings;
  final String verdict;
  final Color verdictColor;
  final List<String> sources;
  final Map<String, dynamic> sentiment;
  final List<String> manipulationTactics;

  PropagandaAnalysis({
    required this.text,
    required this.biasScore,
    required this.techniques,
    required this.emotionalWords,
    required this.warnings,
    required this.verdict,
    required this.verdictColor,
    required this.sources,
    required this.sentiment,
    required this.manipulationTactics,
  });

  static PropagandaAnalysis analyze(String text) {
    final techniques = <String, double>{};
    final emotionalWords = <String>[];
    final warnings = <String>[];
    final sources = <String>[];
    final manipulationTactics = <String>[];
    
    // ADVANCED EMOTIONAL LANGUAGE DETECTION
    final emotionalKeywords = {
      'Angst': ['schrecklich', 'katastrophal', 'gefährlich', 'bedrohlich', 'horror', 'terror'],
      'Wut': ['skandal', 'empörend', 'unverschämt', 'unglaublich', 'schockierend'],
      'Übertreibung': ['dramatisch', 'alarmierend', 'verheerend', 'gigantisch', 'massiv'],
      'Nationalismus': ['vaterland', 'heimat', 'nation', 'volk', 'unsere'],
      'Feindbilder': ['gegner', 'feind', 'bedrohung', 'invasion', 'übernahme'],
    };
    
    for (var category in emotionalKeywords.entries) {
      int count = 0;
      for (var word in category.value) {
        if (text.toLowerCase().contains(word)) {
          emotionalWords.add('$word (${category.key})');
          count++;
        }
      }
      if (count > 0) {
        techniques[category.key] = min(count * 18.0, 95.0);
        if (count > 2) {
          warnings.add('Übermäßige ${category.key.toLowerCase()}-basierte Sprache erkannt');
        }
      }
    }
    
    // FEAR MONGERING DETECTION
    final fearPatterns = ['droht', 'gefahr', 'risiko', 'warnung', 'achtung', 'vorsicht'];
    int fearCount = 0;
    for (var pattern in fearPatterns) {
      if (text.toLowerCase().contains(pattern)) fearCount++;
    }
    if (fearCount > 0) {
      techniques['Angstmache'] = min(fearCount * 22.0, 90.0);
      warnings.add('Nutzt Angst als primäres Überzeugungsmittel ($fearCount Instanzen)');
      manipulationTactics.add('Fear Appeal: Emotionale Manipulation durch Angsterzeugung');
    }
    
    // ABSOLUTISM & GENERALIZATION
    final absoluteWords = ['immer', 'nie', 'niemals', 'alle', 'niemand', 'jeder', 'keiner', 'alles', 'nichts'];
    int absoluteCount = 0;
    for (var word in absoluteWords) {
      final regex = RegExp('\\b$word\\b', caseSensitive: false);
      absoluteCount += regex.allMatches(text).length;
    }
    if (absoluteCount > 0) {
      techniques['Absolutismus'] = min(absoluteCount * 15.0, 85.0);
      warnings.add('$absoluteCount absolute Aussagen gefunden (verhindert nuancierte Diskussion)');
      manipulationTactics.add('Black & White Thinking: Eliminiert Grautöne und Komplexität');
    }
    
    // SOURCE VERIFICATION
    final sourceIndicators = ['quelle:', 'laut', 'studie', 'forschung', 'bericht', 'experten', 'wissenschaftler', 'professor', 'dr.'];
    bool hasSource = false;
    for (var indicator in sourceIndicators) {
      if (text.toLowerCase().contains(indicator)) {
        hasSource = true;
        sources.add('Quellenreferenz gefunden: "$indicator"');
      }
    }
    
    if (!hasSource && text.length > 100) {
      techniques['Fehlende Quellen'] = 75.0;
      warnings.add('Keine verifizierbaren Quellen angegeben (${text.length} Zeichen Text)');
      manipulationTactics.add('Appeal to Anonymous Authority: Behauptungen ohne Belege');
    } else if (hasSource) {
      techniques['Quellenangabe'] = 20.0; // Positiver Faktor
    }
    
    // US VS THEM RHETORIC
    final usWords = text.toLowerCase().split(' ').where((w) => w == 'wir' || w == 'uns' || w == 'unser').length;
    final themWords = text.toLowerCase().split(' ').where((w) => w == 'sie' || w == 'die' || w == 'deren').length;
    
    if (usWords > 2 && themWords > 2) {
      final ratio = (usWords + themWords) / text.split(' ').length;
      techniques['Wir vs. Die'] = min(ratio * 300, 80.0);
      warnings.add('Spaltet in Gruppen (Ingroup vs. Outgroup): $usWords "Wir" vs $themWords "Sie"');
      manipulationTactics.add('Us vs Them: Tribalistisches Gruppendenken fördern');
    }
    
    // LOADED LANGUAGE
    final loadedWords = ['angeblich', 'sogenannt', 'selbsternannt', 'regime', 'marionette', 'verschwörung'];
    int loadedCount = 0;
    for (var word in loadedWords) {
      if (text.toLowerCase().contains(word)) {
        loadedCount++;
        emotionalWords.add('$word (Wertegeladen)');
      }
    }
    if (loadedCount > 0) {
      techniques['Wertegeladene Sprache'] = min(loadedCount * 20.0, 70.0);
      manipulationTactics.add('Loaded Language: Bewertende statt neutrale Begriffe');
    }
    
    // REPETITION DETECTION
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    final wordFreq = <String, int>{};
    for (var word in words) {
      if (word.length > 5) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }
    }
    final repeated = wordFreq.entries.where((e) => e.value > 2).toList();
    if (repeated.isNotEmpty) {
      techniques['Wiederholung'] = min(repeated.length * 12.0, 65.0);
      warnings.add('${repeated.length} Schlüsselwörter wiederholt (Konditionierung)');
      manipulationTactics.add('Repetition: Wiederholung zur Glaubwürdigkeitserzeugung');
    }
    
    // URGENCY & CALL TO ACTION
    final urgencyWords = ['sofort', 'jetzt', 'heute', 'schnell', 'unverzüglich', 'dringend'];
    int urgencyCount = 0;
    for (var word in urgencyWords) {
      if (text.toLowerCase().contains(word)) urgencyCount++;
    }
    if (urgencyCount > 0) {
      techniques['Dringlichkeit'] = min(urgencyCount * 18.0, 70.0);
      warnings.add('Erzeugt künstliche Dringlichkeit ($urgencyCount Instanzen)');
      manipulationTactics.add('Scarcity Principle: Druckaufbau durch Zeitknappheit');
    }
    
    // SENTIMENT ANALYSIS
    final positiveWords = text.toLowerCase().split(' ').where((w) => 
      ['gut', 'besser', 'toll', 'super', 'fantastisch', 'wunderbar'].contains(w)
    ).length;
    final negativeWords = text.toLowerCase().split(' ').where((w) => 
      ['schlecht', 'böse', 'falsch', 'schrecklich', 'furchtbar', 'katastrophal'].contains(w)
    ).length;
    
    final sentiment = {
      'positive': positiveWords,
      'negative': negativeWords,
      'ratio': negativeWords > 0 ? positiveWords / negativeWords : positiveWords.toDouble(),
    };
    
    // CALCULATE OVERALL BIAS SCORE
    double biasScore = 0;
    int techniqueCount = 0;
    
    techniques.forEach((key, value) {
      if (key != 'Quellenangabe') {
        biasScore += value;
        techniqueCount++;
      }
    });
    
    if (techniqueCount > 0) {
      biasScore = (biasScore / techniqueCount).clamp(0, 100);
    }
    
    // Adjust for source presence
    if (hasSource) {
      biasScore = (biasScore * 0.85).clamp(0, 100);
    }
    
    // Adjust for emotional density
    final emotionalDensity = emotionalWords.length / max(text.split(' ').length / 10, 1);
    if (emotionalDensity > 2) {
      biasScore = min(biasScore + 15, 100);
    }
    
    // VERDICT DETERMINATION
    String verdict;
    Color verdictColor;
    
    if (biasScore < 25) {
      verdict = 'Neutral & Faktisch';
      verdictColor = const Color(0xFF4CAF50);
      if (manipulationTactics.isEmpty) {
        manipulationTactics.add('✓ Keine signifikanten Manipulationstechniken erkannt');
      }
    } else if (biasScore < 45) {
      verdict = 'Leicht Manipulativ';
      verdictColor = const Color(0xFF8BC34A);
      warnings.add('Moderate Verwendung persuasiver Techniken');
    } else if (biasScore < 65) {
      verdict = 'Manipulativ';
      verdictColor = const Color(0xFFFF9800);
      warnings.add('Klare Absicht der Meinungsbeeinflussung');
    } else if (biasScore < 80) {
      verdict = 'Stark Manipulativ';
      verdictColor = const Color(0xFFFF5722);
      warnings.add('Aggressive Propaganda-Techniken erkannt');
    } else {
      verdict = 'Extreme Propaganda';
      verdictColor = const Color(0xFFF44336);
      warnings.add('WARNUNG: Hochgradig manipulativer Inhalt');
    }
    
    return PropagandaAnalysis(
      text: text,
      biasScore: biasScore,
      techniques: techniques,
      emotionalWords: emotionalWords,
      warnings: warnings,
      verdict: verdict,
      verdictColor: verdictColor,
      sources: sources,
      sentiment: sentiment,
      manipulationTactics: manipulationTactics,
    );
  }
}
