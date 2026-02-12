import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../../services/ai_service.dart';

class ImageForensicsScreen extends StatefulWidget {
  const ImageForensicsScreen({super.key});

  @override
  State<ImageForensicsScreen> createState() => _ImageForensicsScreenState();
}

class _ImageForensicsScreenState extends State<ImageForensicsScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _analysis;
  bool _isAnalyzing = false;
  String? _imageHash;
  final Map<String, Map<String, dynamic>> _analysisCache = {};

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysis = null;
          _imageHash = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }
  
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
          _analysis = null;
          _imageHash = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Aufnehmen: $e')),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Bild auswählen')),
      );
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      // Hash berechnen
      final bytes = await _selectedImage!.readAsBytes();
      final currentHash = md5.convert(bytes).toString();
      
      // Cache prüfen
      if (_analysisCache.containsKey(currentHash)) {
        setState(() {
          _analysis = _analysisCache[currentHash];
          _imageHash = currentHash;
          _isAnalyzing = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Bereits analysiert - Cache verwendet'),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      // Zeige Fortschritt
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('🤖 KI analysiert: EXIF • ELA • Klonen • Deep Fake • Splicing...'),
              ],
            ),
            duration: Duration(seconds: 45),
            backgroundColor: Color(0xFF2196F3),
          ),
        );
      }
      
      // ECHTE KI-ANALYSE
      final base64Image = base64Encode(bytes);
      final result = await AIService.analyzeImage(base64Image);
      
      // Cache speichern
      _analysisCache[currentHash] = result;
      
      setState(() {
        _analysis = result;
        _imageHash = currentHash;
        _isAnalyzing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        if (result['isLocalFallback'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ KI-Worker nicht erreichbar - Offline-Analyse'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Echte KI-Analyse abgeschlossen'),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
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
                            'IMAGE FORENSICS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '🤖 KI analysiert Manipulation & Deep Fakes',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'ECHT',
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
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_user, color: Colors.green, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Echte KI-Forensik via Cloudflare AI Workers. Jedes Bild wird individuell analysiert - keine simulierten Daten!',
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
                      
                      // Upload Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Galerie'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _takePhoto,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Kamera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (_selectedImage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _imageHash != null 
                                    ? 'Bild analysiert (ID: ${_imageHash!.substring(0, 8)}...)'
                                    : 'Bild ausgewählt - Bereit zur Analyse',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                                onPressed: () => setState(() {
                                  _selectedImage = null;
                                  _imageHash = null;
                                  _analysis = null;
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      // Analyze Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isAnalyzing ? null : _analyzeImage,
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
                                      '🤖 Echte KI analysiert...',
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
                                      'Mit Echter KI Analysieren',
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
    
    final bool isOffline = _analysis!['isLocalFallback'] == true;
    
    return Column(
      children: [
        // Status Badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isOffline 
                ? Colors.orange.withValues(alpha: 0.2)
                : Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOffline ? Colors.orange : Colors.green,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isOffline ? Icons.cloud_off : Icons.verified,
                color: isOffline ? Colors.orange : Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOffline ? 'OFFLINE-MODUS' : 'ECHTE KI-ANALYSE',
                      style: TextStyle(
                        color: isOffline ? Colors.orange : Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOffline 
                        ? 'KI-Worker nicht erreichbar - Bitte später versuchen'
                        : 'Cloudflare AI Workers • 8 forensische Tests',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Raw JSON Response
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.code, color: Color(0xFF2196F3), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'KI-ANALYSE ROHDATEN (JSON)',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(_analysis),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
