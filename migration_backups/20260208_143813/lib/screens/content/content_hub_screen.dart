import 'package:flutter/material.dart';
import '../../services/content_management_service.dart';
import 'create_content_screen.dart';

class ContentHubScreen extends StatefulWidget {
  final String world;

  const ContentHubScreen({super.key, required this.world});

  @override
  State<ContentHubScreen> createState() => _ContentHubScreenState();
}

class _ContentHubScreenState extends State<ContentHubScreen> {
  List<Map<String, dynamic>> _content = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    final content = await ContentManagementService.getPublicContent(widget.world);
    if (mounted) {
      setState(() {
        _content = content;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Content - ${widget.world}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _content.isEmpty
              ? const Center(child: Text('Noch kein Content vorhanden'))
              : RefreshIndicator(
                  onRefresh: _loadContent,
                  child: ListView.builder(
                    itemCount: _content.length,
                    itemBuilder: (context, index) {
                      final item = _content[index];
                      final isFeatured = item['is_featured'] == 1;
                      final isVerified = item['is_verified'] == 1;

                      return Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['title'] ?? '',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ),
                                  if (isFeatured)
                                    const Icon(Icons.star, color: Colors.amber),
                                  if (isVerified)
                                    const Icon(Icons.verified, color: Colors.blue),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Von ${item['author_username']}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (item['category'] != null) ...[
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(item['category']),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                              const SizedBox(height: 12),
                              Text(
                                item['body'] ?? '',
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${item['view_count']} Views',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => CreateContentScreen(world: widget.world),
            ),
          );
          if (result == true) {
            _loadContent();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Neuer Beitrag'),
      ),
    );
  }
}
