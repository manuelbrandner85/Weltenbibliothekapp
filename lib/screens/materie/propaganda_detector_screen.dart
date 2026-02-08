import 'package:flutter/material.dart';
import '../../services/ai_service.dart';

class PropagandaDetectorScreen extends StatefulWidget {
  const PropagandaDetectorScreen({super.key});

  @override
  State<PropagandaDetectorScreen> createState() => _PropagandaDetectorScreenState();
}

class _PropagandaDetectorScreenState extends State<PropagandaDetectorScreen> with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  Map<String, dynamic>? _analysis;
  bool _isAnalyzing = false;
  late AnimationController _pulseController;
  final bool _useAI = true; // Toggle für KI vs Lokale Analyse

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _analyze() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Text eingeben')),
      );
      return;
    }
    
    setState(() => _isAnalyzing = true);
    
    try {
      // 🤖 ECHTE KI-ANALYSE mit Cloudflare AI Workers
      final result = await AIService.analyzePropaganda(_textController.text);
      
      setState(() {
        _analysis = result;
        _isAnalyzing = false;
      });
      
      if (mounted && result['isLocalFallback'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ KI-Worker offline - Lokale Analyse verwendet'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Color(0xFF1A1A1A), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PROPAGANDA DETECTOR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '🤖 KI-gestützte Alternative Perspektive',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.psychology, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'KI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'KI analysiert aus alternativer/kritischer Perspektive und erkennt Mainstream-Propaganda-Techniken',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Input Field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          maxLines: 10,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Nachrichtenartikel, Social Media Post oder politische Rede hier einfügen...\n\nBeispiel:\n"Die Regierung hat heute verkündet, dass die neuen Maßnahmen alternativlos sind..."',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(20),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Analyze Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isAnalyzing ? null : _analyze,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isAnalyzing
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      '🤖 KI analysiert...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.psychology, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Mit KI Analysieren',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      
                      if (_analysis != null) ...[
                        const SizedBox(height: 32),
                        
                        // Results werden angezeigt
                        _buildResults(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_analysis == null) return const SizedBox.shrink();
    
    final biasScore = (_analysis!['biasScore'] as num?)?.toDouble() ?? 0.0;
    final verdict = _analysis!['verdict'] as String? ?? 'Unbekannt';
    final isLocalFallback = _analysis!['isLocalFallback'] == true;
    
    Color verdictColor;
    if (biasScore < 25) {
      verdictColor = const Color(0xFF4CAF50);
    } else if (biasScore < 50) {
      verdictColor = const Color(0xFF8BC34A);
    } else if (biasScore < 70) {
      verdictColor = const Color(0xFFFF9800);
    } else {
      verdictColor = const Color(0xFFF44336);
    }
    
    return Column(
      children: [
        // Main Score Card
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    verdictColor.withValues(alpha: 0.3 + (_pulseController.value * 0.1)),
                    verdictColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: verdictColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: verdictColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (isLocalFallback)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '⚠️ OFFLINE-MODUS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    '${biasScore.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: verdictColor,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'PROPAGANDA-SCORE',
                    style: TextStyle(
                      color: verdictColor.withValues(alpha: 0.8),
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: verdictColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      verdict.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        // Weitere Details (wenn vorhanden)
        if (_analysis!['techniques'] != null) ...[
          const SizedBox(height: 24),
          _buildSection(
            '🎭 ERKANNTE TECHNIKEN',
            (_analysis!['techniques'] as Map).entries
                .map((e) => '${e.key}: ${(e.value as num).toStringAsFixed(0)}%')
                .toList(),
            Colors.blue,
          ),
        ],
        
        if (_analysis!['warnings'] != null && (_analysis!['warnings'] as List).isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSection(
            '⚠️ WARNUNGEN',
            List<String>.from(_analysis!['warnings']),
            Colors.orange,
          ),
        ],
      ],
    );
  }

  Widget _buildSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
