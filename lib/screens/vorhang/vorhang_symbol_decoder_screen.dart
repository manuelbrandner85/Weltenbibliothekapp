// Vorhang core tool: "Symbol- & Logo-Decoder".
// Browse/search a curated catalog of symbols and logos; tap one to reveal its
// possible meanings, origin and cross-world references. The user may also
// capture/pick a photo as a visual reference to compare against the catalog
// (no on-device recognition -- the match is done by the user, honestly framed).

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/vorhang_symbols_service.dart';
import '../../services/haptic_service.dart';

class VorhangSymbolDecoderScreen extends StatefulWidget {
  const VorhangSymbolDecoderScreen({super.key});

  @override
  State<VorhangSymbolDecoderScreen> createState() =>
      _VorhangSymbolDecoderScreenState();
}

class _VorhangSymbolDecoderScreenState
    extends State<VorhangSymbolDecoderScreen> {
  static const _gold = Color(0xFFC9A84C);
  static const _bgBlack = Color(0xFF000000);
  static const _surface = Color(0xFF0D0B00);

  final _searchCtrl = TextEditingController();
  final _picker = ImagePicker();

  List<VorhangSymbol> _all = [];
  List<VorhangSymbol> _filtered = [];
  List<String> _categories = [];
  String? _activeCategory;
  String _query = '';
  bool _loading = true;
  Uint8List? _referencePhoto;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await VorhangSymbolsService.instance.fetch();
    final cats = <String>{};
    for (final s in items) {
      if (s.category != null && s.category!.isNotEmpty) cats.add(s.category!);
    }
    if (!mounted) return;
    setState(() {
      _all = items;
      _categories = cats.toList()..sort();
      _loading = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    Iterable<VorhangSymbol> items = _all;
    if (_activeCategory != null) {
      items = items.where((s) => s.category == _activeCategory);
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      items = items.where((s) =>
          s.name.toLowerCase().contains(q) ||
          (s.shortMeaning ?? '').toLowerCase().contains(q) ||
          s.keywords.any((k) => k.toLowerCase().contains(q)));
    }
    setState(() => _filtered = items.toList());
  }

  Future<void> _capture(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 1024);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _referencePhoto = bytes);
      HapticService.lightImpact();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bild konnte nicht geladen werden.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: _gold),
              title: const Text('Symbol fotografieren',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _capture(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _gold),
              title: const Text('Aus Galerie wählen',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _capture(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _openDetail(VorhangSymbol symbol) {
    HapticService.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SymbolDetailSheet(symbol: symbol),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlack,
      appBar: AppBar(
        backgroundColor: _bgBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: Text(
          'SYMBOL-DECODER',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w300,
            fontSize: 16,
            letterSpacing: 3.0,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildIntro(),
          _buildSearchBar(),
          if (_categories.isNotEmpty) _buildCategoryChips(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Waehle ein Symbol oder fotografiere es, um moegliche Bedeutungen, '
              'Herkunft und Querverweise in die anderen Welten zu sehen.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildPhotoButton(),
        ],
      ),
    );
  }

  Widget _buildPhotoButton() {
    return GestureDetector(
      onTap: _showPhotoSourceSheet,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _gold.withValues(alpha: 0.12),
          border: Border.all(color: _gold.withValues(alpha: 0.5)),
          image: _referencePhoto != null
              ? DecorationImage(
                  image: MemoryImage(_referencePhoto!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _referencePhoto == null
            ? const Icon(Icons.add_a_photo, color: _gold, size: 22)
            : null,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        cursorColor: _gold,
        onChanged: (v) {
          _query = v;
          _applyFilter();
        },
        decoration: InputDecoration(
          hintText: 'Symbol suchen ...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: const Icon(Icons.search, color: _gold),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: _gold),
                  onPressed: () {
                    _searchCtrl.clear();
                    _query = '';
                    _applyFilter();
                  },
                )
              : null,
          filled: true,
          fillColor: _surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _gold.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _gold.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _gold.withValues(alpha: 0.6)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _categoryChip(null, 'Alle'),
          for (final c in _categories) _categoryChip(c, c),
        ],
      ),
    );
  }

  Widget _categoryChip(String? value, String label) {
    final active = _activeCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) {
          setState(() => _activeCategory = value);
          _applyFilter();
        },
        backgroundColor: _surface,
        selectedColor: _gold.withValues(alpha: 0.25),
        labelStyle: TextStyle(
          color: active ? _gold : Colors.white.withValues(alpha: 0.7),
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          fontSize: 12,
        ),
        side: BorderSide(
          color: active
              ? _gold.withValues(alpha: 0.6)
              : _gold.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _gold),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off,
                color: _gold.withValues(alpha: 0.4), size: 48),
            const SizedBox(height: 12),
            Text(
              'Kein Symbol gefunden.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildSymbolTile(_filtered[i]),
    );
  }

  Widget _buildSymbolTile(VorhangSymbol s) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetail(s),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _surface,
                _gold.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: _gold.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold.withValues(alpha: 0.12),
                  border: Border.all(color: _gold.withValues(alpha: 0.35)),
                ),
                child: Text(
                  s.emoji ?? '🔎',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (s.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.category!,
                              style: const TextStyle(
                                color: _gold,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (s.shortMeaning != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        s.shortMeaning!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: _gold.withValues(alpha: 0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detail bottom sheet: full meaning breakdown + cross-world references.
class _SymbolDetailSheet extends StatelessWidget {
  final VorhangSymbol symbol;
  const _SymbolDetailSheet({required this.symbol});

  static const _gold = Color(0xFFC9A84C);
  static const _surface = Color(0xFF0D0B00);

  // Other-world accent colors for cross references.
  static const Map<String, Color> _worldColors = {
    'materie': Color(0xFF3B82F6),
    'energie': Color(0xFFA855F7),
    'vorhang': _gold,
    'ursprung': Color(0xFF00D4AA),
  };
  static const Map<String, String> _worldLabels = {
    'materie': 'Materie',
    'energie': 'Energie',
    'vorhang': 'Vorhang',
    'ursprung': 'Ursprung',
  };

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gold.withValues(alpha: 0.12),
                    border: Border.all(color: _gold.withValues(alpha: 0.4)),
                  ),
                  child: Text(symbol.emoji ?? '🔎',
                      style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symbol.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (symbol.category != null)
                        Text(
                          symbol.category!,
                          style: TextStyle(
                            color: _gold.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (symbol.meanings.isNotEmpty) ...[
              _label('MOEGLICHE BEDEUTUNGEN'),
              const SizedBox(height: 10),
              for (final m in symbol.meanings) _bullet(m),
              const SizedBox(height: 20),
            ],
            if (symbol.origin != null && symbol.origin!.isNotEmpty) ...[
              _label('HERKUNFT'),
              const SizedBox(height: 10),
              Text(
                symbol.origin!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (symbol.crossWorldRefs.isNotEmpty) ...[
              _label('QUERVERWEISE IN DIE WELTEN'),
              const SizedBox(height: 10),
              for (final entry in symbol.crossWorldRefs.entries)
                _crossRef(entry.key, entry.value),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String s) => Text(
        s,
        style: const TextStyle(
          color: _gold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 3.0,
        ),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _gold,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _crossRef(String worldKey, String text) {
    final color = _worldColors[worldKey] ?? _gold;
    final label = _worldLabels[worldKey] ?? worldKey;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
