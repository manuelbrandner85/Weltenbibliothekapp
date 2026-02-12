/// 📁 EPSTEIN FILES - GOVERNMENT RESEARCH TOOL
/// 
/// Funktionalität:
/// - Lädt offiziell veröffentlichte Epstein-Dokumente von justice.gov
/// - PDF-Download und In-App-Anzeige mit Übersetzungsfunktion
/// - Vollständiger Zugriff auf die Epstein Document Library
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:translator/translator.dart';
import 'dart:io';

class EpsteinFilesSimpleScreen extends StatefulWidget {
  const EpsteinFilesSimpleScreen({super.key});

  @override
  State<EpsteinFilesSimpleScreen> createState() => _EpsteinFilesSimpleScreenState();
}

class _EpsteinFilesSimpleScreenState extends State<EpsteinFilesSimpleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  late WebViewController _jmailWebViewController;
  bool _translateEnabled = false; // 🌐 Übersetzung AN/AUS
  
  // PDF Viewing State entfernt - Dokumenten-Archiv wurde gelöscht
  // (Code bleibt für potenzielle zukünftige Nutzung)
  bool _showPdfViewer = false;
  String? _currentPdfUrl;
  Uint8List? _currentPdfBytes;
  String? _extractedText;
  String? _translatedText;
  bool _isTranslating = false;
  bool _isLoadingPdf = false;
  
  final GoogleTranslator _translator = GoogleTranslator();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this); // NUR 1 TAB: Epstein Files (JMail)
    _initJmailWebView(); // KORRIGIERT: JMail initialisieren
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _initJmailWebView() {
    _jmailWebViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (kDebugMode) {
              debugPrint('✅ Page loaded: $url');
            }
            // 🌐 Verstecke Google Translate Banner wenn Übersetzung aktiv
            if (_translateEnabled) {
              _hideGoogleTranslateBanner();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // 🌐 Nur übersetzen wenn _translateEnabled = true
            if (_translateEnabled && request.url.startsWith('http') && !request.url.contains('translate.google.com')) {
              final translatedUrl = 'https://translate.google.com/translate?sl=auto&tl=de&u=${Uri.encodeComponent(request.url)}';
              _jmailWebViewController.loadRequest(Uri.parse(translatedUrl));
              return NavigationDecision.prevent;
            }
            // Erlaube alle Navigationen
            return NavigationDecision.navigate;
          },
        ),
      )
      // 🌐 Lade JMail DIREKT (OHNE Übersetzung beim Start)
      ..loadRequest(Uri.parse('https://jmail.world/'));
  }
  
  /// 🌐 Toggle Übersetzung - Lädt Seite mit/ohne Google Translate neu
  void _toggleTranslation() {
    setState(() {
      _translateEnabled = !_translateEnabled;
    });
    
    // Lade Seite neu mit/ohne Übersetzung
    if (_translateEnabled) {
      _jmailWebViewController.loadRequest(
        Uri.parse('https://translate.google.com/translate?sl=en&tl=de&u=https://jmail.world/')
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🌐 Übersetzung aktiviert - Seite wird übersetzt'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } else {
      _jmailWebViewController.loadRequest(Uri.parse('https://jmail.world/'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🌐 Übersetzung deaktiviert - Original-Seite'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF2196F3),
        ),
      );
    }
  }
  
  /// 🌐 Verstecke Google Translate Banner - Sieht sauberer aus
  void _hideGoogleTranslateBanner() {
    final jsCode = '''
      (function() {
        // Entferne Google Translate Banner
        const banner = document.querySelector('.goog-te-banner-frame');
        if (banner) banner.style.display = 'none';
        
        // Entferne Top-Frame
        const topFrame = document.getElementById(':1.container');
        if (topFrame) topFrame.style.display = 'none';
        
        // Setze Body-Top zurück (Banner verschiebt Body nach unten)
        document.body.style.top = '0';
        document.body.style.position = 'relative';
        
        console.log('✅ Google Translate Banner versteckt');
      })();
    ''';
    
    // JavaScript nach 1 Sekunde ausführen
    Future.delayed(const Duration(seconds: 1), () {
      try {
        _jmailWebViewController.runJavaScript(jsCode);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Konnte Banner nicht verstecken: $e');
        }
      }
    });
  }
  
  // PDF Handler & Dokumenten-Archiv entfernt - nicht mehr benötigt
  

  
  Future<void> _openPdfInApp(String pdfUrl) async {
    if (_isLoadingPdf) {
      if (kDebugMode) {
        debugPrint('⚠️ PDF wird bereits geladen, ignoriere Klick');
      }
      return;
    }
    
    setState(() {
      _isLoadingPdf = true;
    });
    
    try {
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('📥 PDF wird geladen...'),
              ],
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Color(0xFFD32F2F),
          ),
        );
      }
      
      final fullUrl = pdfUrl.startsWith('http') 
          ? pdfUrl 
          : 'https://www.justice.gov$pdfUrl';
      
      if (kDebugMode) {
        debugPrint('📥 Lade PDF: $fullUrl');
      }
      
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(fullUrl));
      final response = await request.close();
      
      if (response.statusCode != 200) {
        httpClient.close();
        throw Exception('PDF-Download fehlgeschlagen: ${response.statusCode}');
      }
      
      final pdfBytes = await consolidateHttpClientResponseBytes(response);
      httpClient.close();
      
      if (kDebugMode) {
        debugPrint('📄 PDF geladen: ${pdfBytes.length} bytes');
      }
      
      String extractedText;
      try {
        final pdfDoc = PdfDocument(inputBytes: pdfBytes);
        final textExtractor = PdfTextExtractor(pdfDoc);
        extractedText = textExtractor.extractText();
        pdfDoc.dispose();
        
        if (extractedText.trim().isEmpty) {
          extractedText = 'Dieses Dokument enthält keinen extrahierbaren Text.';
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Text-Extraktion fehlgeschlagen: $e');
        }
        extractedText = 'PDF konnte nicht gelesen werden. Möglicherweise ist es gescannt oder verschlüsselt.';
      }
      
      if (kDebugMode) {
        debugPrint('📄 Text extrahiert: ${extractedText.length} Zeichen');
      }
      
      setState(() {
        _showPdfViewer = true;
        _currentPdfUrl = pdfUrl;
        _currentPdfBytes = pdfBytes;
        _extractedText = extractedText;
        _translatedText = null;
        _isLoadingPdf = false;
      });
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Fehler beim PDF-Laden: $e');
      }
      
      setState(() {
        _isLoadingPdf = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler beim PDF-Laden: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _openPdfInApp(pdfUrl),
            ),
          ),
        );
      }
    }
  }
  
  Future<void> _translatePdf() async {
    if (_extractedText == null || _extractedText!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Kein Text zum Übersetzen gefunden'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isTranslating = true;
    });
    
    try {
      if (kDebugMode) {
        debugPrint('🌐 Übersetze ${_extractedText!.length} Zeichen...');
      }
      
      String translatedText = '';
      const chunkSize = 4000;
      final chunks = <String>[];
      for (int i = 0; i < _extractedText!.length; i += chunkSize) {
        final end = (i + chunkSize < _extractedText!.length) 
            ? i + chunkSize 
            : _extractedText!.length;
        chunks.add(_extractedText!.substring(i, end));
      }
      
      if (kDebugMode) {
        debugPrint('📦 Übersetze ${chunks.length} Abschnitte');
      }
      
      for (int i = 0; i < chunks.length; i++) {
        final translation = await _translator.translate(
          chunks[i],
          from: 'en',
          to: 'de',
        );
        
        translatedText += translation.text;
        
        if (i < chunks.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      setState(() {
        _translatedText = translatedText;
      });
      
      if (kDebugMode) {
        debugPrint('✅ Übersetzung abgeschlossen');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Übersetzung abgeschlossen!'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Übersetzungsfehler: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Übersetzungsfehler: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _translatePdf,
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }
  
  void _closePdfViewer() {
    setState(() {
      _showPdfViewer = false;
      _currentPdfUrl = null;
      _currentPdfBytes = null;
      _extractedText = null;
      _translatedText = null;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          _showPdfViewer ? 'PDF ANSICHT' : 'GOVERNMENT RESEARCH',
          style: const TextStyle(letterSpacing: 2),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        leading: _showPdfViewer
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _closePdfViewer,
                tooltip: 'Zurück',
              )
            : null,
        bottom: _showPdfViewer 
            ? null 
            : TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFD32F2F),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.folder_special),
                    text: 'EPSTEIN FILES',
                  ),
                ],
              ),
        actions: [
          if (!_showPdfViewer) ...[
            // 🌐 Übersetzungs-Toggle Button
            IconButton(
              icon: Icon(
                _translateEnabled ? Icons.translate : Icons.translate_outlined,
                color: _translateEnabled ? Colors.green : Colors.white,
              ),
              onPressed: _toggleTranslation,
              tooltip: _translateEnabled ? 'Übersetzung AUS' : 'Übersetzung AN',
            ),
            // 🔄 Refresh Button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _jmailWebViewController.reload();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔄 Seite wird neu geladen...'),
                    duration: Duration(seconds: 1),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              tooltip: 'Neu laden',
            ),
          ],
        ],
      ),
      body: _showPdfViewer 
          ? _buildPdfViewer() 
          : TabBarView(
              controller: _tabController,
              children: [
                _buildJmailTab(), // Epstein Files Tab (JMail Website)
              ],
            ),
      floatingActionButton: _showPdfViewer && _extractedText != null
          ? FloatingActionButton.extended(
              onPressed: _isTranslating ? null : _translatePdf,
              backgroundColor: _isTranslating 
                  ? Colors.grey 
                  : const Color(0xFFD32F2F),
              icon: _isTranslating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.translate),
              label: Text(
                _isTranslating 
                    ? 'ÜBERSETZE...' 
                    : (_translatedText != null ? 'NEU ÜBERSETZEN' : 'INS DEUTSCHE'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            )
          : null,
    );
  }
  
  
  /// 🌐 JMail Tab (umbenannt als "Epstein Files")
  Widget _buildJmailTab() {
    return WebViewWidget(controller: _jmailWebViewController);
  }
  
  // _buildEpsteinTab entfernt - Dokumenten-Archiv wurde gelöscht
  
  Widget _buildPdfViewer() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1A1A1A),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PDF GELADEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentPdfUrl?.split('/').last ?? 'Dokument',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        if (_extractedText != null)
          DefaultTabController(
            length: 2,
            child: Expanded(
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: const Color(0xFFD32F2F),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                    tabs: const [
                      Tab(text: 'ORIGINAL (ENGLISCH)'),
                      Tab(text: 'ÜBERSETZUNG (DEUTSCH)'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTextView(_extractedText!, 'Englischer Originaltext'),
                        _translatedText != null
                            ? _buildTextView(_translatedText!, 'Deutsche Übersetzung')
                            : _buildTranslationPlaceholder(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text(
                '❌ PDF enthält keinen extrahierbaren Text\n(möglicherweise gescannt)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildTextView(String text, String hint) {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: SelectableText(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
    );
  }
  
  Widget _buildTranslationPlaceholder() {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.translate,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Noch keine Übersetzung',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Klicke auf den Button unten rechts',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const Icon(
              Icons.arrow_downward,
              color: Color(0xFFD32F2F),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
