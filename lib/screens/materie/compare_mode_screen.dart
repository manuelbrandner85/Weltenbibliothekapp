import 'package:flutter/material.dart';
import '../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import 'package:flutter/services.dart';
import '../../services/backend_recherche_service.dart';

/// Professional Compare Mode Screen v7.5
/// 
/// Features:
/// - Split-Screen mit Sync-Scrolling
/// - Highlight-Unterschiede
/// - Quellen-Vergleich
/// - Multimedia-Vergleich
/// - Export-Funktion
class CompareModeScreen extends StatefulWidget {
  final InternetSearchResult? result1;
  final InternetSearchResult? result2;

  const CompareModeScreen({
    super.key,
    this.result1,
    this.result2,
  });

  @override
  State<CompareModeScreen> createState() => _CompareModeScreenState();
}

class _CompareModeScreenState extends State<CompareModeScreen> with TickerProviderStateMixin {
  final BackendRechercheService _searchService = BackendRechercheService();
  final ScrollController _scrollController1 = ScrollController();
  final ScrollController _scrollController2 = ScrollController();
  
  InternetSearchResult? _result1;
  InternetSearchResult? _result2;
  bool _isLoading1 = false;
  bool _isLoading2 = false;
  bool _syncScrolling = true;
  CompareMode _currentMode = CompareMode.sideBySide;
  
  late TabController _tabController;
  final TextEditingController _query1Controller = TextEditingController();
  final TextEditingController _query2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _result1 = widget.result1;
    _result2 = widget.result2;
    _tabController = TabController(length: 4, vsync: this);
    
    if (_result1 != null) {
      _query1Controller.text = _result1!.query;
    }
    if (_result2 != null) {
      _query2Controller.text = _result2!.query;
    }
    
