// Research-Timeline (R1): dynamische Events aus Supabase mit Suche,
// Kategorie-Filter, Pull-to-Refresh, Pagination, FAB "Event vorschlagen".

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/research_timeline_service.dart';

class ResearchTimelineScreen extends StatefulWidget {
  const ResearchTimelineScreen({super.key});

  @override
  State<ResearchTimelineScreen> createState() => _ResearchTimelineScreenState();
}

class _ResearchTimelineScreenState extends State<ResearchTimelineScreen> {
  static const _bg = Color(0xFF0A0A0A);
  static const _surface = Color(0xFF1A0000);
  static const _accent = Color(0xFFE53935);
  static const _pageSize = 50;

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<TimelineEventV2> _events = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String _selectedCategory = 'all';

  static const _categories = <String, String>{
    'all': 'Alle',
    'conspiracy': 'Verschwörung',
    'leak': 'Leak',
    'declassified': 'Declassified',
    'corporate': 'Konzern',
    'historical': 'Historisch',
  };

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 300 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _events = [];
      _hasMore = true;
    });
    final q = _searchCtrl.text.trim();
    final list = await ResearchTimelineService.instance.fetchEvents(
      category: _selectedCategory == 'all' ? null : _selectedCategory,
      searchQuery: q.isEmpty ? null : q,
      limit: _pageSize,
      offset: 0,
    );
    if (!mounted) return;
    setState(() {
      _events = list;
      _loading = false;
      _hasMore = list.length == _pageSize;
    });
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    final q = _searchCtrl.text.trim();
    final list = await ResearchTimelineService.instance.fetchEvents(
      category: _selectedCategory == 'all' ? null : _selectedCategory,
      searchQuery: q.isEmpty ? null : q,
      limit: _pageSize,
      offset: _events.length,
    );
    if (!mounted) return;
    setState(() {
      _events.addAll(list);
      _loadingMore = false;
      _hasMore = list.length == _pageSize;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Event vorschlagen',
            style: TextStyle(color: Colors.white)),
        onPressed: _showSuggestDialog,
      ),
      body: RefreshIndicator(
        color: _accent,
        backgroundColor: _surface,
        onRefresh: _load,
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            SliverAppBar(
              backgroundColor: _bg,
              pinned: true,
              expandedHeight: 130,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                title: const Text(
                  'RESEARCH-TIMELINE',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildCategoryChips()),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child:
                    Center(child: CircularProgressIndicator(color: _accent)),
              )
            else if (_events.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Keine Events gefunden.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _events.length) {
                        if (_loadingMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: _accent)),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      return _buildItem(_events[index],
                          isLast: index == _events.length - 1 && !_hasMore);
                    },
                    childCount: _events.length + (_hasMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _load(),
        decoration: InputDecoration(
          hintText: 'Events durchsuchen ...',
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: _accent, size: 20),
          suffixIcon: _searchCtrl.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close,
                      color: Colors.white.withValues(alpha: 0.6), size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _load();
                  },
                ),
          filled: true,
          fillColor: _surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _accent.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _accent),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _categories.entries.map((e) {
          final selected = _selectedCategory == e.key;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: ChoiceChip(
              label: Text(e.value),
              selected: selected,
              onSelected: (_) {
                setState(() => _selectedCategory = e.key);
                _load();
              },
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: _surface,
              selectedColor: _accent,
              side: BorderSide(
                  color: selected ? _accent : _accent.withValues(alpha: 0.3)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItem(TimelineEventV2 event, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: event.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: event.color, width: 3),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: event.color.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: event.color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        event.dateDisplay,
                        style: TextStyle(
                          color: event.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (event.verified)
                        Icon(Icons.verified,
                            color: event.color, size: 14),
                      const Spacer(),
                      _categoryBadge(event.category, event.color),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (event.sources.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: event.sources.map((src) {
                        return InkWell(
                          onTap: () => _launchUrl(src),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: event.color.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.link,
                                    color: event.color, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'Quelle',
                                  style: TextStyle(
                                      color: event.color, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBadge(String cat, Color c) {
    final label = _categories[cat] ?? cat;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: c.withValues(alpha: 0.85),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8)),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showSuggestDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _SuggestEventForm(
          onSubmitted: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vorschlag eingereicht - danke!'),
                backgroundColor: _accent,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SuggestEventForm extends StatefulWidget {
  final VoidCallback onSubmitted;
  const _SuggestEventForm({required this.onSubmitted});

  @override
  State<_SuggestEventForm> createState() => _SuggestEventFormState();
}

class _SuggestEventFormState extends State<_SuggestEventForm> {
  static const _accent = Color(0xFFE53935);
  static const _surface = Color(0xFF1A0000);

  final _titleCtrl = TextEditingController();
  final _dateDisplayCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  DateTime _dateSort = DateTime.now();
  String _category = 'conspiracy';
  bool _submitting = false;

  static const _cats = <String, String>{
    'conspiracy': 'Verschwörung',
    'leak': 'Leak',
    'declassified': 'Declassified',
    'corporate': 'Konzern',
    'historical': 'Historisch',
  };

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dateDisplayCtrl.dispose();
    _descCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Titel und Beschreibung sind Pflichtfelder.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final sources = _sourceCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final ok = await ResearchTimelineService.instance.suggestEvent(
      title: _titleCtrl.text.trim(),
      dateDisplay: _dateDisplayCtrl.text.trim().isEmpty
          ? _dateSort.toIso8601String().substring(0, 10)
          : _dateDisplayCtrl.text.trim(),
      dateSort: _dateSort,
      description: _descCtrl.text.trim(),
      category: _category,
      sources: sources,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      widget.onSubmitted();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vorschlag konnte nicht gesendet werden.')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateSort,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dateSort = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Event vorschlagen',
            style: TextStyle(
                color: _accent, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _field(_titleCtrl, 'Titel *'),
          const SizedBox(height: 10),
          _field(_dateDisplayCtrl,
              'Datumsanzeige (z.B. "6. Juli 2019") - leer = ISO'),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(color: _accent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: _accent, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    _dateSort.toIso8601String().substring(0, 10),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _field(_descCtrl, 'Beschreibung *', maxLines: 4),
          const SizedBox(height: 10),
          _field(_sourceCtrl, 'Quellen (Komma-getrennte URLs)'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: _cats.entries.map((e) {
              final sel = _category == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: sel,
                onSelected: (_) => setState(() => _category = e.key),
                labelStyle: TextStyle(
                  color: sel ? Colors.white : Colors.white70,
                  fontSize: 11,
                ),
                backgroundColor: _surface,
                selectedColor: _accent,
                side: BorderSide(
                    color: sel ? _accent : _accent.withValues(alpha: 0.3)),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Senden',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _accent.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent),
        ),
      ),
    );
  }
}
