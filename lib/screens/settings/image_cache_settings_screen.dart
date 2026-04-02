/// 🖼️ WELTENBIBLIOTHEK - IMAGE CACHE SETTINGS SCREEN
/// User-friendly cache management interface
/// Features: Cache stats, clear cache, optimize storage
library;

import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../services/image_cache_service.dart';

class ImageCacheSettingsScreen extends StatefulWidget {
  const ImageCacheSettingsScreen({super.key});

  @override
  State<ImageCacheSettingsScreen> createState() => _ImageCacheSettingsScreenState();
}

class _ImageCacheSettingsScreenState extends State<ImageCacheSettingsScreen> {
  final ImageCacheService _cacheService = ImageCacheService();
  Map<String, dynamic> _cacheStats = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    setState(() => _isLoading = true);
    
    final stats = await _cacheService.getCacheStats();
    
    setState(() {
      _cacheStats = stats;
      _isLoading = false;
    });
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache löschen?'),
        content: const Text(
          'Alle gespeicherten Bilder werden gelöscht. '
          'Sie werden beim nächsten Laden neu heruntergeladen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      
      await _cacheService.clearCache();
      await _loadCacheStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cache erfolgreich gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _clearOldCache() async {
    setState(() => _isLoading = true);
    
    await _cacheService.clearOldCache();
    await _loadCacheStats();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Alte Cache-Dateien gelöscht'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 Bild-Cache'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCacheStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Cache Statistics
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Statistiken',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (_cacheStats.isNotEmpty) ...[
                            _buildStatRow(
                              'Bilder im Speicher',
                              '${_cacheStats['memory_current_count'] ?? 0} / ${_cacheStats['memory_max_count'] ?? 0}',
                              Icons.image,
                            ),
                            const Divider(),
                            _buildStatRow(
                              'Speicher verwendet',
                              _formatBytes(_cacheStats['memory_current_bytes'] ?? 0),
                              Icons.memory,
                            ),
                            const Divider(),
                            _buildStatRow(
                              'Aktive Bilder',
                              '${_cacheStats['memory_live_count'] ?? 0}',
                              Icons.visibility,
                            ),
                            const Divider(),
                            _buildStatRow(
                              'Wartende Bilder',
                              '${_cacheStats['memory_pending_count'] ?? 0}',
                              Icons.hourglass_empty,
                            ),
                          ] else
                            const Center(
                              child: Text('Keine Statistiken verfügbar'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Cache Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cleaning_services_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Aktionen',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Clear Old Cache
                          ListTile(
                            leading: const Icon(Icons.auto_delete_outlined),
                            title: const Text('Alte Dateien löschen'),
                            subtitle: const Text('Löscht Bilder älter als 7 Tage'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _clearOldCache,
                          ),
                          
                          const Divider(),
                          
                          // Clear All Cache
                          ListTile(
                            leading: Icon(
                              Icons.delete_forever_outlined,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            title: Text(
                              'Gesamten Cache löschen',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            subtitle: const Text('Löscht alle gespeicherten Bilder'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _clearCache,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Info Card
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Info',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Der Bild-Cache verbessert die Performance der App, '
                            'indem häufig verwendete Bilder gespeichert werden. '
                            'Bei Speicherproblemen kannst du den Cache löschen.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
