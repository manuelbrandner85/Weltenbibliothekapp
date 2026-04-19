/// 🔍 RECHERCHE INPUT BAR
/// 
/// Search input field with voice input support and start button
library;

import 'package:flutter/material.dart';

class RechercheInputBar extends StatefulWidget {
  final Function(String query) onSearch;
  final bool isLoading;
  final VoidCallback? onCancel;
  
  const RechercheInputBar({
    super.key,
    required this.onSearch,
    this.isLoading = false,
    this.onCancel,
  });

  @override
  State<RechercheInputBar> createState() => _RechercheInputBarState();
}

class _RechercheInputBarState extends State<RechercheInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _handleSearch() {
    final query = _controller.text.trim();
    if (query.isNotEmpty && !widget.isLoading) {
      widget.onSearch(query);
      _focusNode.unfocus();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search input field
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: !widget.isLoading,
              decoration: InputDecoration(
                hintText: 'Suche nach Verschwörungstheorien, historischen Ereignissen...',
                prefixIcon: const Icon(Icons.search, size: 24),
                suffixIcon: widget.isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _controller.clear();
                              setState(() {});
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.mic),
                            onPressed: () {
                              // TODO: Voice input
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Voice input coming soon!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _handleSearch(),
              textInputAction: TextInputAction.search,
              maxLines: 1,
            ),
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                // Start/Cancel button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.isLoading
                        ? widget.onCancel
                        : (_controller.text.trim().isEmpty ? null : _handleSearch),
                    icon: Icon(
                      widget.isLoading ? Icons.stop : Icons.search,
                      size: 20,
                    ),
                    label: Text(
                      widget.isLoading ? 'Abbrechen' : 'Recherche starten',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isLoading
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: widget.isLoading ? 4 : 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
