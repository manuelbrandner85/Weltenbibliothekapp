// Investigation-Board (R6): interaktive Pinnwand mit Drag&Drop-Items,
// Verbindungen via CustomPainter, RepaintBoundary-Export als PNG.
// Persistenz ueber investigation_boards (JSONB items + connections).

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../services/invisible_auth_service.dart';
import '../../../../services/supabase_service.dart';

const _accent = Color(0xFFE53935);
const _bg = Color(0xFF0A0A0A);
const _surface = Color(0xFF1A0000);
const _canvas = Color(0xFF0D0505);

enum _ItemKind { person, organisation, event, location, document, note }

extension _ItemKindX on _ItemKind {
  String get id {
    switch (this) {
      case _ItemKind.person:
        return 'person';
      case _ItemKind.organisation:
        return 'organisation';
      case _ItemKind.event:
        return 'event';
      case _ItemKind.location:
        return 'location';
      case _ItemKind.document:
        return 'document';
      case _ItemKind.note:
        return 'note';
    }
  }

  static _ItemKind fromId(String s) {
    for (final k in _ItemKind.values) {
      if (k.id == s) return k;
    }
    return _ItemKind.note;
  }

  String get label {
    switch (this) {
      case _ItemKind.person:
        return 'Person';
      case _ItemKind.organisation:
        return 'Organisation';
      case _ItemKind.event:
        return 'Ereignis';
      case _ItemKind.location:
        return 'Ort';
      case _ItemKind.document:
        return 'Dokument';
      case _ItemKind.note:
        return 'Notiz';
    }
  }

  IconData get icon {
    switch (this) {
      case _ItemKind.person:
        return Icons.person_outline;
      case _ItemKind.organisation:
        return Icons.business_outlined;
      case _ItemKind.event:
        return Icons.event;
      case _ItemKind.location:
        return Icons.place_outlined;
      case _ItemKind.document:
        return Icons.description_outlined;
      case _ItemKind.note:
        return Icons.sticky_note_2_outlined;
    }
  }

  Color get color {
    switch (this) {
      case _ItemKind.person:
        return const Color(0xFFE53935);
      case _ItemKind.organisation:
        return const Color(0xFFFFA726);
      case _ItemKind.event:
        return const Color(0xFFAB47BC);
      case _ItemKind.location:
        return const Color(0xFF42A5F5);
      case _ItemKind.document:
        return const Color(0xFF66BB6A);
      case _ItemKind.note:
        return const Color(0xFFFFEE58);
    }
  }
}

class _BoardItem {
  final String id;
  String title;
  String? note;
  _ItemKind kind;
  Offset position;

  _BoardItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.position,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'kind': kind.id,
        'x': position.dx,
        'y': position.dy,
      };

  factory _BoardItem.fromJson(Map<String, dynamic> j) => _BoardItem(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        note: j['note'] as String?,
        kind: _ItemKindX.fromId(j['kind'] as String? ?? 'note'),
        position: Offset(
          (j['x'] as num?)?.toDouble() ?? 0,
          (j['y'] as num?)?.toDouble() ?? 0,
        ),
      );
}

class _BoardConnection {
  final String fromId;
  final String toId;
  final String? label;

  const _BoardConnection({
    required this.fromId,
    required this.toId,
    this.label,
  });

  Map<String, dynamic> toJson() => {
        'from': fromId,
        'to': toId,
        'label': label,
      };

  factory _BoardConnection.fromJson(Map<String, dynamic> j) => _BoardConnection(
        fromId: j['from'] as String? ?? '',
        toId: j['to'] as String? ?? '',
        label: j['label'] as String?,
      );
}

class InvestigationBoardScreen extends StatefulWidget {
  final String? boardId;
  const InvestigationBoardScreen({super.key, this.boardId});

  @override
  State<InvestigationBoardScreen> createState() =>
      _InvestigationBoardScreenState();
}

class _InvestigationBoardScreenState extends State<InvestigationBoardScreen> {
  static const _canvasSize = 4000.0;

  final _transform = TransformationController();
  final _canvasKey = GlobalKey();

