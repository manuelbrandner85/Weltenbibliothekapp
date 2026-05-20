/// 👥 OpenCorporates Network — Vorstands-Verflechtungen.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/thread.dart';
import '../widgets/kb_design.dart';

class OcNetworkCard extends StatelessWidget {
  final List<OcNetworkOfficer> items;
  final bool loading;
  const OcNetworkCard({super.key, required this.items, required this.loading});

  static const _accent = Color(0xFF26A69A);

  @override
  Widget build(BuildContext context) {
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
          if (items.isNotEmpty)
            Text('${items.length}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        Text('OpenCorporates · Wer sitzt in welchem Vorstand?',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
        const SizedBox(height: 14),
        if (loading)
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
