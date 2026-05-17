// Globale Suche — welt-übergreifende Suche über Chats / Profile / Module.
//
// Aufruf: `GlobalSearchSheet.open(context)`. Öffnet ein Vollbild-
// Dialog-Sheet mit Live-Suche. Debounce 300ms, parallele Queries auf
// drei Tabellen, kategorisiert dargestellt.
//
// Bewusst MVP-scope: nur Tabellen die anon-readable sind (chat_messages
// hat aktuell GRANT-ALL TO anon laut CLAUDE.md; profiles + vorhang_modules
// haben Read-Policies für authentifizierte User). Wenn der User nicht
// angemeldet ist, werden leere Resultate angezeigt.

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GlobalSearchSheet {
  static Future<void> open(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      barrierLabel: 'Suche schließen',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => const _GlobalSearchView(),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.97, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _GlobalSearchView extends StatefulWidget {
  const _GlobalSearchView();

  @override
  State<_GlobalSearchView> createState() => _GlobalSearchViewState();
}

class _GlobalSearchViewState extends State<_GlobalSearchView> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  bool _loading = false;
  List<_Hit> _profiles = const [];
  List<_Hit> _messages = const [];
  List<_Hit> _modules = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChange(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value));
  }

  Future<void> _search(String q) async {
    final query = q.trim();
    if (query.length < 2) {
      setState(() {
        _profiles = const [];
        _messages = const [];
        _modules = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);

    final supa = Supabase.instance.client;
    final like = '%${query.replaceAll('%', '').replaceAll('_', '')}%';

    Future<List<_Hit>> profilesFut = supa
        .from('profiles')
        .select('username,display_name,avatar_url,role')
        .or('username.ilike.$like,display_name.ilike.$like')
        .limit(8)
        .then((rows) => (rows as List)
            .map((r) => _Hit(
                  title: (r['display_name'] as String?)?.isNotEmpty == true
                      ? r['display_name'] as String
                      : (r['username'] as String? ?? '?'),
                  subtitle: '@${r['username'] ?? ''}',
                  category: _HitCategory.profile,
                  data: Map<String, dynamic>.from(r as Map),
                ))
            .toList())
        .catchError((_) => <_Hit>[]);

    Future<List<_Hit>> messagesFut = supa
        .from('chat_messages')
        .select('id,username,message,room_id,realm,created_at')
        .ilike('message', like)
        .order('created_at', ascending: false)
        .limit(10)
        .then((rows) => (rows as List)
            .map((r) => _Hit(
                  title: (r['message'] as String?) ?? '',
                  subtitle:
                      '@${r['username'] ?? '?'} · ${r['realm'] ?? ''} / ${r['room_id'] ?? ''}',
                  category: _HitCategory.message,
                  data: Map<String, dynamic>.from(r as Map),
                ))
            .toList())
        .catchError((_) => <_Hit>[]);

    Future<List<_Hit>> modulesFut = supa
        .from('vorhang_modules')
        .select('module_code,title,branch,description')
        .or('title.ilike.$like,description.ilike.$like,module_code.ilike.$like')
        .limit(8)
        .then((rows) => (rows as List)
            .map((r) => _Hit(
                  title: (r['title'] as String?) ?? (r['module_code'] as String? ?? '?'),
                  subtitle:
                      'Vorhang · ${r['branch'] ?? ''} · ${r['module_code'] ?? ''}',
                  category: _HitCategory.module,
                  data: Map<String, dynamic>.from(r as Map),
                ))
            .toList())
        .catchError((_) => <_Hit>[]);

    try {
      final results = await Future.wait([profilesFut, messagesFut, modulesFut])
          .timeout(const Duration(seconds: 6));
      if (!mounted) return;
      setState(() {
        _profiles = results[0];
        _messages = results[1];
        _modules = results[2];
        _loading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ GlobalSearch error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _hasResults =>
      _profiles.isNotEmpty || _messages.isNotEmpty || _modules.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxWidth = mq.size.width > 720 ? 680.0 : mq.size.width - 32;
    final maxHeight = mq.size.height * 0.78;

    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: maxWidth,
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFC9A84C).withValues(alpha: 0.35),
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 28),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                if (_loading)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(Color(0xFFC9A84C)),
                  )
                else
                  Container(height: 2, color: Colors.transparent),
                Flexible(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              color: Color(0xFFC9A84C), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              autocorrect: false,
              onChanged: _onChange,
              decoration: const InputDecoration(
                hintText: 'Suche User, Nachrichten, Module …',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Schließen',
            icon: const Icon(Icons.close_rounded, color: Colors.white54),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_ctrl.text.trim().length < 2) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Text(
            'Mindestens 2 Zeichen eingeben.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      );
    }
    if (!_loading && !_hasResults) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sentiment_dissatisfied_rounded,
                color: Colors.white24, size: 32),
            const SizedBox(height: 10),
            Text(
              'Keine Treffer.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        if (_profiles.isNotEmpty) ..._buildSection('Profile', _profiles),
        if (_messages.isNotEmpty) ..._buildSection('Nachrichten', _messages),
        if (_modules.isNotEmpty) ..._buildSection('Vorhang-Module', _modules),
      ],
    );
  }

  List<Widget> _buildSection(String title, List<_Hit> hits) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: const Color(0xFFC9A84C).withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
      ...hits.map((h) => _HitTile(hit: h)),
    ];
  }
}

enum _HitCategory { profile, message, module }

class _Hit {
  final String title;
  final String subtitle;
  final _HitCategory category;
  final Map<String, dynamic> data;
  const _Hit({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.data,
  });
}

class _HitTile extends StatelessWidget {
  final _Hit hit;
  const _HitTile({required this.hit});

  IconData get _icon {
    switch (hit.category) {
      case _HitCategory.profile:
        return Icons.person_rounded;
      case _HitCategory.message:
        return Icons.chat_bubble_rounded;
      case _HitCategory.module:
        return Icons.school_rounded;
    }
  }

  Color get _color {
    switch (hit.category) {
      case _HitCategory.profile:
        return const Color(0xFF3B82F6);
      case _HitCategory.message:
        return const Color(0xFFA855F7);
      case _HitCategory.module:
        return const Color(0xFFC9A84C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _color.withValues(alpha: 0.15),
        child: Icon(_icon, color: _color, size: 18),
      ),
      title: Text(
        hit.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        hit.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 11,
        ),
      ),
      onTap: () {
        // MVP: schließen und User selber navigieren lassen.
        // Spätere Iteration: per Category in Chat/Module deep-linken.
        Navigator.of(context).pop();
      },
    );
  }
}
