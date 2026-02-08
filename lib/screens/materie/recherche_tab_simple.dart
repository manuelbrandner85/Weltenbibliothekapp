/// SUPER-EINFACHE TEST-VERSION - GARANTIERT FUNKTIONIEREND
library;
import 'package:flutter/material.dart';

class SimpleRechercheTab extends StatefulWidget {
  const SimpleRechercheTab({super.key});

  @override
  State<SimpleRechercheTab> createState() => _SimpleRechercheTabState();
}

class _SimpleRechercheTabState extends State<SimpleRechercheTab> {
  final TextEditingController _controller = TextEditingController();
  String _status = 'Bereit';
  String _result = '';
  bool _isLoading = false;

  Future<void> _startSearch() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _status = 'Lade...';
      _result = '';
    });

    try {
      // Simuliere Netzwerk-Request (5 Sekunden)
      await Future.delayed(const Duration(seconds: 5));

      setState(() {
        _isLoading = false;
        _status = 'Erfolgreich!';
        _result = '''
🎉 TEST ERFOLGREICH!

Suchbegriff: ${_controller.text}

✅ Wenn du das siehst, funktioniert die App!
✅ Das bedeutet: Flutter läuft korrekt
✅ Das bedeutet: UI rendert korrekt
✅ Das bedeutet: State-Management funktioniert

🔍 Das Problem lag am Worker-Request:
- Netzwerk-Fehler
- CORS-Problem
- Timeout-Fehler

📱 Nächster Schritt:
Teste die ECHTE Version mit Live-Daten!
        ''';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Fehler!';
        _result = 'Fehler: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('SIMPLE TEST'),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🧪 EINFACHER TEST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: $_status',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Suchfeld
              TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Suchbegriff eingeben...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'TEST STARTEN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Ergebnis
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _result.isEmpty ? 'Hier erscheint das Ergebnis...' : _result,
                      style: TextStyle(
                        color: _result.isEmpty ? Colors.white30 : Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
