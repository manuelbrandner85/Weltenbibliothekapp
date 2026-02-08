import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'dart:convert'; // Helper for JSON decode
import '../../services/group_tools_service.dart';
import '../../services/user_service.dart';

/// 💠 Kristall-Bibliothek Screen
/// Gemeinsame Kristall-Sammlung & Erfahrungen
class CrystalLibraryScreen extends StatefulWidget {
  final String roomId;
  
  const CrystalLibraryScreen({
    super.key,
    this.roomId = 'kristalle',
  });

  @override
  State<CrystalLibraryScreen> createState() => _CrystalLibraryScreenState();
}

class _CrystalLibraryScreenState extends State<CrystalLibraryScreen> {
  final GroupToolsService _toolsService = GroupToolsService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _crystals = [];
  bool _isLoading = false;
  String _username = '';
  String _userId = '';
  String? _errorMessage;
  
  // Filter
  String _sortBy = 'likes'; // 'likes', 'recent', 'name'
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCrystals();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final user = await _userService.getCurrentUser();
    setState(() {
      _username = user.username;
      _userId = 'user_${user.username.toLowerCase()}';
    });
  }
  
  Future<void> _loadCrystals({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final crystals = await _toolsService.getCrystals(
        roomId: widget.roomId,
        search: search,
        limit: 100,
      );
      
      if (kDebugMode) {
        debugPrint('💠 Loaded ${crystals.length} crystals');
      }
      
      // Sort
      crystals.sort((a, b) {
        if (_sortBy == 'likes') {
          return (b['likes'] ?? 0).compareTo(a['likes'] ?? 0);
        } else if (_sortBy == 'recent') {
          return (b['created_at'] ?? '').compareTo(a['created_at'] ?? '');
        } else {
          return (a['crystal_name'] ?? '').compareTo(b['crystal_name'] ?? '');
        }
      });
      
      setState(() {
        _crystals = crystals;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading crystals: $e');
      }
      setState(() {
        _errorMessage = 'Fehler beim Laden: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _showAddCrystalDialog() async {
    if (_username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Bitte erstelle erst ein Profil im Energie- oder Materie-Tab'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddCrystalDialog(
        username: _username,
        userId: _userId,
        roomId: widget.roomId,
      ),
    );
    
    if (result != null && result['success'] == true) {
      _loadCrystals(); // Reload
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['crystal_name']} hinzugefügt!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  void _showCrystalDetails(Map<String, dynamic> crystal) {
    showDialog(
      context: context,
      builder: (context) => _CrystalDetailsDialog(crystal: crystal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('💠 Kristall-Bibliothek'),
        actions: [
          // Sort-Dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white70),
            onSelected: (value) {
              setState(() => _sortBy = value);
              _loadCrystals();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'likes', child: Text('🔥 Beliebteste')),
              const PopupMenuItem(value: 'recent', child: Text('🕐 Neueste')),
              const PopupMenuItem(value: 'name', child: Text('🔤 Name')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadCrystals(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A148C).withValues(alpha: 0.2),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Kristall suchen...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.purple),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          _loadCrystals();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) => _loadCrystals(search: value),
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadCrystals(),
                              child: const Text('Erneut versuchen'),
                            ),
                          ],
                        ),
                      )
                    : _crystals.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.diamond, size: 64, color: Colors.purple),
                                const SizedBox(height: 16),
                                const Text(
                                  'Noch keine Kristalle',
                                  style: TextStyle(color: Colors.white70, fontSize: 18),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Sei der Erste und füge einen Kristall hinzu!',
                                  style: TextStyle(color: Colors.white38),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _crystals.length,
                            itemBuilder: (context, index) {
                              final crystal = _crystals[index];
                              return _buildCrystalCard(crystal);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCrystalDialog,
        backgroundColor: const Color(0xFF9C27B0),
        icon: const Icon(Icons.add),
        label: const Text('Kristall hinzufügen'),
      ),
    );
  }
  
  Widget _buildCrystalCard(Map<String, dynamic> crystal) {
    final name = crystal['crystal_name'] ?? 'Unbekannt';
    final type = crystal['crystal_type'] ?? '';
    final uses = crystal['uses'] ?? '';
    final likes = crystal['likes'] ?? 0;
    final username = crystal['username'] ?? 'Anonym';
    
    // Parse properties JSON
    List<String> properties = [];
    try {
      final propsJson = crystal['properties'];
      if (propsJson is String) {
        final decoded = List<String>.from(
          (propsJson.isNotEmpty ? (propsJson.startsWith('[') 
            ? (jsonDecode(propsJson) as List) 
            : [propsJson]) 
          : [])
        );
        properties = decoded;
      } else if (propsJson is List) {
        properties = List<String>.from(propsJson);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing properties: $e');
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showCrystalDetails(crystal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Kristall-Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                      ),
                    ),
                    child: const Icon(Icons.diamond, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  // Name & Type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (type.isNotEmpty)
                          Text(
                            type,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Likes
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, size: 16, color: Colors.purple),
                        const SizedBox(width: 4),
                        Text(
                          likes.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Properties
              if (properties.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: properties.take(5).map((prop) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        prop,
                        style: const TextStyle(color: Colors.purple, fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              // Uses
              if (uses.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  uses,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Footer
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    username,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showCrystalDetails(crystal),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================
// 💠 ADD CRYSTAL DIALOG
// ========================================

class _AddCrystalDialog extends StatefulWidget {
  final String username;
  final String userId;
  final String roomId;
  
  const _AddCrystalDialog({
    required this.username,
    required this.userId,
    required this.roomId,
  });

  @override
  State<_AddCrystalDialog> createState() => _AddCrystalDialogState();
}

class _AddCrystalDialogState extends State<_AddCrystalDialog> {
  final GroupToolsService _toolsService = GroupToolsService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _usesController = TextEditingController();
  final _propertyController = TextEditingController();
  
  final List<String> _properties = [];
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _usesController.dispose();
    _propertyController.dispose();
    super.dispose();
  }
  
  void _addProperty() {
    final prop = _propertyController.text.trim();
    if (prop.isNotEmpty && !_properties.contains(prop)) {
      setState(() {
        _properties.add(prop);
        _propertyController.clear();
      });
    }
  }
  
  void _removeProperty(String prop) {
    setState(() => _properties.remove(prop));
  }
  
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final crystalId = await _toolsService.addCrystal(
        roomId: widget.roomId,
        userId: widget.userId,
        username: widget.username,
        crystalName: _nameController.text.trim(),
        crystalType: _typeController.text.trim(),
        properties: _properties,
        uses: _usesController.text.trim(),
      );
      
      if (crystalId != null && mounted) {
        Navigator.of(context).pop({
          'success': true,
          'crystal_name': _nameController.text.trim(),
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Fehler beim Hinzufügen'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                        ),
                      ),
                      child: const Icon(Icons.diamond, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '💠 Kristall hinzufügen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Kristall-Name *',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'z.B. Amethyst',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte Namen eingeben';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Type
                TextFormField(
                  controller: _typeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Typ/Kategorie',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'z.B. Quarz, Edelstein',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Properties
                const Text(
                  'Eigenschaften',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _propertyController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'z.B. Beruhigend',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _addProperty(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _addProperty,
                      icon: const Icon(Icons.add_circle, color: Colors.purple),
                    ),
                  ],
                ),
                
                if (_properties.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _properties.map((prop) {
                      return Chip(
                        label: Text(prop),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeProperty(prop),
                        backgroundColor: Colors.purple.withValues(alpha: 0.2),
                        labelStyle: const TextStyle(color: Colors.white),
                      );
                    }).toList(),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Uses
                TextFormField(
                  controller: _usesController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Anwendung & Wirkung',
                    labelStyle: const TextStyle(color: Colors.white70),
                    hintText: 'z.B. Meditation, Schlaf, Drittes Auge öffnen...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('Abbrechen'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Hinzufügen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================
// 💠 CRYSTAL DETAILS DIALOG
// ========================================

class _CrystalDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> crystal;
  
  const _CrystalDetailsDialog({required this.crystal});

  @override
  Widget build(BuildContext context) {
    final name = crystal['crystal_name'] ?? 'Unbekannt';
    final type = crystal['crystal_type'] ?? '';
    final uses = crystal['uses'] ?? '';
    final likes = crystal['likes'] ?? 0;
    final username = crystal['username'] ?? 'Anonym';
// UNUSED: final createdAt = crystal['created_at'] ?? '';
    
    // Parse properties
    List<String> properties = [];
    try {
      final propsJson = crystal['properties'];
      if (propsJson is String && propsJson.isNotEmpty) {
        final decoded = List<String>.from(
          propsJson.startsWith('[') 
            ? (jsonDecode(propsJson) as List) 
            : [propsJson]
        );
        properties = decoded;
      } else if (propsJson is List) {
        properties = List<String>.from(propsJson);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error parsing properties in details: $e');
      }
    }
    
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
                      ),
                    ),
                    child: const Icon(Icons.diamond, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (type.isNotEmpty)
                          Text(
                            type,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Properties
              if (properties.isNotEmpty) ...[
                const Text(
                  'Eigenschaften',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: properties.map((prop) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        prop,
                        style: const TextStyle(color: Colors.purple, fontSize: 14),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
              
              // Uses
              if (uses.isNotEmpty) ...[
                const Text(
                  'Anwendung & Wirkung',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  uses,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
                const SizedBox(height: 24),
              ],
              
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20, color: Colors.white54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        username,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ),
                    const Icon(Icons.favorite, size: 20, color: Colors.purple),
                    const SizedBox(width: 4),
                    Text(
                      likes.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
