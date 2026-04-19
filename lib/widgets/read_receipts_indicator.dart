/// Read Receipts Indicator Widget
/// Zeigt Avatar-Stack von Lesern unter eigenen Nachrichten
library;

import 'package:flutter/material.dart';
import '../services/read_receipts_service.dart';

class ReadReceiptsIndicator extends StatefulWidget {
  final String messageId;
  final String currentUserId;
  final Color worldColor;

  const ReadReceiptsIndicator({
    super.key,
    required this.messageId,
    required this.currentUserId,
    required this.worldColor,
  });

  @override
  State<ReadReceiptsIndicator> createState() => _ReadReceiptsIndicatorState();
}

class _ReadReceiptsIndicatorState extends State<ReadReceiptsIndicator> {
  final ReadReceiptsService _receiptsService = ReadReceiptsService();
  List<Map<String, dynamic>> _receipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceipts();

    // Listen to updates
    _receiptsService.addListener(_onReceiptsUpdate);
  }

  @override
  void dispose() {
    _receiptsService.removeListener(_onReceiptsUpdate);
    super.dispose();
  }

  void _onReceiptsUpdate() {
    if (mounted) {
      _loadReceipts();
    }
  }

  Future<void> _loadReceipts() async {
    final receipts = await _receiptsService.getReceipts(widget.messageId);
    if (mounted) {
      setState(() {
        _receipts = receipts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nur für eigene Nachrichten anzeigen
    if (_isLoading || _receipts.isEmpty) {
      return const SizedBox.shrink();
    }

    final readerCount = _receipts.length;
    final displayNames = _receipts.take(3).map((r) => r['username'] as String).toList();

    return GestureDetector(
      onTap: () => _showReadersDialog(context),
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0, right: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Avatar-Stack (max 3)
            SizedBox(
              height: 20,
              width: readerCount > 1 ? (readerCount > 2 ? 50 : 35) : 20,
              child: Stack(
                children: List.generate(
                  readerCount > 3 ? 3 : readerCount,
                  (index) => Positioned(
                    left: index * 15.0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: widget.worldColor.withValues(alpha: 0.3),
                        border: Border.all(
                          color: const Color(0xFF0A0A0F),
                          width: 1.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          displayNames[index][0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: widget.worldColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // "Gelesen von X"
            Text(
              readerCount == 1
                  ? 'Gelesen'
                  : 'Gelesen von $readerCount',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReadersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'Gelesen von ${_receipts.length} ${_receipts.length == 1 ? 'Person' : 'Personen'}',
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _receipts.length,
            itemBuilder: (context, index) {
              final receipt = _receipts[index];
              final readAt = DateTime.fromMillisecondsSinceEpoch(
                receipt['readAt'] as int,
              );

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: widget.worldColor.withValues(alpha: 0.3),
                  child: Text(
                    (receipt['username'] as String)[0].toUpperCase(),
                    style: TextStyle(
                      color: widget.worldColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  receipt['username'] as String,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _formatTimestamp(readAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'Gerade eben';
    } else if (diff.inMinutes < 60) {
      return 'vor ${diff.inMinutes} Min';
    } else if (diff.inHours < 24) {
      return 'vor ${diff.inHours} Std';
    } else {
      return 'vor ${diff.inDays} Tag${diff.inDays > 1 ? 'en' : ''}';
    }
  }
}