  String? _boardId;
  String _title = 'Neue Investigation';
  String? _description;
  final List<_BoardItem> _items = [];
  final List<_BoardConnection> _connections = [];

  String? _selectedId; // selected item for connection
  String? _connectingFrom; // start of a new connection
  bool _saving = false;
  bool _loading = true;

  int _nextItemSeq = 0;

  @override
  void initState() {
    super.initState();
    _boardId = widget.boardId;
    if (_boardId != null) {
      _load();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final client = supabase;
      final res = await client
          .from('investigation_boards')
          .select()
          .eq('id', _boardId!)
          .maybeSingle();
      if (res == null) {
        setState(() => _loading = false);
        return;
      }
      final m = Map<String, dynamic>.from(res);
      final items = (m['items'] as List? ?? [])
          .map((e) => _BoardItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final conns = (m['connections'] as List? ?? [])
          .map((e) =>
              _BoardConnection.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (!mounted) return;
      setState(() {
        _title = m['title'] as String? ?? 'Investigation';
        _description = m['description'] as String?;
        _items
          ..clear()
          ..addAll(items);
        _connections
          ..clear()
          ..addAll(conns);
        _nextItemSeq = _items.length;
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Board load: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final client = supabase;
      final legacy = InvisibleAuthService().legacyUserId;
      final payload = {
        'title': _title,
        'description': _description,
        'items': _items.map((e) => e.toJson()).toList(),
        'connections': _connections.map((e) => e.toJson()).toList(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (_boardId == null) {
        payload['user_id'] = client.auth.currentUser?.id;
        payload['legacy_user_id'] =
            client.auth.currentUser == null ? legacy : null;
        final inserted = await client
            .from('investigation_boards')
            .insert(payload)
            .select('id')
            .single();
        _boardId = inserted['id'] as String?;
      } else {
        await client
            .from('investigation_boards')
            .update(payload)
            .eq('id', _boardId!);
      }
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gespeichert'), backgroundColor: _accent),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Board save: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Speichern fehlgeschlagen. Bitte erneut versuchen.')),
      );
    }
  }

  void _addItem(_ItemKind kind) {
    // Spawn near canvas center; light scatter so multiple items don't overlap.
    final base = Offset(_canvasSize / 2, _canvasSize / 2);
    final scatter = Offset(
      (_nextItemSeq % 4) * 40.0 - 60,
      ((_nextItemSeq ~/ 4) % 4) * 40.0 - 60,
    );
    final spawn = base + scatter;
    setState(() {
      final id =
          'item_${DateTime.now().millisecondsSinceEpoch}_${_nextItemSeq++}';
      _items.add(_BoardItem(
        id: id,
        title: kind.label,
        kind: kind,
        position: spawn,
      ));
      _selectedId = id;
    });
  }

  void _moveItem(String id, Offset delta) {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    setState(() {
      final item = _items[idx];
      item.position = item.position + delta;
    });
  }

  void _onItemTap(String id) {
    if (_connectingFrom != null && _connectingFrom != id) {
      setState(() {
        _connections.add(_BoardConnection(
          fromId: _connectingFrom!,
          toId: id,
        ));
        _connectingFrom = null;
        _selectedId = id;
      });
    } else {
      setState(() => _selectedId = id);
    }
  }

  Future<void> _editItem(_BoardItem item) async {
    final titleCtrl = TextEditingController(text: item.title);
    final noteCtrl = TextEditingController(text: item.note ?? '');
    _ItemKind selectedKind = item.kind;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: _surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: const EdgeInsets.all(20),
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
                const Text('Element bearbeiten',
                    style: TextStyle(
                        color: _accent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Titel'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: _inputDecoration('Notiz'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: _ItemKind.values.map((k) {
                    final sel = selectedKind == k;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(k.icon, size: 14, color: k.color),
                          const SizedBox(width: 4),
                          Text(k.label),
                        ],
                      ),
                      selected: sel,
                      onSelected: (_) => setSheet(() => selectedKind = k),
                      backgroundColor: _canvas,
                      selectedColor: k.color.withValues(alpha: 0.3),
                      side: BorderSide(
                          color: sel
                              ? k.color
                              : Colors.white.withValues(alpha: 0.2)),
                      labelStyle: TextStyle(
                        color: sel ? Colors.white : Colors.white70,
                        fontSize: 11,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent)),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Loeschen'),
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white),
                        icon: const Icon(Icons.check),
                        label: const Text('Speichern'),
                        onPressed: () => Navigator.pop(ctx, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) {
      setState(() {
        item.title = titleCtrl.text.trim().isEmpty
            ? selectedKind.label
            : titleCtrl.text.trim();
        item.note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
        item.kind = selectedKind;
      });
    } else if (ok == false) {
      setState(() {
        _connections
            .removeWhere((c) => c.fromId == item.id || c.toId == item.id);
        _items.removeWhere((e) => e.id == item.id);
        if (_selectedId == item.id) _selectedId = null;
        if (_connectingFrom == item.id) _connectingFrom = null;
      });
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
        filled: true,
        fillColor: _canvas,
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
      );

  Future<void> _export() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      if (kIsWeb) {
        // On web, share via clipboard or just snackbar.
        await Clipboard.setData(
            ClipboardData(text: 'Board-Export: ${bytes.length} Bytes'));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auf Web: Export nicht moeglich.')),
        );
        return;
      }
      final file = XFile.fromData(
        bytes,
        name: 'investigation_$_title.png',
        mimeType: 'image/png',
      );
      await Share.shareXFiles([file], text: 'Investigation-Board: $_title');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Export: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Export fehlgeschlagen. Bitte erneut versuchen.')),
      );
    }
  }

  Future<void> _editTitle() async {
    final ctrl = TextEditingController(text: _title);
    final descCtrl = TextEditingController(text: _description ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Investigation', style: TextStyle(color: _accent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Titel'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: _inputDecoration('Beschreibung'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen',
                style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _title = ctrl.text.trim().isEmpty ? 'Investigation' : ctrl.text.trim();
        _description =
            descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: GestureDetector(
          onTap: _editTitle,
          child: Row(
            children: [
              Flexible(
                child: Text(_title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit, size: 14, color: Colors.white54),
            ],
          ),
        ),
        iconTheme: const IconThemeData(color: _accent),
        actions: [
          IconButton(
            icon: Icon(
              _connectingFrom == null ? Icons.link : Icons.link_off,
              color: _connectingFrom == null ? Colors.white70 : _accent,
            ),
            tooltip: _connectingFrom == null
                ? 'Verbindung erstellen'
                : 'Verbindung abbrechen',
            onPressed: () {
              if (_selectedId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Erst ein Element auswaehlen.')),
                );
                return;
              }
              setState(() {
                _connectingFrom = _connectingFrom == null ? _selectedId : null;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong, color: Colors.white70),
            tooltip: 'Ansicht zuruecksetzen',
            onPressed: () => _transform.value = Matrix4.identity(),
          ),
          IconButton(
            icon: const Icon(Icons.image_outlined, color: Colors.white70),
            tooltip: 'Als PNG exportieren',
            onPressed: _export,
          ),
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: _accent, strokeWidth: 2))
                : const Icon(Icons.save, color: _accent),
            tooltip: 'Speichern',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : Stack(
              children: [
                _buildCanvas(),
                if (_connectingFrom != null)
                  Positioned(
                    bottom: 80,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.2),
                        border: Border.all(color: _accent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Verbindungs-Modus: Tippe auf das Ziel-Element.',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: _loading ? null : _buildAddMenu(),
    );
  }

  Widget _buildAddMenu() {
    return PopupMenuButton<_ItemKind>(
      tooltip: 'Element hinzufuegen',
      icon: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: _accent,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      color: _surface,
      onSelected: _addItem,
      itemBuilder: (_) => _ItemKind.values
          .map((k) => PopupMenuItem(
                value: k,
                child: Row(
                  children: [
                    Icon(k.icon, color: k.color, size: 18),
                    const SizedBox(width: 10),
                    Text(k.label, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCanvas() {
    return InteractiveViewer(
      transformationController: _transform,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.25,
      maxScale: 3.0,
      child: RepaintBoundary(
        key: _canvasKey,
        child: SizedBox(
          width: _canvasSize,
          height: _canvasSize,
          child: Stack(
            children: [
              // Background grid pattern.
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(),
                ),
              ),
              // Connection lines layer.
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ConnectionsPainter(
                      items: _items,
                      connections: _connections,
                    ),
                  ),
                ),
              ),
              // Item layer.
              ..._items.map((item) {
                return _BoardItemWidget(
                  key: ValueKey(item.id),
                  item: item,
                  selected: _selectedId == item.id,
                  connectSource: _connectingFrom == item.id,
                  onTap: () => _onItemTap(item.id),
                  onDoubleTap: () => _editItem(item),
                  onDrag: (delta) => _moveItem(item.id, delta),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardItemWidget extends StatelessWidget {
  static const _itemWidth = 160.0;
  static const _itemHeight = 64.0;

  final _BoardItem item;
  final bool selected;
  final bool connectSource;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final ValueChanged<Offset> onDrag;

  const _BoardItemWidget({
    super.key,
    required this.item,
    required this.selected,
    required this.connectSource,
    required this.onTap,
    required this.onDoubleTap,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.kind.color;
    return Positioned(
      left: item.position.dx - _itemWidth / 2,
      top: item.position.dy - _itemHeight / 2,
      width: _itemWidth,
      height: _itemHeight,
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onPanUpdate: (d) => onDrag(d.delta),
        child: Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: connectSource
                  ? Colors.amber
                  : selected
                      ? color
                      : color.withValues(alpha: 0.45),
              width: connectSource ? 2.4 : (selected ? 2 : 1.2),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: selected ? 0.35 : 0.18),
                blurRadius: selected ? 10 : 6,
                spreadRadius: selected ? 1 : 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(item.kind.icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(item.note ?? item.kind.label,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = _canvas;
    canvas.drawRect(Offset.zero & size, bg);
    final p = Paint()
      ..color = _accent.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConnectionsPainter extends CustomPainter {
  final List<_BoardItem> items;
  final List<_BoardConnection> connections;

  _ConnectionsPainter({required this.items, required this.connections});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _accent.withValues(alpha: 0.6)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (final c in connections) {
      final from = items.firstWhere(
        (i) => i.id == c.fromId,
        orElse: () => _BoardItem(
          id: '',
          title: '',
          kind: _ItemKind.note,
          position: Offset.zero,
        ),
      );
      final to = items.firstWhere(
        (i) => i.id == c.toId,
        orElse: () => _BoardItem(
          id: '',
          title: '',
          kind: _ItemKind.note,
          position: Offset.zero,
        ),
      );
      if (from.id.isEmpty || to.id.isEmpty) continue;
      canvas.drawLine(from.position, to.position, paint);
      // Arrow head
      _drawArrowHead(canvas, from.position, to.position, paint);
      if (c.label != null && c.label!.isNotEmpty) {
        final mid = (from.position + to.position) / 2;
        final tp = TextPainter(
          text: TextSpan(
            text: c.label,
            style: TextStyle(
              color: _accent.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              backgroundColor: _canvas.withValues(alpha: 0.8),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, mid - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    final dir = (to - from);
    final len = dir.distance;
    if (len < 1) return;
    final unit = dir / len;
    // Step back slightly to land outside the target item.
    final tip = to - unit * 30;
    const arrowSize = 8.0;
    final left = tip -
        Offset(unit.dx * arrowSize - unit.dy * arrowSize / 2,
            unit.dy * arrowSize + unit.dx * arrowSize / 2);
    final right = tip -
        Offset(unit.dx * arrowSize + unit.dy * arrowSize / 2,
            unit.dy * arrowSize - unit.dx * arrowSize / 2);
    final fill = Paint()
      ..color = _accent.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant _ConnectionsPainter oldDelegate) =>
      oldDelegate.items != items || oldDelegate.connections != connections;
}
