import 'package:flutter/material.dart';

/// Message Search Widget
/// Suche nach Nachrichten im Chat
class MessageSearchWidget extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final Function(Map<String, dynamic> message) onSelectMessage;
  final VoidCallback onClose;
  
  const MessageSearchWidget({
    super.key,
    required this.messages,
    required this.onSelectMessage,
    required this.onClose,
  });
  
  @override
  State<MessageSearchWidget> createState() => _MessageSearchWidgetState();
}

class _MessageSearchWidgetState extends State<MessageSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _search(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    final results = widget.messages.where((msg) {
      final content = msg['message']?.toString().toLowerCase() ?? '';
      final username = msg['username']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();
      
      return content.contains(searchQuery) || username.contains(searchQuery);
    }).toList();
    
    setState(() => _searchResults = results.reversed.toList()); // Newest first
  }
  
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = timestamp is String 
          ? DateTime.parse(timestamp)
          : DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 1) return 'Gerade eben';
      if (diff.inMinutes < 60) return 'vor ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'vor ${diff.inHours}h';
      if (diff.inDays < 7) return 'vor ${diff.inDays}d';
      
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return '';
    }
  }
  
  String _highlightMatch(String text, String query) {
    // Return text as-is, highlighting done via TextSpan in build
    return text;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF9B51E0)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: _search,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Nachrichten durchsuchen...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          
          // Results
          Expanded(
            child: _searchResults.isEmpty && _searchController.text.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Keine Ergebnisse gefunden',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Suche nach Nachrichten',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final msg = _searchResults[index];
                          final username = msg['username']?.toString() ?? 'Unbekannt';
                          final content = msg['message']?.toString() ?? '';
                          final timestamp = _formatTimestamp(msg['timestamp']);
                          
                          return ListTile(
                            onTap: () {
                              widget.onSelectMessage(msg);
                              widget.onClose();
                            },
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF9B51E0),
                              child: Text(
                                username[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  content,
                                  style: const TextStyle(color: Colors.white70),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (timestamp.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    timestamp,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white38,
                              size: 16,
                            ),
                          );
                        },
                      ),
          ),
          
          // Result Count
          if (_searchResults.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Text(
                '${_searchResults.length} Ergebnis${_searchResults.length != 1 ? 'se' : ''}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
