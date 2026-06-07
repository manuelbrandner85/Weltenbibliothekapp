/// 👥 OpenCorporates Network — Vorstands-Verflechtungen.
/// 2026-06-07: Liste/Graph-Toggle (Phase B der Verflechtungs-Konsolidierung).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';
import 'network_card.dart';

class OcNetworkCard extends StatefulWidget {
  final List<OcNetworkOfficer> items;
  final bool loading;
  const OcNetworkCard({super.key, required this.items, required this.loading});

  static const accent = Color(0xFF26A69A);

  @override
  State<OcNetworkCard> createState() => _OcNetworkCardState();
}

class _OcNetworkCardState extends State<OcNetworkCard> {
  // 'list' (default) | 'graph'
  String _mode = 'list';

  static const _accent = OcNetworkCard.accent;

  /// Konvertiert Vorstands-Liste in einen NetworkGraph fuer NetworkCard:
  ///   - Knoten = Firmen (unique companyName + otherCompanies).
  ///   - Center = Firma mit den meisten gemeinsamen Officers.
  ///   - Kanten = pro Officer ein Edge vom Center zu jeder anderen Firma,
  ///     in der der Officer auch sitzt. Edge-Label = Officer-Name.
  ///   - Dedup pro (target, officer) -- gleicher Officer in derselben
  ///     Firma 2x wird nicht doppelt eingezeichnet.
  NetworkGraph _buildGraph() {
    final officersByCompany = <String, List<String>>{};
    for (final o in widget.items) {
      final co = o.companyName.trim();
      if (co.isEmpty) continue;
      officersByCompany.putIfAbsent(co, () => []).add(o.officerName);
      for (final other in o.otherCompanies) {
        final t = other.trim();
        if (t.isEmpty) continue;
        officersByCompany.putIfAbsent(t, () => []).add(o.officerName);
      }
    }
    if (officersByCompany.isEmpty) {
      return const NetworkGraph(nodes: [], edges: []);
    }

    // Center: Firma mit den meisten Verbindungen.
    final centerCo = officersByCompany.entries
        .reduce((a, b) => a.value.length >= b.value.length ? a : b)
        .key;

    final nodes = <NetworkNode>[
      NetworkNode(id: 'center', label: centerCo, type: 'company', weight: 1.0),
    ];
    final outerIdMap = <String, String>{}; // companyName -> nodeId
    var idx = 0;
    for (final co in officersByCompany.keys) {
      if (co == centerCo) continue;
      if (idx >= 16) break;
      final id = 'oc$idx';
      outerIdMap[co] = id;
      nodes.add(NetworkNode(
        id: id,
        label: co,
        type: 'company',
        weight: 0.6 - (idx * 0.02).clamp(0.0, 0.4),
      ));
      idx++;
    }

    // Edges aufbauen: pro Officer (in Center-Firma), pro Folge-Firma -> Edge.
    final edges = <NetworkEdge>[];
    final edgeKeys = <String>{};
    for (final o in widget.items) {
      final officer = o.officerName.trim();
      if (officer.isEmpty) continue;
      // Welche Firmen ist dieser Officer in?
      final cos = <String>{o.companyName.trim(), ...o.otherCompanies}
          .where((c) => c.isNotEmpty)
          .toSet();
      if (!cos.contains(centerCo)) continue;
      for (final co in cos) {
        if (co == centerCo) continue;
        final toId = outerIdMap[co];
        if (toId == null) continue;
        final key = '$toId-$officer';
        if (edgeKeys.contains(key)) continue;
        edgeKeys.add(key);
        edges.add(NetworkEdge(
            fromId: 'center', toId: toId, label: officer, strength: 0.6));
      }
    }

    return NetworkGraph(nodes: nodes, edges: edges);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final loading = widget.loading;
    return Container(
      decoration: KbDesign.glassBox(tint: _accent, opacity: 0.10),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.groups_2, color: _accent, size: 18),
          const SizedBox(width: 8),
          const Text('VORSTANDS-VERFLECHTUNGEN',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          // 2026-06-07: Liste/Graph-Toggle.
          if (items.length > 1)
            _modeToggle(),
          if (items.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text('${items.length}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          ],
        ]),
        const SizedBox(height: 4),
        Text('OpenCorporates · Wer sitzt in welchem Vorstand?',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
        const SizedBox(height: 14),
        if (_mode == 'graph' && items.length > 1) ...[
          NetworkCard(
            nodes: _buildGraph().nodes,
            edges: _buildGraph().edges,
            loading: loading,
            // Tap auf Knoten oeffnet Firmenname als neues Thema im Kaninchenbau.
            onTapNode: (label) {
              // Hochreichen ueber InheritedNotifier ist Overkill; das
              // Parent _openThread laeuft nur fuer NetworkCard direkt.
              // Hier nur Haptic + SnackBar, ausreichend.
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Firma: $label'),
                duration: const Duration(seconds: 2),
              ));
            },
          ),
        ] else if (loading)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                          color: _accent, strokeWidth: 2))))
        else if (items.isEmpty)
          Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Keine Vorstands-Verflechtungen zum Thema gefunden.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4))))
        else
          ...items.take(10).map(_buildItem),
      ]),
    );
  }

  Widget _modeToggle() {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _toggleChip('Liste', _mode == 'list', () => setState(() => _mode = 'list')),
      const SizedBox(width: 4),
      _toggleChip('Graph', _mode == 'graph', () => setState(() => _mode = 'graph')),
    ]);
  }

  Widget _toggleChip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active
              ? _accent.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active
                  ? _accent.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? _accent : Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildItem(OcNetworkOfficer o) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: o.url.isEmpty
            ? null
            : () async {
                HapticFeedback.lightImpact();
                final uri = Uri.tryParse(o.url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accent.withValues(alpha: 0.22))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.person, color: _accent, size: 15),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(o.officerName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (o.position.isNotEmpty)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(o.position,
                        style: const TextStyle(
                            color: _accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              if (o.companyName.isNotEmpty)
                Text('@ ${o.companyName}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              if (o.startDate.isNotEmpty)
                Text(
                    'seit ${o.startDate.length > 10 ? o.startDate.substring(0, 10) : o.startDate}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10)),
            ]),
          ]),
        ),
      ),
    );
  }
}
