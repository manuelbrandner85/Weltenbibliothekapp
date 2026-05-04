import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';

/// 🌙 Traum-Tagebuch — Mit Jungianischer Symbolanalyse
class DreamJournalScreen extends StatefulWidget {
  final String roomId;
  const DreamJournalScreen({super.key, this.roomId = 'traumarbeit'});

  @override
  State<DreamJournalScreen> createState() => _DreamJournalScreenState();
}

class _DreamJournalScreenState extends State<DreamJournalScreen>
    with SingleTickerProviderStateMixin {
  final _toolsService = GroupToolsService();
  final _userService = UserService();

  late final AnimationController _moonCtrl;
  List<Map<String, dynamic>> _dreams = [];
  bool _isLoading = false;
  String _username = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _moonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _loadUserData();
    _loadDreams();
  }

  @override
  void dispose() {
    _moonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getCurrentUser();
      if (mounted) setState(() {
        _username = user.username;
        _userId = 'user_${user.username.toLowerCase()}';
      });
    } catch (_) {}
  }

  Future<void> _loadDreams() async {
    setState(() => _isLoading = true);
    try {
      final dreams = await _toolsService.getDreams(roomId: widget.roomId);
      if (mounted) setState(() { _dreams = dreams; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Statische Traumsymbol-Datenbank (Jungianisch / europäische Volkstradition)
  static const Map<String, Map<String, String>> _symbolDict = {
    'wasser': {'de': 'Unterbewusstsein, Emotionen, Transformation', 'arch': 'Die Große Mutter'},
    'feuer': {'de': 'Leidenschaft, Reinigung, Transformation', 'arch': 'Der Held'},
    'schlange': {'de': 'Weisheit, Erneuerung, verborgenes Wissen', 'arch': 'Der Schatten'},
    'fliegen': {'de': 'Freiheit, spirituelle Erhebung, Perspektivwechsel', 'arch': 'Der Geist'},
    'fallen': {'de': 'Kontrollverlust, Unsicherheit im Wachleben', 'arch': 'Der Schatten'},
    'haus': {'de': 'Das Selbst, Persönlichkeitsstruktur, Psyche', 'arch': 'Das Selbst'},
    'tod': {'de': 'Ende eines Lebensabschnitts, Transformation', 'arch': 'Der Trickster'},
    'kind': {'de': 'Inneres Kind, Neubeginn, Unschuld', 'arch': 'Das Göttliche Kind'},
    'licht': {'de': 'Bewusstsein, Erkenntnis, spirituelle Führung', 'arch': 'Der Weise'},
    'dunkelheit': {'de': 'Unbewusstes, Angst, unbekannte Aspekte', 'arch': 'Der Schatten'},
    'meer': {'de': 'Kollektives Unbewusstes, emotionale Tiefe', 'arch': 'Die Große Mutter'},
    'wald': {'de': 'Das Unbewusste, Prüfung, Suche nach dem Selbst', 'arch': 'Der Held'},
    'baum': {'de': 'Lebensachse, Verbindung Erde-Himmel, Wachstum', 'arch': 'Das Selbst'},
    'mond': {'de': 'Weibliches Prinzip, Rhythmen, Intuition', 'arch': 'Die Anima'},
    'sonne': {'de': 'Bewusstsein, Männliches Prinzip, Vitalität', 'arch': 'Der Vater'},
    'tier': {'de': 'Instinkte, Schatten, naturhafte Kraft', 'arch': 'Der Trickster'},
    'gold': {'de': 'Wertvolles Selbst, Individualisation', 'arch': 'Das Selbst'},
    'brücke': {'de': 'Übergang, Verbindung zweier Welten', 'arch': 'Der Bote'},
    'spiegel': {'de': 'Selbstreflexion, Doppelnatur, Persona', 'arch': 'Die Persona'},
    'uhr': {'de': 'Zeit, Vergänglichkeit, innerer Druck', 'arch': 'Der Weise'},
  };

  List<String> _detectSymbols(String text) {
    final lower = text.toLowerCase();
    return _symbolDict.keys.where((k) => lower.contains(k)).toList();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C4DFF);
    const bg = Color(0xFF0A0A14);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: const Color(0xFF12121F),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Traum-Tagebuch',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              background: AnimatedBuilder(
                animation: _moonCtrl,
                builder: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF12121F),
                        accent.withValues(alpha: 0.1 + _moonCtrl.value * 0.05),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '🌙',
                      style: TextStyle(
                        fontSize: 48 + _moonCtrl.value * 6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadDreams,
              ),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF))),
            )
          else if (_dreams.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌙', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    const Text(
                      'Noch keine Träume',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tippe auf + um deinen ersten\nTraum zu dokumentieren',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _DreamCard(
                  dream: _dreams[i],
                  detectSymbols: _detectSymbols,
                  symbolDict: _symbolDict,
                  onTap: () => _showDreamDetail(_dreams[i]),
                ),
                childCount: _dreams.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDream(),
        backgroundColor: accent,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Traum erfassen'),
      ),
    );
  }

  void _showDreamDetail(Map<String, dynamic> dream) {
    const accent = Color(0xFF7C4DFF);
    final title = dream['dream_title'] ?? '';
    final desc = dream['description'] ?? dream['content'] ?? '';
    final lucid = dream['lucid'] == 1 || dream['lucid'] == true;
    final symbols = _detectSymbols('$title $desc');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF12121F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(lucid ? Icons.wb_twilight_rounded : Icons.bedtime_rounded,
                      color: accent, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (lucid)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.4)),
                      ),
                      child: const Text('Luzid', style: TextStyle(color: Color(0xFFFFB300), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  desc,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, height: 1.6),
                ),
              ],
              if (symbols.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: accent, size: 16),
                    const SizedBox(width: 6),
                    const Text('Erkannte Symbole', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                ...symbols.map((sym) {
                  final info = _symbolDict[sym]!;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sym[0].toUpperCase() + sym.substring(1),
                          style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(info['de']!, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('Archetyp: ${info['arch']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDream() {
    const accent = Color(0xFF7C4DFF);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isLucid = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setLocal) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF12121F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('🌙 Traum erfassen',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Titel des Traums…',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.07),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Was hast du geträumt?',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.07),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Luzider Traum', style: TextStyle(color: Colors.white70)),
                  subtitle: Text('Ich war mir bewusst, dass ich träume', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                  value: isLucid,
                  activeColor: accent,
                  onChanged: (v) => setLocal(() => isLucid = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final title = titleCtrl.text.trim();
                      final desc = descCtrl.text.trim();
                      final lucid = isLucid;
                      titleCtrl.dispose();
                      descCtrl.dispose();
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _toolsService.createDream(
                        roomId: widget.roomId,
                        userId: _userId,
                        username: _username,
                        title: title,
                        description: desc,
                        lucid: lucid,
                      );
                      _loadDreams();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Traum speichern', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DreamCard extends StatelessWidget {
  final Map<String, dynamic> dream;
  final List<String> Function(String) detectSymbols;
  final Map<String, Map<String, String>> symbolDict;
  final VoidCallback onTap;

  const _DreamCard({
    required this.dream,
    required this.detectSymbols,
    required this.symbolDict,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C4DFF);
    final title = dream['dream_title'] ?? '';
    final desc = dream['description'] ?? dream['content'] ?? '';
    final lucid = dream['lucid'] == 1 || dream['lucid'] == true;
    final symbols = detectSymbols('$title $desc');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  lucid ? Icons.wb_twilight_rounded : Icons.bedtime_rounded,
                  color: lucid ? const Color(0xFFFFB300) : accent.withValues(alpha: 0.7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (lucid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Luzid', style: TextStyle(color: Color(0xFFFFB300), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, height: 1.4),
              ),
            ],
            if (symbols.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: symbols.take(4).map((sym) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sym,
                    style: TextStyle(color: accent.withValues(alpha: 0.9), fontSize: 10),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
