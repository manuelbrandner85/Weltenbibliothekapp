/// WELTENBIBLIOTHEK v5.13 – KANINCHENBAU-SERVICE
/// 
/// Backend-Integration für automatische Tiefenrecherche
library;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rabbit_hole_models.dart';

class RabbitHoleService {
  final String workerUrl;
  final Duration timeout;
  
  /// Controller für Abbruch
  bool _isCancelled = false;

  RabbitHoleService({
    this.workerUrl = 'https://recherche-engine.brandy13062.workers.dev',
    this.timeout = const Duration(seconds: 30),
  });

  /// Bricht laufende Recherche ab
  void cancelResearch() {
    _isCancelled = true;
  }

  /// Startet Kaninchenbau-Recherche
  /// 
  /// Features:
  /// - Jede Ebene unabhängig
  /// - Kein Ergebnis → nächste Ebene trotzdem möglich
  /// - KI nur als Fallback pro Ebene
  /// - Abbruch jederzeit möglich
  Future<RabbitHoleAnalysis> startRabbitHole({
    required String topic,
    RabbitHoleConfig config = RabbitHoleConfig.standard,
    void Function(RabbitHoleEvent)? onEvent,
  }) async {
    // Reset cancel flag
    _isCancelled = false;
    
    final startTime = DateTime.now();
    final nodes = <RabbitHoleNode>[];

    try {
      // Event: Start
      onEvent?.call(RabbitHoleStarted(topic));

      // Durchlaufe alle Ebenen
      for (final level in config.enabledLevels) {
        // Prüfe Abbruch
        if (_isCancelled) {
          onEvent?.call(RabbitHoleError('Recherche vom Benutzer abgebrochen', level));
          break;
        }

        if (level.depth > config.maxDepth) break;

        try {
          // Recherchiere Ebene (mit Fehlertoleranz)
          final node = await _exploreLevel(
            topic: topic,
            level: level,
            previousNodes: nodes,
            onEvent: onEvent,
          );

          nodes.add(node);

          // Event: Ebene abgeschlossen
          onEvent?.call(RabbitHoleLevelCompleted(level, node));

          // Warte vor nächster Ebene (optional)
          if (config.autoProgress && level.next != null) {
            await Future.delayed(config.delayBetweenLevels);
          }
        } catch (e) {
          // Event: Fehler auf Ebene
          onEvent?.call(RabbitHoleError('Fehler auf ${level.label}: $e', level));
          
          // 🆕 WICHTIG: Fahre mit nächster Ebene fort (keine Abhängigkeit)
          // Füge leeren Platzhalter-Node hinzu, um Ebene zu markieren
          nodes.add(RabbitHoleNode(
            level: level,
            title: '${level.label} - Keine Ergebnisse',
            content: 'Recherche für diese Ebene fehlgeschlagen oder keine Daten verfügbar.',
            sources: [],
            keyFindings: ['Ebene übersprungen aufgrund fehlender Daten'],
            timestamp: DateTime.now(),
            trustScore: 0,
            isFallback: true,
          ));
          
          // Fahre mit nächster Ebene fort
          continue;
        }
      }

      final analysis = RabbitHoleAnalysis(
        topic: topic,
        nodes: nodes,
        status: nodes.length >= config.maxDepth 
            ? RabbitHoleStatus.completed 
            : RabbitHoleStatus.idle,
        startTime: startTime,
        endTime: DateTime.now(),
        maxDepth: config.maxDepth,
      );

      // Event: Abgeschlossen
      onEvent?.call(RabbitHoleCompleted(analysis));

      return analysis;
    } catch (e) {
      // Event: Fehler
      onEvent?.call(RabbitHoleError('Kaninchenbau fehlgeschlagen: $e'));

      return RabbitHoleAnalysis(
        topic: topic,
        nodes: nodes,
        status: RabbitHoleStatus.error,
        startTime: startTime,
        endTime: DateTime.now(),
        maxDepth: config.maxDepth,
        errorMessage: e.toString(),
      );
    }
  }

