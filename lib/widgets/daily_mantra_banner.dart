// DailyMantraBanner — Glass-Banner mit Tages-Mantra (F1).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/daily_mantra_service.dart';
import '../utils/wb_toast.dart';

class DailyMantraBanner extends StatefulWidget {
  final Color accent;
  const DailyMantraBanner({super.key, this.accent = const Color(0xFFA855F7)});

  @override
  State<DailyMantraBanner> createState() => _DailyMantraBannerState();
}

class _DailyMantraBannerState extends State<DailyMantraBanner> {
  Mantra? _mantra;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await DailyMantraService.instance.today();
    if (mounted) setState(() => _mantra = m);
  }

  @override
  Widget build(BuildContext context) {
    final m = _mantra;
    if (m == null || m.text.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: m.text));
        WBToast.success(context, '📋 Mantra kopiert');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.accent.withValues(alpha: 0.22),
              widget.accent.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(color: widget.accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote_rounded,
                    color: widget.accent.withValues(alpha: 0.8), size: 16),
                const SizedBox(width: 6),
                Text(
                  'MANTRA DES TAGES',
                  style: TextStyle(
                    color: widget.accent.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '„${m.text}"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontStyle: FontStyle.italic,
                height: 1.45,
              ),
            ),
            if ((m.author?.isNotEmpty ?? false) ||
                (m.tradition?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Text(
                [m.author, m.tradition]
                    .where((s) => s != null && s.isNotEmpty)
                    .join(' · '),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
