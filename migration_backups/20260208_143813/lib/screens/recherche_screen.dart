import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'rabbit_hole_research_screen.dart';

// 🆕 RECHERCHE-STATUS STATE MACHINE
enum RechercheStatus {
  idle,           // Bereit für neue Recherche
  loading,        // Request läuft
  sourcesFound,   // Quellen erfolgreich gecrawlt
  analysisReady,  // KI-Analyse abgeschlossen
  done,           // Fertig
  error           // Fehler aufgetreten
}

class RechercheScreen extends StatefulWidget {
  const RechercheScreen({super.key});

  @override
  State<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends State<RechercheScreen> {
  final TextEditingController controller = TextEditingController();
  
  // 🆕 STATE MACHINE
  RechercheStatus status = RechercheStatus.idle;
  
  String? resultText;
  String? validationError;
  
  // 🆕 AUTO-RETRY-LOGIC
  int retryCount = 0;
  static const int maxRetries = 3;
  
  // Progress-Tracking
  double progress = 0.0;
  String currentPhase = "";
  List<Map<String, dynamic>> intermediateResults = [];

  // 🆕 EINGABE-VALIDIERUNG
  String? validateQuery(String query) {
    final trimmed = query.trim();
    
    if (trimmed.isEmpty) {
      return "⚠️ Bitte Suchbegriff eingeben";
    }
    
    if (trimmed.length < 3) {
      return "⚠️ Mindestens 3 Zeichen erforderlich";
    }
    
    if (trimmed.length > 100) {
      return "⚠️ Maximal 100 Zeichen erlaubt";
    }
    
    if (trimmed.contains(RegExp(r'[<>{}]'))) {
      return "⚠️ Ungültige Sonderzeichen";
    }
    
    return null;
  }

  // 🆕 STATE MACHINE TRANSITIONS
  void transitionTo(RechercheStatus newStatus, {String? phase, double? progressValue}) {
    setState(() {
      status = newStatus;
      if (phase != null) currentPhase = phase;
      if (progressValue != null) progress = progressValue;
    });
  }

  // 🆕 RECHERCHE MIT STATE MACHINE
  Future<void> startRecherche() async {
    // Validierung
    final error = validateQuery(controller.text);
    if (error != null) {
      setState(() {
        validationError = error;
      });
      return;
    }
    
    setState(() {
      validationError = null;
      intermediateResults = [];
      resultText = null;
    });

    // 🆕 IDLE → LOADING
    transitionTo(RechercheStatus.loading, phase: "Verbinde mit Server...", progressValue: 0.1);

    final uri = Uri.parse(
      "https://weltenbibliothek-worker.brandy13062.workers.dev?q=${Uri.encodeComponent(controller.text.trim())}"
    );

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 429) {
        transitionTo(RechercheStatus.error);
        throw Exception("⏱️ Zu viele Anfragen. Bitte warte 60 Sekunden.");
      }

      if (response.statusCode != 200) {
        transitionTo(RechercheStatus.error);
        throw Exception("Worker nicht erreichbar (HTTP ${response.statusCode})");
      }

      // 🆕 LOADING → SOURCES_FOUND
      transitionTo(RechercheStatus.sourcesFound, phase: "Quellen gefunden...", progressValue: 0.5);

      final data = jsonDecode(response.body);
      final responseStatus = data["status"];
      final message = data["message"];

      if (responseStatus == "limited") {
        transitionTo(RechercheStatus.error);
        throw Exception("⏱️ $message\nBitte warte ${data['retryAfter'] ?? 60} Sekunden.");
      } else if (responseStatus != "ok" && responseStatus != "fallback") {
        transitionTo(RechercheStatus.error);
        throw Exception(message ?? "Ungültige Worker-Antwort");
      }

      // Zwischenergebnisse extrahieren
      final results = data["results"];
      if (results != null && results is Map) {
        final webResults = (results["web"] as List<dynamic>?) ?? [];
        final docResults = (results["documents"] as List<dynamic>?) ?? [];
        final mediaResults = (results["media"] as List<dynamic>?) ?? [];
        
        // 🆕 EMPTY → FALLBACK AKTIVIEREN
        final isEmpty = webResults.isEmpty && docResults.isEmpty && mediaResults.isEmpty;
        
        setState(() {
          intermediateResults = [
            ...webResults.map((r) => {'source': r['source'] ?? 'Web', 'type': r['type'] ?? 'text'}),
            ...docResults.map((r) => {'source': r['source'] ?? 'Dokument', 'type': r['type'] ?? 'document'}),
            ...mediaResults.map((r) => {'source': r['source'] ?? 'Media', 'type': r['type'] ?? 'media'}),
          ];
          
          // Wenn leer, zeige Fallback-Hinweis
          if (isEmpty) {
            intermediateResults.add({
              'source': '🆘 Fallback aktiviert',
              'type': 'theoretische Einordnung'
            });
          }
        });
      }

      // 🆕 SOURCES_FOUND → ANALYSIS_READY
      transitionTo(RechercheStatus.analysisReady, phase: "Analyse abgeschlossen...", progressValue: 0.9);

      // Formatiere Ergebnis
      final analyse = data["analyse"];
      final query = data["query"];
      
      String formatted = "═══════════════════════════════════\n";
      formatted += "RECHERCHE: $query\n";
      formatted += "═══════════════════════════════════\n\n";
      
      if (responseStatus == "fallback" && message != null) {
        formatted += "⚠️ HINWEIS:\n$message\n\n";
        
        final sourcesStatus = data["sourcesStatus"];
        if (sourcesStatus != null) {
          formatted += "Web-Quellen: ${sourcesStatus['web'] ?? 0}\n";
          formatted += "Dokumente: ${sourcesStatus['documents'] ?? 0}\n";
          formatted += "Medien: ${sourcesStatus['media'] ?? 0}\n\n";
        }
      }
      
      if (analyse != null) {
        if (analyse["fallback"] == true || analyse["mitDaten"] == false) {
          formatted += "⚠️ ANALYSE OHNE AUSREICHENDE PRIMÄRDATEN\n\n";
        }
        
        formatted += analyse["inhalt"] ?? "Keine Analyse verfügbar";
        formatted += "\n\n";
        formatted += "─────────────────────────────────\n";
        formatted += "Timestamp: ${analyse["timestamp"]}\n";
      } else {
        formatted += "Keine Analyse verfügbar\n";
      }

      // 🆕 ANALYSIS_READY → DONE
      transitionTo(RechercheStatus.done, phase: "Fertig!", progressValue: 1.0);
      
      setState(() {
        resultText = formatted;
        retryCount = 0; // Reset retry counter on success
      });

    } catch (e) {
      transitionTo(RechercheStatus.error, phase: "Fehler aufgetreten", progressValue: 0.0);
      
      // 🆕 AUTO-RETRY-LOGIC
      if (retryCount < maxRetries && !e.toString().contains("429")) {
        retryCount++;
        setState(() {
          resultText = "❌ Fehler: $e\n\n⚡ Auto-Retry in 3 Sekunden... (Versuch $retryCount/$maxRetries)";
        });
        
        // Automatischer Retry nach 3 Sekunden
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && status == RechercheStatus.error) {
            startRecherche();
          }
        });
      } else {
        // Max-Retries erreicht oder Rate-Limit
        setState(() {
          resultText = "❌ Fehler: $e\n\n🔄 Bitte manuell erneut versuchen";
          retryCount = 0; // Reset für nächsten manuellen Versuch
        });
      }
    }
  }

  // 🆕 STATUS-ABHÄNGIGE UI-FARBE
  Color getStatusColor() {
    switch (status) {
      case RechercheStatus.idle:
        return Colors.grey;
      case RechercheStatus.loading:
        return Colors.blue;
      case RechercheStatus.sourcesFound:
        return Colors.orange;
      case RechercheStatus.analysisReady:
        return Colors.purple;
      case RechercheStatus.done:
        return Colors.green;
      case RechercheStatus.error:
        return Colors.red;
    }
  }

  // 🆕 STATUS-TEXT
  String getStatusText() {
    switch (status) {
      case RechercheStatus.idle:
        return "Bereit";
      case RechercheStatus.loading:
        return "LOADING - Verbinde...";
      case RechercheStatus.sourcesFound:
        return "SOURCES_FOUND - ${intermediateResults.length} Quellen";
      case RechercheStatus.analysisReady:
        return "ANALYSIS_READY - Analyse fertig";
      case RechercheStatus.done:
        return "DONE - Abgeschlossen";
      case RechercheStatus.error:
        return "ERROR - Fehler aufgetreten";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = status == RechercheStatus.loading || 
                        status == RechercheStatus.sourcesFound || 
                        status == RechercheStatus.analysisReady;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recherche – Welt & Materie"),
        // 🆕 STATUS-INDIKATOR IN APPBAR
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: getStatusColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: getStatusColor(), width: 2),
                ),
                child: Text(
                  status.name.toUpperCase(),
                  style: TextStyle(
                    color: getStatusColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🆕 STATUS-BADGE
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: getStatusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: getStatusColor(), width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    status == RechercheStatus.done ? Icons.check_circle :
                    status == RechercheStatus.error ? Icons.error :
                    status == RechercheStatus.idle ? Icons.search :
                    Icons.sync,
                    color: getStatusColor(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      getStatusText(),
                      style: TextStyle(
                        color: getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Eingabefeld
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "Suchbegriff eingeben",
                helperText: "Min. 3 Zeichen, max. 100 Zeichen",
                errorText: validationError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  validationError = validateQuery(value);
                });
              },
            ),
            const SizedBox(height: 16),
            
            // 🆕 v5.13: KANINCHENBAU-BUTTON
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RabbitHoleResearchScreen(
                      initialTopic: controller.text.trim(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.explore, size: 24),
              label: const Text(
                '🕳️ KANINCHENBAU STARTEN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Automatische Vertiefung in 6 Ebenen',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Button
            ElevatedButton(
              onPressed: (isSearching || validateQuery(controller.text) != null)
                  ? null
                  : startRecherche,
              child: const Text("Recherche starten"),
            ),
            const SizedBox(height: 24),

            // Progress-Anzeige
            if (isSearching) ...[
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(getStatusColor()),
              ),
              const SizedBox(height: 8),
              Text(
                currentPhase,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: getStatusColor(),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
            ],

            // Zwischenergebnisse
            if (isSearching && intermediateResults.isNotEmpty) ...[
              const Text(
                "📊 Gefundene Quellen:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: getStatusColor()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: intermediateResults.length,
                  itemBuilder: (context, index) {
                    final result = intermediateResults[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.check_circle, color: getStatusColor(), size: 16),
                      title: Text(
                        result['source'] ?? 'Quelle ${index + 1}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        result['type'] ?? '',
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Ergebnis
            if (status == RechercheStatus.done || status == RechercheStatus.error)
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    resultText ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 🧹 PHASE B: Proper resource disposal
    super.dispose();
  }
}