  /// Erkundet eine einzelne Ebene
  /// 
  /// 🆕 Features:
  /// - Versucht zuerst externe Recherche
  /// - KI-Fallback bei fehlenden Ergebnissen
  /// - Jede Ebene unabhängig von vorherigen
  Future<RabbitHoleNode> _exploreLevel({
    required String topic,
    required RabbitHoleLevel level,
    required List<RabbitHoleNode> previousNodes,
    void Function(RabbitHoleEvent)? onEvent,
  }) async {
    // Erstelle kontextuellen Prompt basierend auf Ebene
    final prompt = _buildLevelPrompt(topic, level, previousNodes);

    try {
      // 🆕 QUELLEN-ORCHESTRIERUNG: 6 Cluster seriell abfragen
      // Cluster werden NACHEINANDER (nicht parallel) abgefragt für Stabilität
      onEvent?.call(RabbitHoleError('🔍 Starte Quellen-Orchestrierung für ${level.label}...', level));
      
      final allSources = <String>[];
      final allKeyFindings = <String>[];
      final clusterResults = <String, dynamic>{};
      var totalTrustScore = 0;
      var clusterCount = 0;
      
      // CLUSTER A: Klassische Medien (BBC, NY Times, Der Spiegel, etc.)
      onEvent?.call(RabbitHoleError('📰 Cluster A: Klassische Medien...', level));
      final clusterA = await _querySourceCluster(
        prompt: prompt,
        cluster: 'classic_media',
        level: level.depth,
        context: previousNodes,
      );
      if (clusterA != null && clusterA['sources'].isNotEmpty) {
        allSources.addAll(List<String>.from(clusterA['sources']));
        allKeyFindings.addAll(List<String>.from(clusterA['key_findings'] ?? []));
        clusterResults['classic_media'] = clusterA['sources'].length;
        totalTrustScore += (clusterA['trust_score'] ?? 70) as int;
        clusterCount++;
        onEvent?.call(RabbitHoleError('  ✓ ${clusterA['sources'].length} Quellen aus klassischen Medien', level));
      }
      
      // CLUSTER B: Alternative Medien (Blogs, Independent, etc.)
      onEvent?.call(RabbitHoleError('🌐 Cluster B: Alternative Medien...', level));
      final clusterB = await _querySourceCluster(
        prompt: prompt,
        cluster: 'alternative_media',
        level: level.depth,
        context: previousNodes,
      );
      if (clusterB != null && clusterB['sources'].isNotEmpty) {
        allSources.addAll(List<String>.from(clusterB['sources']));
        allKeyFindings.addAll(List<String>.from(clusterB['key_findings'] ?? []));
        clusterResults['alternative_media'] = clusterB['sources'].length;
        totalTrustScore += (clusterB['trust_score'] ?? 50) as int;
        clusterCount++;
        onEvent?.call(RabbitHoleError('  ✓ ${clusterB['sources'].length} Quellen aus alternativen Medien', level));
      }
      
      // CLUSTER C: Regierungs- & Amtsquellen (Gov, CIA FOIA, etc.)
      onEvent?.call(RabbitHoleError('🏛️ Cluster C: Regierungs- & Amtsquellen...', level));
      final clusterC = await _querySourceCluster(
        prompt: prompt,
        cluster: 'government_sources',
        level: level.depth,
        context: previousNodes,
      );
      if (clusterC != null && clusterC['sources'].isNotEmpty) {
        allSources.addAll(List<String>.from(clusterC['sources']));
        allKeyFindings.addAll(List<String>.from(clusterC['key_findings'] ?? []));
        clusterResults['government_sources'] = clusterC['sources'].length;
        totalTrustScore += (clusterC['trust_score'] ?? 85) as int;
        clusterCount++;
        onEvent?.call(RabbitHoleError('  ✓ ${clusterC['sources'].length} Quellen aus Regierung/Ämtern', level));
      }
      
      // CLUSTER D: Wissenschaft & Archive (PubMed, arXiv, etc.)
      onEvent?.call(RabbitHoleError('📚 Cluster D: Wissenschaft & Archive...', level));
      final clusterD = await _querySourceCluster(
        prompt: prompt,
        cluster: 'science_archives',
        level: level.depth,
        context: previousNodes,
      );
      if (clusterD != null && clusterD['sources'].isNotEmpty) {
        allSources.addAll(List<String>.from(clusterD['sources']));
        allKeyFindings.addAll(List<String>.from(clusterD['key_findings'] ?? []));
        clusterResults['science_archives'] = clusterD['sources'].length;
        totalTrustScore += (clusterD['trust_score'] ?? 90) as int;
        clusterCount++;
        onEvent?.call(RabbitHoleError('  ✓ ${clusterD['sources'].length} Quellen aus Wissenschaft/Archiven', level));
      }
      
      // CLUSTER E: Dokumente & PDFs (Declassified docs, reports, etc.)
      onEvent?.call(RabbitHoleError('📄 Cluster E: Dokumente & PDFs...', level));
      final clusterE = await _querySourceCluster(
        prompt: prompt,
        cluster: 'documents_pdfs',
        level: level.depth,
        context: previousNodes,
      );
      if (clusterE != null && clusterE['sources'].isNotEmpty) {
        allSources.addAll(List<String>.from(clusterE['sources']));
        allKeyFindings.addAll(List<String>.from(clusterE['key_findings'] ?? []));
        clusterResults['documents_pdfs'] = clusterE['sources'].length;
        totalTrustScore += (clusterE['trust_score'] ?? 80) as int;
        clusterCount++;
        onEvent?.call(RabbitHoleError('  ✓ ${clusterE['sources'].length} Quellen aus Dokumenten/PDFs', level));
      }
      
      // CLUSTER F: Internationale Quellen (Multi-language, global)
      onEvent?.call(RabbitHoleError('🌍 Cluster F: Internationale Quellen...', level));
      final clusterF = await _querySourceCluster(
        prompt: prompt,
        cluster: 'international_sources',
        level: level.depth,
        context: previousNodes,
      );
      if (clusterF != null && clusterF['sources'].isNotEmpty) {
        allSources.addAll(List<String>.from(clusterF['sources']));
        allKeyFindings.addAll(List<String>.from(clusterF['key_findings'] ?? []));
        clusterResults['international_sources'] = clusterF['sources'].length;
        totalTrustScore += (clusterF['trust_score'] ?? 65) as int;
        clusterCount++;
        onEvent?.call(RabbitHoleError('  ✓ ${clusterF['sources'].length} Quellen aus internationalen Medien', level));
      }
      
      // Wenn Quellen aus Clustern gefunden → verwende diese
      if (allSources.isNotEmpty) {
        final avgTrustScore = clusterCount > 0 ? (totalTrustScore / clusterCount).round() : 50;
        
        onEvent?.call(RabbitHoleError('✅ Gesamt: ${allSources.length} Quellen aus $clusterCount Clustern (Trust: $avgTrustScore)', level));
        
        return RabbitHoleNode(
          level: level,
          title: level.label,
          content: '', // Content wird vom Backend gefüllt
          sources: allSources,
          keyFindings: allKeyFindings,
          metadata: {
            'cluster_results': clusterResults,
            'clusters_used': clusterCount,
            'orchestration': 'serial', // Seriell, nicht parallel
          },
          timestamp: DateTime.now(),
          trustScore: avgTrustScore,
          isFallback: false,
        );
      }
      
      // 🚫 NEUE REGEL: KI DARF NICHT MEHR AUFFÜLLEN
      // KI = Analyse-Modul ✓
      // KI ≠ Quellenlieferant ✗
      // 
      // Wenn keine externen Quellen: KEINE KI-Generierung!
      // Stattdessen: Explizite Lücke zurückgeben
      
      onEvent?.call(RabbitHoleError('❌ Keine externen Quellen für ${level.label} - LÜCKE BLEIBT', level));
      
      // ❌ KEIN KI-FALLBACK MEHR!
      // Stattdessen: Leere Node mit expliziter Lücken-Kennzeichnung
      return RabbitHoleNode(
        level: level,
        title: '${level.label} - Keine Daten verfügbar',
        content: 'Zu diesem Themenbereich liegen keine externen Quellen vor.\n\n'
                 '🚫 KI darf diese Lücke NICHT auffüllen.\n'
                 '✅ KI darf nur vorhandene Quellen analysieren und strukturieren.',
        sources: [], // ❌ KEINE erfundenen Quellen
        keyFindings: [
          '❌ Keine externen Quellen verfügbar',
          '🚫 KI-Generierung deaktiviert',
          '✅ Datenlücke transparent kommuniziert',
        ],
        metadata: {
          'gap_reason': 'no_external_sources',
          'ai_mode': 'analysis_only', // if (mode === "analysis") allowAI()
          'source_mode': 'denied',     // if (mode === "sources") denyAI()
        },
        timestamp: DateTime.now(),
        trustScore: 0, // ❌ Trust-Score 0 bei fehlenden Quellen
        isFallback: true, // Markiert als unvollständig
      );
    } catch (e) {
      // Bei Fehler: Werfe Exception, damit Ebene übersprungen wird
      throw Exception('Recherche fehlgeschlagen für ${level.label}: $e');
    }
  }

