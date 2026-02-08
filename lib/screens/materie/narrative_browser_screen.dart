import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/category_widgets.dart';
import 'narrative_detail_screen.dart';

class NarrativeBrowserScreen extends StatefulWidget {
  const NarrativeBrowserScreen({super.key});

  @override
  State<NarrativeBrowserScreen> createState() => _NarrativeBrowserScreenState();
}

class _NarrativeBrowserScreenState extends State<NarrativeBrowserScreen> {
  static const String _backendUrl = 'https://api-backend.brandy13062.workers.dev';
  
  List<NarrativeCategory> _categories = [];
  List<Map<String, dynamic>> _narratives = [];
  String? _selectedCategoryId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load categories
      final catResponse = await http.get(Uri.parse('$_backendUrl/api/categories'));
      if (catResponse.statusCode == 200) {
        final catData = jsonDecode(catResponse.body);
        _categories = (catData['categories'] as List)
            .map((c) => NarrativeCategory.fromJson(c))
            .toList();
      }
      
      // Load narratives
      await _loadNarratives();
      
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNarratives() async {
    try {
      String url = '$_backendUrl/api/narratives';
      if (_selectedCategoryId != null) {
        url += '?category=$_selectedCategoryId';
      }
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _narratives = List<Map<String, dynamic>>.from(data['narratives']);
        });
      }
    } catch (e) {
      debugPrint('Error loading narratives: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗂️ Alternative Narrative'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                CategoryFilterChips(
                  categories: _categories,
                  selectedCategoryId: _selectedCategoryId,
                  onCategorySelected: (categoryId) {
                    setState(() => _selectedCategoryId = categoryId);
                    _loadNarratives();
                  },
                ),
                Expanded(
                  child: _narratives.isEmpty
                      ? const Center(child: Text('Keine Narrative gefunden'))
                      : ListView.builder(
                          itemCount: _narratives.length,
                          itemBuilder: (context, index) {
                            final narrative = _narratives[index];
                            return NarrativeCard(
                              narrative: narrative,
                              onTap: () => _showNarrativeDetail(narrative),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showNarrativeDetail(Map<String, dynamic> narrative) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NarrativeDetailScreen(
          narrativeId: narrative['id'] as String,
          narrativeTitle: narrative['title'] as String,
        ),
      ),
    );
  }
}