    // Sync scrolling setup
    _scrollController1.addListener(_onScroll1);
    _scrollController2.addListener(_onScroll2);
  }

  @override
  void dispose() {
    _scrollController1.dispose();
    _scrollController2.dispose();
    _tabController.dispose();
    _query1Controller.dispose();
    _query2Controller.dispose();
    super.dispose();
  }

  bool _isScrolling1 = false;
  bool _isScrolling2 = false;

  void _onScroll1() {
    if (_syncScrolling && !_isScrolling2 && _scrollController1.hasClients && _scrollController2.hasClients) {
      _isScrolling1 = true;
      _scrollController2.jumpTo(_scrollController1.offset);
      _isScrolling1 = false;
    }
  }

  void _onScroll2() {
    if (_syncScrolling && !_isScrolling1 && _scrollController1.hasClients && _scrollController2.hasClients) {
      _isScrolling2 = true;
      _scrollController1.jumpTo(_scrollController2.offset);
      _isScrolling2 = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildControlBar(),
          Expanded(
            child: _buildCompareView(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Row(
        children: [
          Icon(Icons.compare_arrows, color: Colors.purple, size: 24),
          SizedBox(width: 12),
          Text('⚖️ Vergleichsmodus'),
        ],
      ),
      actions: [
        // Sync Toggle
        IconButton(
          icon: Icon(
            _syncScrolling ? Icons.sync : Icons.sync_disabled,
            color: _syncScrolling ? Colors.cyan : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _syncScrolling = !_syncScrolling;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _syncScrolling ? '✅ Sync-Scrolling aktiviert' : '❌ Sync-Scrolling deaktiviert',
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          tooltip: 'Sync-Scrolling',
        ),
        
        // View Mode
        PopupMenuButton<CompareMode>(
          icon: const Icon(Icons.view_column, color: Colors.cyan),
          onSelected: (mode) {
            setState(() {
              _currentMode = mode;
            });
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: CompareMode.sideBySide,
              child: Row(
                children: [
                  Icon(Icons.view_column, size: 20),
                  SizedBox(width: 12),
                  Text('Nebeneinander'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: CompareMode.topBottom,
              child: Row(
                children: [
                  Icon(Icons.view_agenda, size: 20),
                  SizedBox(width: 12),
                  Text('Übereinander'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: CompareMode.tabs,
              child: Row(
                children: [
                  Icon(Icons.tab, size: 20),
                  SizedBox(width: 12),
                  Text('Tabs'),
                ],
              ),
            ),
          ],
        ),
        
        // Export
        IconButton(
          icon: const Icon(Icons.download, color: Colors.cyan),
          onPressed: _exportComparison,
          tooltip: 'Vergleich exportieren',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        children: [
          // Search 1
          Expanded(
            child: _buildSearchField(
              controller: _query1Controller,
              label: 'Recherche 1',
              color: Colors.blue,
              onSearch: (query) => _performSearch(query, isFirst: true),
              isLoading: _isLoading1,
            ),
          ),
          const SizedBox(width: 16),
          
          // VS Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple),
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Search 2
          Expanded(
            child: _buildSearchField(
              controller: _query2Controller,
              label: 'Recherche 2',
              color: Colors.orange,
              onSearch: (query) => _performSearch(query, isFirst: false),
              isLoading: _isLoading2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String label,
    required Color color,
    required Function(String) onSearch,
    required bool isLoading,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color),
        filled: true,
        fillColor: Colors.grey[850],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        suffixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                icon: Icon(Icons.search, color: color),
                onPressed: () => onSearch(controller.text),
              ),
      ),
      style: const TextStyle(color: Colors.white),
      onSubmitted: onSearch,
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.purple,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.article, size: 20), text: 'Text'),
          Tab(icon: Icon(Icons.source, size: 20), text: 'Quellen'),
          Tab(icon: Icon(Icons.collections, size: 20), text: 'Multimedia'),
          Tab(icon: Icon(Icons.analytics, size: 20), text: 'Analyse'),
        ],
      ),
    );
  }

  Widget _buildCompareView() {
    if (_result1 == null && _result2 == null) {
      return _buildEmptyState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildTextComparison(),
        _buildSourcesComparison(),
        _buildMultimediaComparison(),
        _buildAnalysisView(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 24),
          Text(
            'Gib zwei Suchanfragen ein',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vergleiche verschiedene Perspektiven',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComparison() {
    switch (_currentMode) {
      case CompareMode.sideBySide:
        return Row(
          children: [
            Expanded(
              child: _buildTextPanel(
                _result1,
                Colors.blue,
                'RECHERCHE 1',
                _scrollController1,
              ),
            ),
            Container(width: 2, color: Colors.purple),
            Expanded(
              child: _buildTextPanel(
                _result2,
                Colors.orange,
                'RECHERCHE 2',
                _scrollController2,
              ),
            ),
          ],
        );
      
      case CompareMode.topBottom:
        return Column(
          children: [
            Expanded(
              child: _buildTextPanel(
                _result1,
                Colors.blue,
                'RECHERCHE 1',
                _scrollController1,
              ),
            ),
            Container(height: 2, color: Colors.purple),
            Expanded(
              child: _buildTextPanel(
                _result2,
                Colors.orange,
                'RECHERCHE 2',
                _scrollController2,
              ),
            ),
          ],
        );
      
      case CompareMode.tabs:
        return TabBarView(
          children: [
            _buildTextPanel(_result1, Colors.blue, 'RECHERCHE 1', _scrollController1),
            _buildTextPanel(_result2, Colors.orange, 'RECHERCHE 2', _scrollController2),
          ],
        );
    }
  }

  Widget _buildTextPanel(
    InternetSearchResult? result,
    Color color,
    String label,
    ScrollController scrollController,
  ) {
    if (result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'Keine Recherche',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              border: Border(bottom: BorderSide(color: color)),
            ),
            child: Row(
              children: [
                Icon(Icons.article, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.query,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  color: color,
                  onPressed: () => _copyText(result.summary),
                  tooltip: 'Text kopieren',
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                result.summary,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.8,
                ),
              ),
            ),
          ),
          
          // Footer Stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(top: BorderSide(color: Colors.grey[800]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Wörter', result.summary.split(' ').length.toString(), Icons.text_fields),
                _buildStat('Quellen', result.sources.length.toString(), Icons.source),
                if (result.multimedia != null) ...[
                  _buildStat('PDFs', (result.multimedia!['documents'] as List?)?.length.toString() ?? '0', Icons.picture_as_pdf),
                  _buildStat('Bilder', (result.multimedia!['images'] as List?)?.length.toString() ?? '0', Icons.image),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.cyan),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildSourcesComparison() {
    return Row(
      children: [
        Expanded(child: _buildSourcesList(_result1, Colors.blue)),
        Container(width: 2, color: Colors.purple),
        Expanded(child: _buildSourcesList(_result2, Colors.orange)),
      ],
    );
  }

  Widget _buildSourcesList(InternetSearchResult? result, Color color) {
    if (result == null || result.sources.isEmpty) {
      return Center(
        child: Text(
          'Keine Quellen',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: result.sources.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final source = result.sources[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                source.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                source.url,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue[300],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMultimediaComparison() {
    return Row(
      children: [
        Expanded(child: _buildMultimediaPanel(_result1, Colors.blue)),
        Container(width: 2, color: Colors.purple),
        Expanded(child: _buildMultimediaPanel(_result2, Colors.orange)),
      ],
    );
  }

  Widget _buildMultimediaPanel(InternetSearchResult? result, Color color) {
    if (result == null || result.multimedia == null) {
      return Center(
        child: Text(
          'Keine Multimedia-Inhalte',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final docs = (result.multimedia!['documents'] as List?)?.length ?? 0;
    final images = (result.multimedia!['images'] as List?)?.length ?? 0;
    final videos = (result.multimedia!['videos'] as List?)?.length ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMultimediaCard('PDFs', docs, Icons.picture_as_pdf, Colors.red),
        const SizedBox(height: 12),
        _buildMultimediaCard('Bilder', images, Icons.image, Colors.blue),
        const SizedBox(height: 12),
        _buildMultimediaCard('Videos', videos, Icons.video_library, Colors.purple),
      ],
    );
  }

  Widget _buildMultimediaCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisView() {
    if (_result1 == null || _result2 == null) {
      return Center(
        child: Text(
          'Beide Recherchen benötigt für Analyse',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final words1 = _result1!.summary.split(' ').length;
    final words2 = _result2!.summary.split(' ').length;
    final sources1 = _result1!.sources.length;
    final sources2 = _result2!.sources.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildComparisonCard(
          'Textlänge',
          'Recherche 1: $words1 Wörter',
          'Recherche 2: $words2 Wörter',
          words1 > words2 ? Colors.blue : Colors.orange,
          Icons.text_fields,
        ),
        const SizedBox(height: 16),
        _buildComparisonCard(
          'Quellenanzahl',
          'Recherche 1: $sources1 Quellen',
          'Recherche 2: $sources2 Quellen',
          sources1 > sources2 ? Colors.blue : Colors.orange,
          Icons.source,
        ),
        const SizedBox(height: 16),
        _buildComparisonCard(
          'Fazit',
          _generateComparisonSummary(),
          '',
          Colors.purple,
          Icons.analytics,
        ),
      ],
    );
  }

  Widget _buildComparisonCard(
    String title,
    String content1,
    String content2,
    Color accentColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (content1.isNotEmpty)
            Text(
              content1,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.6,
              ),
            ),
          if (content2.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              content2,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _generateComparisonSummary() {
    if (_result1 == null || _result2 == null) return '';
    
    final words1 = _result1!.summary.split(' ').length;
    final words2 = _result2!.summary.split(' ').length;
    final sources1 = _result1!.sources.length;
    final sources2 = _result2!.sources.length;
    
    final buffer = StringBuffer();
    buffer.writeln('Vergleichsergebnis:');
    buffer.writeln();
    
    if (words1 > words2) {
      buffer.writeln('✅ Recherche 1 ist umfangreicher (${((words1 / words2) * 100 - 100).toInt()}% mehr Text)');
    } else {
      buffer.writeln('✅ Recherche 2 ist umfangreicher (${((words2 / words1) * 100 - 100).toInt()}% mehr Text)');
    }
    
    if (sources1 > sources2) {
      buffer.writeln('✅ Recherche 1 hat mehr Quellen ($sources1 vs $sources2)');
    } else {
      buffer.writeln('✅ Recherche 2 hat mehr Quellen ($sources2 vs $sources1)');
    }
    
    return buffer.toString();
  }

  Future<void> _performSearch(String query, {required bool isFirst}) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      if (isFirst) {
        _isLoading1 = true;
      } else {
        _isLoading2 = true;
      }
    });
    
    try {
      final result = await _searchService.searchInternet(query);
      
      setState(() {
        if (isFirst) {
          _result1 = result;
          _isLoading1 = false;
        } else {
          _result2 = result;
          _isLoading2 = false;
        }
      });
    } catch (e) {
      setState(() {
        if (isFirst) {
          _isLoading1 = false;
        } else {
          _isLoading2 = false;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler bei Recherche: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Text kopiert'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _exportComparison() async {
    if (_result1 == null && _result2 == null) return;
    
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('WELTENBIBLIOTHEK - VERGLEICHSMODUS');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();
    
    if (_result1 != null) {
      buffer.writeln('📌 RECHERCHE 1: ${_result1!.query}');
      buffer.writeln('─' * 40);
      buffer.writeln(_result1!.summary);
      buffer.writeln();
    }
    
    if (_result2 != null) {
      buffer.writeln('📌 RECHERCHE 2: ${_result2!.query}');
      buffer.writeln('─' * 40);
      buffer.writeln(_result2!.summary);
      buffer.writeln();
    }
    
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('Erstellt: ${DateTime.now()}');
    
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 16),
              Text('Vergleich in Zwischenablage kopiert!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// Enums
enum CompareMode { sideBySide, topBottom, tabs }