  /// 🆕 QUELLEN-CLUSTER ABFRAGE
  /// Fragt einen spezifischen Quellen-Cluster ab
  /// 
  /// 🎯 KONKRETE QUELLENARTEN (ECHT & LEGAL - NUR ÖFFENTLICH ZUGÄNGLICH):
  /// 
  /// 📰 A) MEDIEN & JOURNALISMUS (classic_media, alternative_media)
  ///   - Öffentliche Nachrichtenseiten (NY Times, BBC, Der Spiegel, Le Monde, etc.)
  ///   - Investigativ-Portale (ProPublica, Bellingcat, The Intercept, etc.)
  ///   - Internationale Presse frei zugänglich (Guardian, France24, DW, etc.)
  ///   - Langform-Artikel & Dossiers (The Atlantic, New Yorker, etc.)
  ///   - Independent Blogs & Substacks (öffentlich)
  ///   - Medium, Substack (frei zugängliche Artikel)
  /// 
  /// 🏛 B) STAAT & BEHÖRDEN (government_sources)
  ///   - Ministerien (gov.uk, .gov, bundestag.de, etc.)
  ///   - Parlamente & Ausschüsse (Senate, Bundestag, EU Parliament)
  ///   - Gesetzesdatenbanken (EUR-Lex, gesetze-im-internet.de)
  ///   - Anhörungen & Protokolle (Congressional Hearings, etc.)
  ///   - Gerichtsurteile öffentlich (Supreme Court, BVerfG, EGMR)
  ///   - FOIA-Releases (CIA FOIA, FBI Vault, etc.)
  ///   - Amtsblätter & Bulletins (Federal Register, EU Journal)
  /// 
  /// 📚 C) WISSENSCHAFT & FORSCHUNG (science_archives)
  ///   - Open-Access-Journals (PLOS, BMC, Frontiers, etc.)
  ///   - Universitätsrepositorien (Harvard Dataverse, MIT DSpace)
  ///   - Preprint-Server (arXiv, bioRxiv, SSRN, etc.)
  ///   - Studien & Metastudien (PubMed, Google Scholar)
  ///   - Forschungsdatenbanken (JSTOR Open, CORE, etc.)
  ///   - Dissertationen & Thesen (öffentlich zugänglich)
  /// 
  /// 🗄 D) ARCHIVE & HISTORIE (science_archives)
  ///   - Internet Archive / Wayback Machine
  ///   - Zeitungsarchive (öffentlich zugänglich)
  ///   - Historische Dokumente (National Archives, etc.)
  ///   - Chroniken & Zeitachsen (Timeline-Datenbanken)
  ///   - Digitalisierte Sammlungen (Library of Congress, etc.)
  ///   - Museum-Archive (öffentlich online)
  /// 
  /// 📄 E) DOKUMENTE (documents_pdfs)
  ///   - PDFs (öffentlich zugänglich)
  ///   - Whitepaper (technisch, politisch)
  ///   - Berichte (Kommissionen, Ausschüsse, Organisationen)
  ///   - Strategiepapiere (öffentlich)
  ///   - Haushalts- & Finanzberichte (Regierung, EU, etc.)
  ///   - Jahresberichte (Behörden, Organisationen)
  ///   - Untersuchungsberichte (öffentlich)
  /// 
  /// 🎥 F) AUDIO / VIDEO (NUR ÖFFENTLICH) (documents_pdfs)
  ///   - Dokumentationen (YouTube, Archive.org, öffentlich-rechtlich)
  ///   - Interviews (frei zugänglich)
  ///   - Vorträge & Lectures (MIT OpenCourseWare, TED, etc.)
  ///   - Pressekonferenzen (C-SPAN, Regierungs-Channels)
  ///   - Podcasts (öffentlich)
  ///   - Anhörungen & Hearings (Video-Archive)
  /// 
  /// 🌍 G) INTERNATIONAL (international_sources)
  ///   - Fremdsprachige Medien (El País, Haaretz, etc.)
  ///   - Internationale Organisationen (UN, WHO, OECD, etc.)
  ///   - Ausländische Regierungsseiten (gov.br, gov.in, etc.)
  ///   - Multilaterale Berichte (World Bank, IMF, etc.)
  ///   - NGO-Reports (Amnesty, HRW, etc. - öffentlich)
  ///   - Internationale Archive (Europäische Datenbanken)
  /// 
  /// ⚠️ WICHTIG:
  /// - Alles öffentlich zugänglich (kein Paywall-Breaking)
  /// - Alles legal (keine Hacks, keine Leaks)
  /// - Keine privaten/geschützten Daten
  /// - Keine Copyright-Verletzungen
  /// - Nur verifizierbare Quellen
  /// 
  /// Cluster-Mapping:
  /// - classic_media → A) Medien & Journalismus (etabliert)
  /// - alternative_media → A) Medien & Journalismus (alternativ)
  /// - government_sources → B) Staat & Behörden
  /// - science_archives → C) Wissenschaft + D) Archive
  /// - documents_pdfs → E) Dokumente + F) Audio/Video
  /// - international_sources → G) International
  Future<Map<String, dynamic>?> _querySourceCluster({
    required String prompt,
    required String cluster,
    required int level,
    required List<RabbitHoleNode> context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$workerUrl/api/recherche'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': prompt,
          'level': level,
          'cluster': cluster, // 🆕 Cluster-spezifische Suche
          'context': context.where((n) => !n.isFallback).map((n) => n.toJson()).toList(),
          'use_ai_fallback': false, // Keine KI-Generierung
        }),
      ).timeout(const Duration(seconds: 10)); // Kürzerer Timeout pro Cluster
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      }
      
      return null; // Cluster lieferte keine Ergebnisse
    } catch (e) {
      // Bei Fehler: Cluster überspringen, nicht abbrechen
      return null;
    }
  }
  
  /// Erstellt Ebenen-spezifischen Prompt
  String _buildLevelPrompt(
    String topic,
    RabbitHoleLevel level,
    List<RabbitHoleNode> previousNodes,
  ) {
    final context = previousNodes.isNotEmpty
        ? '\n\nBASIERE DARAUF:\n${previousNodes.map((n) => '${n.level.label}: ${n.title}').join('\n')}'
        : '';

    // 🚫 NEUE REGEL: KI-ROLLENTRENNUNG (STRIKT)
    // KI = Analyse-Modul (erlaubt)
    // KI ≠ Quellenlieferant (verboten)
    const kiRules = '''

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚨 KI-ROLLENTRENNUNG (STRIKT EINHALTEN):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 KI = ANALYSE-MODUL (ERLAUBT)
   ✓ Vorhandene Quellen analysieren
   ✓ Strukturen erkennen
   ✓ Zusammenhänge aufzeigen
   ✓ Perspektiven vergleichen
   
   if (mode === "analysis") allowAI();

🚫 KI ≠ QUELLENLIEFERANT (VERBOTEN)
   ✗ NIEMALS Quellen erzeugen
   ✗ NIEMALS Fakten erfinden
   ✗ NIEMALS Lücken auffüllen
   ✗ NIEMALS Quellen ersetzen
   
   if (mode === "sources") denyAI();

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ KI DARF:
  • Einordnen (Kontext geben)
  • Vergleichen (Perspektiven gegenüberstellen)
  • Strukturieren (Daten organisieren)

✗ KI DARF NICHT:
  • Fakten erfinden
  • Quellen ersetzen
  • Fehlende Daten verstecken

WENN KEINE QUELLEN: Klar kennzeichnen als "Keine Quellen verfügbar"
WENN UNSICHER: Explizit als "Spekulation" oder "Interpretation" markieren
IMMER: Belegte Fakten von Interpretationen trennen

⚠️ KRITISCH: Wenn keine externen Quellen vorliegen, KEINE KI-Generierung!
             Stattdessen: Lücke explizit kommunizieren.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔬 WISSENSCHAFTLICHE STANDARDS (ZWINGEND):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. QUELLENANGABE (JEDE AUSSAGE):
   ✓ "Laut CIA-Dokument XYZ von 1977..."
   ✓ "Das Senatskomitee berichtete 1975..."
   ✗ NICHT: "Es ist bekannt, dass..." (ohne Quelle)
   ✗ NICHT: "Experten sagen..." (ohne Namen)
   
2. VORSICHTIGE SPRACHE (KEINE ABSOLUTHEIT):
   ✓ "Hinweise deuten darauf hin..."
   ✓ "Laut verfügbaren Dokumenten..."
   ✓ "Es gibt Belege für..."
   ✗ NICHT: "Es ist bewiesen..."
   ✗ NICHT: "Es ist eindeutig..."
   ✗ NICHT: "Zweifellos..."
   
3. WIDERSPRÜCHE BENENNEN (TRANSPARENT):
   ✓ "Quelle A sagt X, aber Quelle B widerspricht mit Y"
   ✓ "Offizielle Darstellung: [...], Alternative Sichtweise: [...]"
   ✗ NICHT: Widersprüche verschweigen
   ✗ NICHT: Nur eine Seite darstellen
   
4. DATENLÜCKEN ERKLÄREN (NICHT FÜLLEN):
   ✓ "Zu diesem Aspekt existieren keine öffentlichen Quellen"
   ✓ "Diese Daten sind bis 2030 klassifiziert"
   ✓ "Keine belastbaren Informationen verfügbar"
   ✗ NICHT: Lücken mit Spekulationen füllen
   ✗ NICHT: Fehlende Daten erfinden
   
MERKE:
• Jede Aussage → Quelle ODER "Analyse:" Präfix
• Unsicherheit explizit machen ("möglicherweise", "vermutlich")
• Wenn unklar: "Unklar" sagen, nicht raten
• Quellenkonflikte offen darstellen
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';

    switch (level) {
      case RabbitHoleLevel.ereignis:
        return '''EBENE 1: EREIGNIS / THEMA
        
Analysiere das Kern-Ereignis: "$topic"

FOKUS:
- Was ist passiert?
- Wann und wo fand es statt?
- Welche Fakten sind belegt?
- Welche Quellen dokumentieren es?

$context

$kiRules''';

      case RabbitHoleLevel.akteure:
        return '''EBENE 2: BETEILIGTE AKTEURE
        
Thema: "$topic"

FOKUS:
- Wer waren die Hauptakteure?
- Welche Rollen hatten sie?
- Welche Motivationen hatten sie?
- Welche Verbindungen bestehen zwischen ihnen?

$context

$kiRules''';

      case RabbitHoleLevel.organisationen:
        return '''EBENE 3: ORGANISATIONEN & NETZWERKE
        
Thema: "$topic"

FOKUS:
- Welche Organisationen waren beteiligt?
- Welche Netzwerke existierten?
- Wie waren diese strukturiert?
- Welche offiziellen/inoffiziellen Verbindungen bestehen?

$context

$kiRules''';

      case RabbitHoleLevel.geldfluss:
        return '''EBENE 4: GELDFLÜSSE & INTERESSEN
        
Thema: "$topic"

FOKUS:
- Wer finanzierte was?
- Welche wirtschaftlichen Interessen bestanden?
- Welche Geldflüsse sind nachweisbar?
- Cui bono - wer profitierte?

$context

$kiRules''';

      case RabbitHoleLevel.kontext:
        return '''EBENE 5: HISTORISCHER KONTEXT
        
Thema: "$topic"

FOKUS:
- Welcher historische Kontext bestand?
- Welche Vorgeschichte ist relevant?
- Welche parallelen Ereignisse gab es?
- Welche langfristigen Entwicklungen führten hierher?

$context

$kiRules''';

      case RabbitHoleLevel.metastruktur:
        return '''EBENE 6: METASTRUKTUREN & NARRATIVE
        
Thema: "$topic"

FOKUS:
- Welche übergeordneten Strukturen werden sichtbar?
- Welche Narrative wurden geschaffen?
- Welche Machtstrukturen zeigen sich?
- Welche systemischen Muster existieren?

$context

$kiRules''';
    }
  }

  /// Lädt gespeicherten Kaninchenbau
  Future<RabbitHoleAnalysis?> loadRabbitHole(String topic) async {
    try {
      final response = await http.get(
        Uri.parse('$workerUrl/api/rabbit-hole/$topic'),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return RabbitHoleAnalysis.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Speichert Kaninchenbau
  Future<bool> saveRabbitHole(RabbitHoleAnalysis analysis) async {
    try {
      final response = await http.post(
        Uri.parse('$workerUrl/api/rabbit-hole'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(analysis.toJson()),
      ).timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
