import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../theme/wb_cinematic_tokens.dart';
import '../../../widgets/cinematic/wb_glass_app_bar.dart';
import '../../../widgets/cinematic/wb_vignette.dart';

// ─────────────────────────────────────────────────────────────────────────────
// C — Krypto-Verfolger
// ─────────────────────────────────────────────────────────────────────────────

const _kBg      = Color(0xFF0D0000);
const _kSurface = Color(0xFF1A0808);
const _kAccent  = Color(0xFFE53935);
const _kText    = Colors.white;
const _kMuted   = Color(0xFFB0A0A0);
const _kBorder  = Color(0x33E53935);
const _kBtcOrange = Color(0xFFF7931A);
const _kEthBlue   = Color(0xFF627EEA);

class CryptoTrackerTool extends StatefulWidget {
  const CryptoTrackerTool({super.key});

  @override
  State<CryptoTrackerTool> createState() => _CryptoTrackerToolState();
}

class _CryptoTrackerToolState extends State<CryptoTrackerTool> {
  final _addrCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _addrCtrl.dispose();
    super.dispose();
  }

  bool _isBtc(String a) => RegExp(r'^[13][a-km-zA-HJ-NP-Z1-9]{25,34}$').hasMatch(a)
      || RegExp(r'^bc1[ac-hj-np-z02-9]{6,87}$').hasMatch(a);

  bool _isEth(String a) => RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(a);

  String _detectCoin(String a) {
    if (_isBtc(a)) return 'BTC';
    if (_isEth(a)) return 'ETH';
    return 'unknown';
  }

  Future<void> _track() async {
    final addr = _addrCtrl.text.trim();
    if (addr.isEmpty) return;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final uri = Uri.parse(
        '${ApiConfig.workerUrl}/api/tools/crypto?address=${Uri.encodeComponent(addr)}',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 25));
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['error'] != null) throw Exception(data['error'].toString());
      setState(() { _result = data; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _kSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kBorder),
    ),
    child: child,
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 130, child: Text(label, style: const TextStyle(color: _kMuted, fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(color: _kText, fontSize: 13), overflow: TextOverflow.ellipsis)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final coin = _detectCoin(_addrCtrl.text.trim());
    final coinColor = coin == 'BTC' ? _kBtcOrange : coin == 'ETH' ? _kEthBlue : _kAccent;

    final txs = (_result?['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF04080F),
      appBar: WBGlassAppBar(
        world: WBWorld.materie,
        titleWidget: Row(children: [
          Icon(Icons.currency_bitcoin_rounded, color: _kAccent, size: 22),
          const SizedBox(width: 8),
          const Text('Krypto-Verfolger', style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Wallet-Adresse', style: TextStyle(color: _kMuted, fontSize: 12)),
              const Spacer(),
              if (_addrCtrl.text.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: coinColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: coinColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(coin == 'unknown' ? '?' : coin, style: TextStyle(color: coinColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ]),
            const SizedBox(height: 8),
            TextField(
              controller: _addrCtrl,
              style: const TextStyle(color: _kText, fontSize: 13, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'Bitcoin- oder Ethereum-Adresse',
                hintStyle: TextStyle(color: _kMuted.withValues(alpha: 0.6)),
                filled: true,
                fillColor: _kBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kAccent)),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _track(),
            ),
            const SizedBox(height: 4),
            const Text('BTC: beginnt mit 1, 3 oder bc1  •  ETH: beginnt mit 0x', style: TextStyle(color: _kMuted, fontSize: 10)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _track,
                icon: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.track_changes_rounded, size: 18),
                label: const Text('Adresse verfolgen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ])),

          if (_error != null)
            _card(Row(children: [
              const Icon(Icons.error_outline, color: _kAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: const TextStyle(color: _kAccent, fontSize: 13))),
            ])),

          if (_result != null) ...[
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.account_balance_wallet_rounded, color: coinColor, size: 18),
                const SizedBox(width: 8),
                Text('Wallet-Übersicht', style: TextStyle(color: coinColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
              const SizedBox(height: 10),
              if (_result!['coin'] != null) _row('Coin', _result!['coin'].toString()),
              if (_result!['balance'] != null) _row('Guthaben', _result!['balance'].toString()),
              if (_result!['balanceUsd'] != null) _row('≈ USD', _result!['balanceUsd'].toString()),
              if (_result!['txCount'] != null) _row('Transaktionen', _result!['txCount'].toString()),
              if (_result!['firstSeen'] != null) _row('Erste Transaktion', _result!['firstSeen'].toString()),
              if (_result!['lastSeen'] != null) _row('Letzte Transaktion', _result!['lastSeen'].toString()),
            ])),

            if (txs.isNotEmpty)
              _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Letzte Transaktionen', style: TextStyle(color: _kMuted, fontSize: 12)),
                const SizedBox(height: 8),
                ...txs.take(5).map((tx) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (tx['hash'] != null)
                      Text(tx['hash'].toString(), style: const TextStyle(color: _kMuted, fontSize: 10, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (tx['amount'] != null)
                        Text(tx['amount'].toString(), style: TextStyle(color: coinColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      const Spacer(),
                      if (tx['date'] != null)
                        Text(tx['date'].toString(), style: const TextStyle(color: _kMuted, fontSize: 11)),
                    ]),
                  ]),
                )),
              ])),
          ],
        ]),
      ),
    );
  }
}
